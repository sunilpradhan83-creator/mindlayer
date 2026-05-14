#!/usr/bin/env bash
set -eu

PROJECT_DIR="$(pwd)"
GLOBAL_ONLY=0
PROJECT_ONLY=0
NO_ADAPTERS=0
NO_GITIGNORE=0
NO_ONBOARD=0

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --project <path>   Install project memory into path. Default: current directory.
  --global-only      Only create/update ~/.mindlayer.
  --project-only     Only create/update project .mindlayer and adapters.
  --no-adapters      Do not modify detected project adapter files.
  --no-gitignore     Do not modify .gitignore.
  --no-onboard       Minimal terminal output.
  -h, --help         Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      [ "$#" -ge 2 ] || { echo "Missing value for --project" >&2; exit 1; }
      PROJECT_DIR="$2"
      shift 2
      ;;
    --global-only) GLOBAL_ONLY=1; shift ;;
    --project-only) PROJECT_ONLY=1; shift ;;
    --no-adapters) NO_ADAPTERS=1; shift ;;
    --no-gitignore) NO_GITIGNORE=1; shift ;;
    --no-onboard) NO_ONBOARD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

if [ "$GLOBAL_ONLY" -eq 1 ] && [ "$PROJECT_ONLY" -eq 1 ]; then
  echo "Use only one of --global-only or --project-only." >&2
  exit 1
fi

GLOBAL_DIR="${HOME}/.mindlayer"
DATE="$(date +%Y-%m-%d 2>/dev/null || printf 'YYYY-MM-DD')"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
GLOBAL_TEMPLATE_DIR="$SCRIPT_DIR/global-template"
PROJECT_TEMPLATE_DIR="$SCRIPT_DIR/project-template"

mkdir_p() {
  mkdir -p "$1"
}

write_if_missing() {
  file="$1"
  content="$2"
  if [ ! -e "$file" ]; then
    dir=$(dirname "$file")
    mkdir_p "$dir"
    printf "%s\n" "$content" > "$file"
  fi
}

render_template_file() {
  template_path="$1"
  date_id="${DATE//-/}"
  awk -v date="$DATE" -v date_id="$date_id" '
    {
      gsub(/YYYYMMDD/, date_id)
      gsub(/YYYY-MM-DD/, date)
      print
    }
  ' "$template_path"
}

write_template_if_missing() {
  file="$1"
  template_path="$2"
  fallback_content="$3"
  if [ -e "$file" ]; then
    return
  fi
  dir=$(dirname "$file")
  mkdir_p "$dir"
  if [ -f "$template_path" ]; then
    render_template_file "$template_path" > "$file"
  else
    printf "%s\n" "$fallback_content" | awk -v date="$DATE" -v date_id="${DATE//-/}" '
      {
        gsub(/YYYYMMDD/, date_id)
        gsub(/YYYY-MM-DD/, date)
        print
      }
    ' > "$file"
  fi
}

write_managed_template() {
  file="$1"
  template_path="$2"
  fallback_content="$3"
  dir=$(dirname "$file")
  mkdir_p "$dir"
  tmp=$(mktemp "${TMPDIR:-/tmp}/mindlayer-managed.XXXXXX") || exit 1

  if [ -f "$template_path" ]; then
    cat "$template_path" > "$tmp"
  else
    printf "%s\n" "$fallback_content" | awk -v date="$DATE" -v date_id="${DATE//-/}" '
      {
        gsub(/YYYYMMDD/, date_id)
        gsub(/YYYY-MM-DD/, date)
        print
      }
    ' > "$tmp"
  fi

  if [ -f "$file" ] && cmp -s "$tmp" "$file"; then
    rm -f "$tmp"
    return
  fi

  mv "$tmp" "$file"
}

append_gitignore_rule() {
  file="$1"
  rule="$2"
  if [ ! -e "$file" ]; then
    printf "# MindLayer local/private memory\n" > "$file"
  fi
  if ! grep -Fxq "$rule" "$file"; then
    printf "%s\n" "$rule" >> "$file"
  fi
}

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "sha256sum or shasum is required to lock MindLayer adapters" >&2
    exit 1
  fi
}

global_boot='# MindLayer Boot

Read this file first at every session start. Then read router.md. Then follow the load triggers.

## Boot Sequence

Run once per session, in order, before answering any request:

1. Read ~/.mindlayer/boot.md — you are here.
2. Read ~/.mindlayer/router.md — global load and save triggers.
3. Read .mindlayer/router.md — project load triggers. Skip if file does not exist.
4. Read ~/.mindlayer/memory-system/per-turn.md — always. Controls every response you generate.
5. Read ~/.mindlayer/preferences/personal.md — only if it contains non-scaffold content.
6. Read project .mindlayer/index.md — catalog of project memory.
7. Read project .mindlayer/knowledge/project.md — stable project identity.
8. Load project progress and backlog — check progress.md and backlog.md.
9. Check sessions/ — if a recent session file exists, read only the ## Next section.
10. Check onboard status — scan .mindlayer/index.md for id: ml-onboard-complete. If absent AND .mindlayer/knowledge/project.md contains only placeholder/scaffold content, load memory-system/commands/onboard.md and fire the onboard flow on the first project-relevant turn.
11. Run adapter guard — compare known frozen adapter hashes against .mindlayer/adapters.lock using canonical templates from ~/.mindlayer/memory-system/templates/. Complete this guard before answering the first project-relevant request.

Do not treat a plain greeting as a project-relevant request.

## Adapter Guard

Project adapters are frozen files. They are not durable memory stores and must not contain user edits.

Known frozen adapters:
- AGENTS.md
- CLAUDE.md
- .github/copilot-instructions.md
- GEMINI.md
- .cursor/rules/mindlayer.md
- .windsurf/rules/mindlayer.md

At boot, after loading memory and before answering the first project-relevant request:

1. For each known frozen adapter that exists in the project, hash the file.
2. Compare each hash with .mindlayer/adapters.lock. A missing lock entry means the adapter is unverified.
3. If all hashes match, proceed silently.
4. If any hash mismatches or has no lock entry, diff the current file against the canonical template in ~/.mindlayer/memory-system/templates/.
5. If the diff contains user-added content, alert the user, show the diff, and trigger the ml save flow to route that content to the correct MindLayer destination. Restore the adapter only after the user approves or skips the memory write.
6. If the mismatch is pure template version drift with no user-added content, restore the canonical adapter silently.
7. After restoring an adapter, update .mindlayer/adapters.lock with the new SHA-256 hash.

Never discard user-added adapter content without first routing it through the ml save approval flow.

## Boot Receipt Format

```text
MindLayer context loaded.

Loaded:
- ...

Skipped:
- ...

Missing:
- ...

Current understanding:
...

Current progress:
...

Onboarding:
pending — ml onboard will run on first project-relevant request.
(omit this line entirely when ml-onboard-complete is present in the index)

Context cost:
Approx. N words loaded (~N est. tokens).

Context share:
- Global memory: ~N%
- Project memory: ~N%
- Other sources: 0% (README.md, docs/, and adapters skipped)

Token strategy:
L0 boot: boot.md, router.md, per-turn.md, indexes, project identity, and latest progress only.

Ready.
What would you like to work on?
```

`ml init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.'

global_router='# MindLayer Router

Read this file immediately after boot.md. Then read the project router at .mindlayer/router.md. Then follow the load and save triggers below.

## Always Load (every session, before first response)

- memory-system/per-turn.md — controls Token Burned block on every response. Load immediately after this file.

## Conditional Loads

Load each file at most once per session. Load before acting on the trigger — not after.

| File | Load when | Signal variants |
|---|---|---|
| memory-system/commands/index.md | Any ml * command fires | ml init, ml load, ml retrieve, ml save, ml status, ml session, ml clean, ml onboard |
| memory-system/commands/init.md | ml init invoked | ml init |
| memory-system/commands/load.md | ml load invoked | ml load, ml retrieve, "load X", "retrieve X", "what do we know about X" |
| memory-system/commands/save.md | ml save invoked or save trigger fires | ml save, "remember this", "save this", "add to memory" |
| memory-system/commands/status.md | ml status invoked | ml status, "mstatus", "memory status" |
| memory-system/commands/archive.md | ml clean invoked | ml clean, "clean memory", "forget X", "tidy memory" |
| memory-system/commands/session.md | ml session invoked or session boundary | ml session, "msession", "how much context", "done", "bye", "end session", /compact invoked |
| memory-system/commands/onboard.md | First project-relevant turn when onboard not yet complete | .mindlayer/index.md does NOT contain id: ml-onboard-complete AND .mindlayer/knowledge/project.md is placeholder-only |
| memory-system/read-write.md | Any memory write | About to write to .mindlayer/, save trigger fired, reading memory for a task |
| memory-system/schema.md | Structural question | lifecycle statuses, private/, sessions/, cache/, tmp/, token strategy, folder structure |
| preferences/personal.md | Every session | Non-scaffold content present |
| preferences/*.md | On-demand memory loading | ml load targets cross-project knowledge, or current task needs it |

## Save Triggers

When any signal below is detected, load memory-system/commands/save.md, then scan the current conversation context for memory candidates. Propose each candidate with destination file, action, and content preview. Require explicit approval before writing.

Signal variants: "ml save", "remember this", "save this", "add to memory", "capture this", "save that", "log this", "don'"'"'t want to lose this", "keep this", "preserve this"

## Routing Rules

- User-owned cross-project preferences belong in ~/.mindlayer/preferences/personal.md.
- Cross-project workflows, principles, anti-patterns, and prompt templates belong in ~/.mindlayer/preferences/.
- Project identity, progress, decisions, context, backlog, and risks belong in project/.mindlayer/.
- Do not mirror global memory into project/.mindlayer/; read and write it directly from ~/.mindlayer/.
- Long-term versioned product vision belongs in .mindlayer/pipeline/roadmap.md; near-term tracked tasks belong in .mindlayer/pipeline/backlog.md.
- Private, local, session, cache, and temporary material must stay out of committed project memory.
- When developing MindLayer itself, treat repo .mindlayer/ as the product-memory source of truth and treat live ~/.mindlayer/ as runtime output.
- When a user installs MindLayer on an existing project, auto-trigger ml onboard on the first project-relevant turn.

## Failsafe Rules

- Load each file at most once per session.
- When in doubt, load. A missed rule costs more than 400 tokens.
- Never skip memory-system/per-turn.md. It controls the Token Burned block on every response.
- Always load memory-system/read-write.md BEFORE writing, not after recognizing the need.
- Read the project router (.mindlayer/router.md) immediately after this file.'

global_memory_system_per_turn='# Per-Turn Rules

Load this file at the start of every session, immediately after router.md. Rules here fire on every agent turn for every host agent and adapter. There are no model-specific or tool-specific exceptions.

## Per-Turn Status Block

Append a status block at the end of every agent turn as the last output.

Required every turn:
- Token Burned:
- Last turn approximate words and estimated tokens
- Session approximate words and estimated tokens
- Next Step

A bare Token Burned block without the Last turn and Session estimate lines is invalid.

```text
-------------------------------------------------------------
Token Burned:
  - Last turn: ~N words, ~N est. tokens
  - Session: ~N words, ~N est. tokens

Next Step: <smallest useful action>
--------------------------------------------------------------
```

Use words x 1.3 or characters / 4 to estimate tokens when exact counts are unavailable. Mark estimates with ~. Do not omit estimates because exact token accounting is unavailable.

Next Step prediction hierarchy — always predict something, never leave blank:
1. Active task in progress -> next action within the current task
2. Task complete + uncommitted changes exist -> commit
3. Task complete + clean working tree -> next item in backlog
4. Backlog empty -> next roadmap phase (surface pull proposal)
5. Roadmap complete -> propose brainstorming next major version with the user

Backlog-empty detection — when a task completes and the backlog is empty, append before the Token Burned block:

```text
Backlog complete — next phase: <roadmap phase name and summary>. Say '"'"'pull next phase'"'"' to populate backlog.
```

When the user says '"'"'pull next phase'"'"', decompose the roadmap phase into backlog items and propose each for approval before writing.

## Lateral Intent Routing

When a user introduces work that is not the current Next Step and not in the active backlog, classify the intent before proceeding.

Classification:
- Fits project scope, likely recurring -> Backlog candidate -> Append capture offer, then proceed
- New direction or scope change -> Roadmap amendment -> Append flag, then proceed
- Clearly one-off, no durable value -> Ad-hoc -> Proceed without comment

Rules:
- Classify silently. Do not narrate the classification.
- Never block the user'"'"'s request. The nudge is informational.
- Append at most one nudge per turn, after the main response and before the Token Burned block.
- Do not fire during boot, status checks, or when the user is explicitly responding to a Next Step or backlog pull.

Nudge format:
```text
Lateral intent: <backlog candidate | roadmap amendment> — say '"'"'add to backlog'"'"' or '"'"'add to roadmap'"'"' to capture, or I'"'"'ll just proceed.
```

## Pre-Push Gate

Before surfacing push as a Next Step, or when the user requests a push, append:

```text
Pre-push: tests added and run for this change? Say '"'"'yes'"'"' to push or '"'"'skip'"'"' to push without testing.
```

Rules:
- Fire once per push action.
- yes or skip both proceed immediately — no further prompts.
- Do not fire during boot, status checks, or non-push turns.

## Proactive Behavior

At the end of every turn, before completing the response:
- Check whether the turn produced anything durable worth saving. If yes, surface a memory candidate.
- Check whether the current task context suggests relevant memory not yet loaded. If yes, suggest a retrieval query.
- Estimate session context weight. If heavy or critical, surface a session warning.
- Check whether the backlog is now empty after task completion. If yes, surface a roadmap phase pull proposal.

Surface at most one of each per turn. Append after the primary answer.

Memory candidate format:
```text
Memory candidate: <description> -> <target.md> — say '"'"'go'"'"' to save
```

Retrieval suggestion format:
```text
Relevant context may be available — try: ml load <predicted-query>
```

Session warning format (heavy 60-80%, critical >80%):
```text
Session context: <heavy | critical> (~N% used). Recommend: <compact | new session> — say '"'"'msession'"'"' for full report.
```

Trigger phrases (invoke immediately):
- "remember this", "save this", "add to memory" -> ml save
- "load X", "retrieve X", "what do we know about X" -> ml load <X>
- "where were we", "memory status", "mstatus", "what'"'"'s loaded" -> ml status
- "should I compact", "how much context", "start fresh", "msession" -> ml session
- "clean memory", "forget X", "tidy memory" -> ml clean
- "done for today", "wrapping up", "bye", "end session", "save session" -> session write offer

Session write format:
```text
Session summary ready — say '"'"'save session'"'"' to write knowledge/sessions/YYYY-MM-DD.md.
```'

global_memory_system_commands='# Commands

Load this file when the user invokes any ml * command. Then load the spec file for the specific command from memory-system/commands/. See memory-system/commands/index.md for the full command map.

## Command Behavior

- MindLayer boot initializes the minimum useful context for the current session.
- Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run it before answering the first project-relevant request.
- Do not treat a plain greeting as a project-relevant request.
- A transparent boot receipt should describe what was loaded, skipped, missing, the rough token or word cost, and approximate context share.
- ml init is a legacy/manual refresh alias for showing or rerunning the boot receipt.
- ml load <query> searches indexes first and loads only relevant sections. ml retrieve <query> is a backward-compatible alias.
- ml save proposes memory writes from durable learnings and waits for approval.
- ml status checks memory health and suggests fixes without writing.
- ml clean scans for stale entries and proposes archive or delete actions with approval.
- ml session reports session context cost and recommends compact or new session.
- ml onboard runs once post-install on existing projects to populate .mindlayer/ from existing context.

## Archive Rules

- archive.md exists at ~/.mindlayer/pipeline/archive/archive.md (global) and .mindlayer/pipeline/archive/archive.md (project).
- Boot always skips archive.md. Load it only when ml load explicitly targets archived content.
- Archived entries keep their full markdown section in archive.md for future reference.
- Deleted entries are removed from both the source file and the index.
- Never archive index.md, boot.md, router.md, or archive.md itself.
- ml clean is the public cleanup command. Archive and delete are internal approved actions. Full spec in memory-system/commands/archive.md.

## Index-First Retrieval

Indexes are compact maps for search. They are not full documentation. Search by title, tags, summary, type, status, importance, and last updated date before reading full sections. On boot, read project .mindlayer/index.md and preferences/index.md as catalogs.'

global_memory_system_read_write='# Read and Write Rules

Load this file before any memory read or write operation.

## Write Rules

- Never write memory without literal explicit approval.
- Prefer updating an existing entry over creating a duplicate.
- Do not store raw chat logs.
- Store durable information, not transient thoughts.
- Keep entries compact, structured, and useful for retrieval.
- If a memory write has been proposed but not approved, keep it visible as pending until the user clearly approves or rejects it.

## Read Rules

- Read ~/.mindlayer/boot.md first when initializing MindLayer behavior, then router.md, then follow load triggers.
- Read preferences/personal.md during boot only when it contains substantive user-written preferences.
- Read indexes before full memory files.
- During boot, always check project .mindlayer/knowledge/project.md for stable project identity.
- Load full sections only when relevant.
- Do not use README.md or docs/ as memory input; they are human-facing documentation.
- Treat tool adapters such as AGENTS.md, CLAUDE.md, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or local.md by default.
- Do not load archive.md during boot.
- Cite file and section when using memory.
- State what was loaded and skipped.

## Approval Rules

Memory writes require clear approval even when the content seems obvious. Show the destination, action, duplicate check, and confidence before writing.

Approval must be literal. approve, approved, go ahead, or an equally explicit instruction counts. Acknowledgments or vague statements such as ok, got it, sounds good, or we should save this do not count as approval.'

global_memory_system_commands_index='# Commands Index

Load this file when any ml * command fires. Then load the spec file for the specific command invoked.

## Command Map

| Command | Spec file | When to load |
|---|---|---|
| ml init | commands/init.md | ml init invoked, or boot receipt requested |
| ml load <query> | commands/load.md | ml load, ml retrieve, "load X", "retrieve X", "what do we know about X" |
| ml save | commands/save.md | ml save, "remember this", "save this", "add to memory", "capture this" |
| ml status | commands/status.md | ml status, "mstatus", "memory status", "what'"'"'s loaded" |
| ml clean | commands/archive.md | ml clean, "clean memory", "forget X", "tidy memory" |
| ml session | commands/session.md | ml session, "msession", "how much context", "start fresh", "done", "bye", "end session" |
| ml onboard | commands/onboard.md | First project-relevant turn post-install when .mindlayer/ is starter-only |

## Rules

- Load the spec file for the invoked command immediately after this file.
- Never load all spec files at once — load only the one needed.
- ml clean is the public cleanup command. Archive/delete are internal actions behind approval.
- ml init is a legacy/manual refresh alias for running the boot receipt.'

global_memory_system_schema='# Schema Reference

Load this file when the user asks about lifecycle statuses, subdirectory rules, or token strategy.

## Token Rules

- Use L0 bootstrap for boot.md, router.md, and per-turn.md only.
- Use L1 summaries and indexes for normal retrieval.
- Use L2 full sections only when the query requires detail.
- Do not load entire files by default.
- Treat placeholder scaffolds and local notes as skipped unless relevant or non-placeholder.
- Warn when memory files are nearing their size budget.

## Lifecycle Statuses

- active: current and trusted.
- experimental: useful but not fully proven.
- deprecated: superseded but retained for reference.
- archived: inactive history. Content lives in archive.md. Boot skips archive.md.

## Subdirectory Rules

Subdirectories under .mindlayer/ are created on first use. Never create empty placeholder directories.

### private/
Purpose: sensitive notes not committed to git. Write via ml save when user marks content sensitive. Boot: always skip. Git: gitignored.

### sessions/
Purpose: dated session journals (YYYY-MM-DD.md). Boot: skip full load, surface ## Next from most recent file only. Git: gitignored.

### cache/
Purpose: derived context that can be regenerated. Boot: always skip. Git: gitignored.

### tmp/
Purpose: ephemeral scratch notes within a single session. Boot: skip, warn if stale. Git: gitignored.'

global_index='# Global Memory Index

Agent-written catalog for ~/.mindlayer/. Starts empty — agent adds entries via ml save over time.

For behavioral rules and load triggers, see boot.md and router.md.
For cross-project knowledge catalog, see preferences/index.md.

## Entries

(No entries yet.)'

global_preferences_index="# Preferences Index

Catalog of all files in ~/.mindlayer/preferences/. Agent-written and git-backed.

## Entries

- id: ml-global-YYYYMMDD-pref-000
  title: Personal Preferences
  file: personal.md
  section: User Preferences
  scope: global
  type: preference
  tags: [preferences, collaboration, style]
  summary: User-owned cross-project collaboration style, workflow habits, and personal defaults.
  importance: high
  status: active
  last_updated: YYYY-MM-DD

- id: ml-global-YYYYMMDD-pref-001
  title: Playbook
  file: playbook.md
  section: Global Playbook
  scope: global
  type: playbook
  tags: [playbook, workflows]
  summary: Reusable cross-project workflows and procedures. Empty until agent writes entries.
  importance: medium
  status: active
  last_updated: YYYY-MM-DD

- id: ml-global-YYYYMMDD-pref-002
  title: Principles
  file: principles.md
  section: Global Principles
  scope: global
  type: principle
  tags: [principles, engineering]
  summary: Stable cross-project engineering and product beliefs. Empty until agent writes entries.
  importance: medium
  status: active
  last_updated: YYYY-MM-DD

- id: ml-global-YYYYMMDD-pref-003
  title: Anti-Patterns
  file: anti-patterns.md
  section: Global Anti-Patterns
  scope: global
  type: anti-pattern
  tags: [anti-patterns, mistakes]
  summary: Cross-project mistakes and behaviors to avoid. Empty until agent writes entries.
  importance: medium
  status: active
  last_updated: YYYY-MM-DD

- id: ml-global-YYYYMMDD-pref-004
  title: Prompts
  file: prompts.md
  section: Global Prompts
  scope: global
  type: prompt
  tags: [prompts, templates]
  summary: Reusable cross-project prompt templates. Empty until agent writes entries.
  importance: low
  status: active
  last_updated: YYYY-MM-DD"

global_preferences_personal="# Personal Preferences

User-owned cross-project preferences for how AI coding agents should work with you.

This file is git-backed at ~/.mindlayer/preferences/. Add a remote to back it up:
git -C ~/.mindlayer/preferences remote add origin <your-private-repo>

Do not store secrets, raw conversations, or project-specific facts here.

## User Preferences

id: ml-global-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: preference
tags: [preferences]
confidence: medium
status: active
source: starter

### Summary
No user preferences saved yet.

### Details
Add durable cross-project preferences here only after explicit approval.

### When to use
Skip this section during boot until real user preferences are saved.

### Related"

global_preferences_playbook="# Global Playbook

Reusable cross-project workflows and procedures. Agent writes entries here via ml save when recurring workflows emerge across projects.

## Entry Template

id: template-global-playbook
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: playbook
tags: []
confidence: high
status: template
source: template

### Summary
Short summary.

### Details
Useful details.

### When to use
When this workflow applies.

### Related"

global_preferences_principles="# Global Principles

Stable cross-project engineering and product beliefs. Agent writes entries here via ml save when durable principles emerge.

## Entry Template

id: template-global-principle
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: principle
tags: []
confidence: high
status: template
source: template

### Summary
Short summary.

### Details
Useful details.

### When to use
When this principle should influence decisions.

### Related"

global_preferences_anti_patterns="# Global Anti-Patterns

Cross-project mistakes and behaviors to avoid. Agent writes entries here via ml save when recurring anti-patterns are identified.

## Entry Template

id: template-global-anti-pattern
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: anti-pattern
tags: []
confidence: high
status: template
source: template

### Summary
Short summary.

### Details
Useful details.

### When to use
When this mistake might recur.

### Related"

global_preferences_prompts="# Global Prompts

Reusable cross-project prompt templates. Agent writes entries here via ml save when effective prompt patterns emerge.

## Entry Template

id: template-global-prompt
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: prompt
tags: [prompt]
confidence: high
status: template
source: template

### Summary
Short summary.

### Details
Prompt template and usage notes.

### When to use
When this prompt pattern applies.

### Related"

project_index="# Project Memory Index

Use this file as the compact search map for project .mindlayer/.

## Entries

- id: ml-project-YYYYMMDD-001
  title: Project starter context
  file: knowledge/project.md
  section: Entry Template
  scope: project
  type: context
  tags: []
  summary: Starter project context entry.
  importance: low
  status: active
  last_updated: YYYY-MM-DD"

project_template="# Project Memory

Stable project identity: what this project is, users, goals, stack, architecture, and core modules.

## Entry Template

id: ml-project-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: context
tags: []
confidence: high
status: active
source: manual

### Summary
Short summary.

### Details
Useful details.

### When to use
When this project context matters.

### Related"

progress_template="# Progress

Current working state: phase, completed work, active work, and next steps.

## Current State

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: progress
tags: []
confidence: medium
status: active
source: manual

### Summary
Current phase and immediate next step.

### Details
- Current phase:
- Completed:
- Active:
- Next step:

### When to use
Use during MindLayer boot to understand current project state.

### Related"

decision_template="# Decisions

Project-specific decisions and rationale.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: decision
tags: []
confidence: high
status: active
source: manual

### Summary
Short decision summary.

### Details
Decision, rationale, and consequences.

### When to use
When revisiting this design or product choice.

### Related"

context_template="# Context

Project-specific technical and domain context.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: context
tags: []
confidence: high
status: active
source: manual

### Summary
Short summary.

### Details
Useful details.

### When to use
When this context affects implementation or planning.

### Related"

backlog_template="# Backlog

Future tasks and ideas.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: backlog
tags: []
confidence: medium
status: active
source: manual

### Summary
Short task or idea.

### Details
Useful details.

### When to use
When planning future work.

### Related"

roadmap_template="# Roadmap

Long-term versioned vision for this project. Review and update as priorities shift, new trends emerge, or versions ship.

## Entry Template

id: ml-roadmap-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: roadmap
tags: []
confidence: medium
status: planned
source: manual

### Summary
Short summary of this version or phase.

### Details
- Goal or feature one.
- Goal or feature two.

### Status
planned | in-progress | shipped"

risk_template="# Risks

Known risks, blockers, fragile areas, and trust concerns.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: project
type: risk
tags: []
confidence: medium
status: active
source: manual

### Summary
Short risk summary.

### Details
Impact, trigger, mitigation, and owner if known.

### When to use
When planning or changing related areas.

### Related"

local_template="# Local Notes

Personal local notes for this project. This file should be ignored by Git.

Do not store shared project decisions here. Use committed project memory files for shared project intelligence."


install_global() {
  mkdir_p "$GLOBAL_DIR"

  # Managed system files — always updated on reinstall
  write_managed_template "$GLOBAL_DIR/boot.md" "$GLOBAL_TEMPLATE_DIR/boot.md" "$global_boot"
  write_managed_template "$GLOBAL_DIR/router.md" "$GLOBAL_TEMPLATE_DIR/router.md" "$global_router"

  # memory-system/ subfiles — managed system rules
  mkdir_p "$GLOBAL_DIR/memory-system"
  write_managed_template "$GLOBAL_DIR/memory-system/per-turn.md" "$GLOBAL_TEMPLATE_DIR/memory-system/per-turn.md" "$global_memory_system_per_turn"
  write_managed_template "$GLOBAL_DIR/memory-system/commands.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands.md" "$global_memory_system_commands"
  write_managed_template "$GLOBAL_DIR/memory-system/read-write.md" "$GLOBAL_TEMPLATE_DIR/memory-system/read-write.md" "$global_memory_system_read_write"
  write_managed_template "$GLOBAL_DIR/memory-system/schema.md" "$GLOBAL_TEMPLATE_DIR/memory-system/schema.md" "$global_memory_system_schema"

  # Canonical adapter templates — managed system files
  mkdir_p "$GLOBAL_DIR/memory-system/templates"
  write_managed_template "$GLOBAL_DIR/memory-system/templates/AGENTS.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/AGENTS.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/templates/CLAUDE.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/CLAUDE.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/templates/copilot-instructions.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/copilot-instructions.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/templates/GEMINI.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/GEMINI.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/templates/cursor-mindlayer.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/cursor-mindlayer.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/templates/windsurf-mindlayer.md" "$GLOBAL_TEMPLATE_DIR/memory-system/templates/windsurf-mindlayer.md" ""

  # memory-system/commands/ — per-command spec files
  mkdir_p "$GLOBAL_DIR/memory-system/commands"
  write_managed_template "$GLOBAL_DIR/memory-system/commands/index.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/index.md" "$global_memory_system_commands_index"
  write_managed_template "$GLOBAL_DIR/memory-system/commands/init.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/init.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/load.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/load.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/save.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/save.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/status.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/status.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/archive.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/archive.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/session.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/session.md" ""
  write_managed_template "$GLOBAL_DIR/memory-system/commands/onboard.md" "$GLOBAL_TEMPLATE_DIR/memory-system/commands/onboard.md" ""

  # preferences/ — agent-written cross-project knowledge, git-backed
  mkdir_p "$GLOBAL_DIR/preferences"
  write_template_if_missing "$GLOBAL_DIR/preferences/index.md" "$GLOBAL_TEMPLATE_DIR/preferences/index.md" "$global_preferences_index"
  write_template_if_missing "$GLOBAL_DIR/preferences/personal.md" "$GLOBAL_TEMPLATE_DIR/preferences/personal.md" "$global_preferences_personal"
  write_template_if_missing "$GLOBAL_DIR/preferences/playbook.md" "$GLOBAL_TEMPLATE_DIR/preferences/playbook.md" "$global_preferences_playbook"
  write_template_if_missing "$GLOBAL_DIR/preferences/principles.md" "$GLOBAL_TEMPLATE_DIR/preferences/principles.md" "$global_preferences_principles"
  write_template_if_missing "$GLOBAL_DIR/preferences/anti-patterns.md" "$GLOBAL_TEMPLATE_DIR/preferences/anti-patterns.md" "$global_preferences_anti_patterns"
  write_template_if_missing "$GLOBAL_DIR/preferences/prompts.md" "$GLOBAL_TEMPLATE_DIR/preferences/prompts.md" "$global_preferences_prompts"

  # Git-init preferences/ for crash-safe backup
  git -C "$GLOBAL_DIR/preferences" init --quiet 2>/dev/null || true
  git -C "$GLOBAL_DIR/preferences" config user.email "mindlayer@local" 2>/dev/null || true
  git -C "$GLOBAL_DIR/preferences" config user.name "MindLayer" 2>/dev/null || true
  git -C "$GLOBAL_DIR/preferences" add . 2>/dev/null || true
  git -C "$GLOBAL_DIR/preferences" commit -m "mindlayer: init preferences" --quiet --allow-empty 2>/dev/null || true

  # CLI command runner — managed local runtime files
  mkdir_p "$GLOBAL_DIR/bin"
  mkdir_p "$GLOBAL_DIR/lib"
  if [ -f "$SCRIPT_DIR/src/ml" ] && [ -d "$SCRIPT_DIR/src/commands" ]; then
    cp "$SCRIPT_DIR/src/ml" "$GLOBAL_DIR/bin/ml"
    chmod +x "$GLOBAL_DIR/bin/ml"
    rm -rf "$GLOBAL_DIR/lib/commands"
    cp -R "$SCRIPT_DIR/src/commands" "$GLOBAL_DIR/lib/commands"
  fi
}

install_project_memory() {
  pmem="$PROJECT_DIR/.mindlayer"
  mkdir_p "$pmem"

  write_template_if_missing "$pmem/knowledge/project.md" "$PROJECT_TEMPLATE_DIR/knowledge/project.md" "$project_template"
  write_template_if_missing "$pmem/pipeline/progress.md" "$PROJECT_TEMPLATE_DIR/pipeline/progress.md" "$progress_template"
  write_template_if_missing "$pmem/knowledge/decisions.md" "$PROJECT_TEMPLATE_DIR/knowledge/decisions.md" "$decision_template"
  write_template_if_missing "$pmem/knowledge/context.md" "$PROJECT_TEMPLATE_DIR/knowledge/context.md" "$context_template"
  write_template_if_missing "$pmem/pipeline/backlog.md" "$PROJECT_TEMPLATE_DIR/pipeline/backlog.md" "$backlog_template"
  write_template_if_missing "$pmem/pipeline/roadmap.md" "$PROJECT_TEMPLATE_DIR/pipeline/roadmap.md" "$roadmap_template"
  write_template_if_missing "$pmem/knowledge/risks.md" "$PROJECT_TEMPLATE_DIR/knowledge/risks.md" "$risk_template"
  write_template_if_missing "$pmem/index.md" "$PROJECT_TEMPLATE_DIR/index.md" "$project_index"
  write_template_if_missing "$pmem/local.md" "$PROJECT_TEMPLATE_DIR/local.md" "$local_template"

  rmdir "$pmem/private" "$pmem/knowledge/sessions" "$pmem/cache" "$pmem/tmp" 2>/dev/null || true
}

install_adapters() {
  [ "$NO_ADAPTERS" -eq 0 ] || return

  lock_file="$PROJECT_DIR/.mindlayer/adapters.lock"
  blocked_adapters=""
  installed_adapters=""
  mkdir_p "$PROJECT_DIR/.mindlayer"

  read_locked_adapter_hash() {
    adapter_name="$1"
    [ -f "$lock_file" ] || return 0
    awk -F= -v name="$adapter_name" '$1 == name { print $2; exit }' "$lock_file"
  }

  adapter_is_blocked() {
    adapter_name="$1"
    printf "%s" "$blocked_adapters" | grep -Fxq "$adapter_name"
  }

  adapter_was_installed() {
    adapter_name="$1"
    printf "%s" "$installed_adapters" | grep -Fxq "$adapter_name"
  }

  should_install_adapter() {
    adapter_path="$1"
    signal="$2"
    [ -f "$PROJECT_DIR/$adapter_path" ] || [ "$signal" -eq 1 ]
  }

  install_canonical_adapter() {
    adapter_name="$1"
    dest="$PROJECT_DIR/$adapter_name"
    template_name="$2"
    template="$GLOBAL_TEMPLATE_DIR/memory-system/templates/$template_name"

    if [ ! -f "$template" ]; then
      echo "Missing canonical adapter template: $template" >&2
      exit 1
    fi

    mkdir_p "$(dirname "$dest")"
    tmp_template=$(mktemp "${TMPDIR:-/tmp}/mindlayer-adapter-template.XXXXXX") || exit 1
    cat "$template" > "$tmp_template"

    if [ -f "$dest" ] && ! cmp -s "$tmp_template" "$dest"; then
      current_hash=$(sha256_file "$dest")
      locked_hash=$(read_locked_adapter_hash "$adapter_name")

      if [ -z "$locked_hash" ] || [ "$current_hash" != "$locked_hash" ]; then
        echo "MindLayer adapter content detected in $adapter_name." >&2
        echo "Install will not overwrite this file until the content is routed through ml save." >&2
        echo "Review the diff below, save or skip the added content in a MindLayer session, then rerun install." >&2
        diff -u "$tmp_template" "$dest" >&2 || true
        rm -f "$tmp_template"
        blocked_adapters="${blocked_adapters}${adapter_name}
"
        return
      fi
    fi

    mv "$tmp_template" "$dest"
    installed_adapters="${installed_adapters}${adapter_name}
"
  }

  claude_signal=0
  codex_signal=0
  copilot_signal=0
  gemini_signal=0
  cursor_signal=0
  windsurf_signal=0

  { command -v claude >/dev/null 2>&1 || [ -d "$HOME/.claude" ]; } && claude_signal=1
  command -v codex >/dev/null 2>&1 && codex_signal=1
  command -v gh-copilot >/dev/null 2>&1 && copilot_signal=1
  { command -v gemini >/dev/null 2>&1 || [ -d "$HOME/.gemini" ]; } && gemini_signal=1
  { [ -d "$HOME/.cursor" ] || [ -d "$PROJECT_DIR/.cursor" ]; } && cursor_signal=1
  { [ -d "$HOME/.windsurf" ] || [ -d "$PROJECT_DIR/.windsurf" ]; } && windsurf_signal=1

  need_agents=0
  if should_install_adapter "AGENTS.md" "$codex_signal" ||
     should_install_adapter "CLAUDE.md" "$claude_signal" ||
     should_install_adapter ".github/copilot-instructions.md" "$copilot_signal" ||
     should_install_adapter "GEMINI.md" "$gemini_signal" ||
     should_install_adapter ".cursor/rules/mindlayer.md" "$cursor_signal" ||
     should_install_adapter ".windsurf/rules/mindlayer.md" "$windsurf_signal"; then
    need_agents=1
  fi

  [ "$need_agents" -eq 1 ] && install_canonical_adapter "AGENTS.md" "AGENTS.md"
  should_install_adapter "CLAUDE.md" "$claude_signal" && install_canonical_adapter "CLAUDE.md" "CLAUDE.md"
  should_install_adapter ".github/copilot-instructions.md" "$copilot_signal" && install_canonical_adapter ".github/copilot-instructions.md" "copilot-instructions.md"
  should_install_adapter "GEMINI.md" "$gemini_signal" && install_canonical_adapter "GEMINI.md" "GEMINI.md"
  should_install_adapter ".cursor/rules/mindlayer.md" "$cursor_signal" && install_canonical_adapter ".cursor/rules/mindlayer.md" "cursor-mindlayer.md"
  should_install_adapter ".windsurf/rules/mindlayer.md" "$windsurf_signal" && install_canonical_adapter ".windsurf/rules/mindlayer.md" "windsurf-mindlayer.md"

  if [ -n "$blocked_adapters" ]; then
    echo "MindLayer install blocked for frozen adapter(s):" >&2
    printf "%s" "$blocked_adapters" | sed '/^$/d; s/^/- /' >&2
    echo "Other clean adapters were installed. Route the blocked adapter content through ml save, then rerun install." >&2
  fi

  tmp_lock=$(mktemp "${TMPDIR:-/tmp}/mindlayer-adapters-lock.XXXXXX") || exit 1
  for adapter_name in AGENTS.md CLAUDE.md .github/copilot-instructions.md GEMINI.md .cursor/rules/mindlayer.md .windsurf/rules/mindlayer.md; do
    if adapter_is_blocked "$adapter_name"; then
      locked_hash=$(read_locked_adapter_hash "$adapter_name")
      if [ -n "$locked_hash" ]; then
        printf "%s=%s\n" "$adapter_name" "$locked_hash" >> "$tmp_lock"
      fi
      continue
    fi
    if ! adapter_was_installed "$adapter_name"; then
      locked_hash=$(read_locked_adapter_hash "$adapter_name")
      if [ -n "$locked_hash" ]; then
        printf "%s=%s\n" "$adapter_name" "$locked_hash" >> "$tmp_lock"
      fi
      continue
    fi
    adapter_path="$PROJECT_DIR/$adapter_name"
    [ -f "$adapter_path" ] || continue
    printf "%s=%s\n" "$adapter_name" "$(sha256_file "$adapter_path")" >> "$tmp_lock"
  done
  mv "$tmp_lock" "$lock_file"

  [ -z "$blocked_adapters" ] || return 1
}

install_gitignore() {
  [ "$NO_GITIGNORE" -eq 0 ] || return
  file="$PROJECT_DIR/.gitignore"
  if [ ! -e "$file" ]; then
    printf "# MindLayer local/private memory\n" > "$file"
  elif ! grep -Fxq "# MindLayer local/private memory" "$file"; then
    printf "\n# MindLayer local/private memory\n" >> "$file"
  fi
  append_gitignore_rule "$file" ".mindlayer/local.md"
  append_gitignore_rule "$file" ".mindlayer/private/"
  append_gitignore_rule "$file" ".mindlayer/knowledge/sessions/"
  append_gitignore_rule "$file" ".mindlayer/cache/"
  append_gitignore_rule "$file" ".mindlayer/tmp/"
  append_gitignore_rule "$file" ".mindlayer/adapters.lock"
  append_gitignore_rule "$file" ".cursor/rules/mindlayer.md"
  append_gitignore_rule "$file" ".windsurf/rules/mindlayer.md"
}

if [ "$PROJECT_ONLY" -eq 0 ]; then
  install_global
fi

if [ "$GLOBAL_ONLY" -eq 0 ]; then
  mkdir_p "$PROJECT_DIR"
  install_project_memory
  install_adapters
  install_gitignore
fi

if [ "$NO_ONBOARD" -eq 0 ]; then
  cat <<EOF
MindLayer installed.

Global memory:
~/.mindlayer/

Project memory:
./.mindlayer/

Next step:
Open your AI coding tool. MindLayer-aware adapters now boot minimal context automatically when the host supports tool preflight, or before the first project-relevant request as a fallback. ml init is a legacy/manual refresh alias for showing or rerunning the boot receipt.

Existing project tip:
If this project already has context in README or docs, ask your AI tool to help populate .mindlayer/ files. Use ml save to propose and approve memory entries one at a time.

Session tip:
MindLayer boot is cheap. Start a new session at each task boundary instead of compacting — boot restores project context from durable memory with zero history overhead.

Note: ~/.mindlayer/boot.md, router.md, and memory-system/ subfiles were refreshed with the latest MindLayer behavior rules.
EOF
else
  echo "MindLayer installed."
fi
