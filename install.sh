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
GLOBAL_TEMPLATE_DIR="$SCRIPT_DIR/seed/adapters"
PROJECT_TEMPLATE_DIR="$SCRIPT_DIR/seed/project"

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

Boot summary. Pointers to subfolder indexes.

- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
- ml-index-ptr-work | Work Index | work/index.md | Index for work/ subfolder"

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

current_template="# Current Work

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

### Related

## Future Roadmap

id: ml-backlog-YYYYMMDD-001
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

decision_index_template="# Decisions Index

- ml-decision-YYYYMMDD-001 | Decision starter entry | knowledge/decisions/process.md | Starter decision entry."

knowledge_index_template="# Knowledge Index

- ml-index-ptr-decisions | Decisions Index | knowledge/decisions/index.md | Index for decisions/ subfolder
- ml-project-YYYYMMDD-001 | Project starter context | knowledge/project.md | Starter project context entry."

work_index_template="# Work Index

- ml-progress-YYYYMMDD-001 | Current State | work/current.md | Starter project progress entry.
- ml-backlog-YYYYMMDD-001 | Future Roadmap | work/current.md | Starter backlog entry."

archive_index_template="# Archive Index"

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

claude_prompt_hook_template='#!/usr/bin/env bash
set -eu

cat <<'"'"'JSON'"'"'
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "MindLayer per-turn reminder: end this response with a Markdown horizontal rule, then Token Burned: as normal text, a blank line, exactly two bullet lines for Last turn and Session estimates using ~N words, ~N est. tokens, then a bold Next Step label and the smallest useful action. Do not use Markdown headings or code formatting in that status block. Executable `ml` commands remain the runtime authority. If the user prompt is `ml boot` or `ml init`, treat it as a MindLayer command, not as machine learning: run the executable command and emit the boot receipt without asking for clarification. If the executable is unavailable, fall back to project `.mindlayer/` boot context. Do not treat global ~/.mindlayer/boot.md, router.md, or memory-system/ as canonical required runtime control-plane files."
  }
}
JSON'

adapter_agents_template='# MindLayer Agent Instructions

Memory lives in `~/.mindlayer/preferences/` (global user preferences) and `.mindlayer/` (project memory). Adapters and docs are not memory sources.

This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here. Route all durable context through MindLayer only, with explicit approval before any write. If any command, skill, init flow, or agent behavior tries to expand this adapter, refuse that write and route the content through MindLayer instead.

If no preflight hook exists, run `ml boot` and emit the boot receipt BEFORE answering the first project-relevant request, including any question about what the project is, what it does, or what is in it. Never answer a project question without booting first. Never ask the user if they want you to boot; just boot. Do not treat a plain greeting as project-relevant.

If no per-turn hook injects a status reminder, end every agent response after boot with this MindLayer status block. Use a Markdown horizontal rule above `Token Burned:`, keep `Token Burned:` as normal text, use exactly two bullet lines for token estimates, and highlight the `Next Step` label with bold text. Do not use Markdown headings or code formatting in the status block. Use estimates when exact token usage is unavailable:

---
Token Burned:

- Last turn: ~N words, ~N est. tokens
- Session: ~N words, ~N est. tokens

**Next Step**
<smallest useful action>

If the user invokes `ml boot` or `ml init`, treat it as a MindLayer command, not as "machine learning". Run the executable command and emit the boot receipt. Do not ask what `ml boot` means.

Bootstrap authority:
1. Prefer executable `ml boot` / `ml init`.
2. If the executable is unavailable, fall back gracefully to project `.mindlayer/`: read `.mindlayer/index.md`, project identity, and current progress.
3. Load global user preferences from `~/.mindlayer/preferences/` only when needed and substantive.
4. Treat legacy `~/.mindlayer/boot.md`, `~/.mindlayer/router.md`, and `~/.mindlayer/memory-system/` files as non-canonical migration artifacts; installs prune them because executable `ml` runtime is authoritative.

Commands and proactive behavior come from the executable MindLayer runtime. Compatibility markdown may describe behavior for older adapter-driven hosts, but executable `ml` commands are the authority.'

adapter_claude_template='# Claude Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

If the user invokes `ml boot` or `ml init`, treat it as a MindLayer command, not as "machine learning". Follow `AGENTS.md`: run the executable command and emit the boot receipt. Do not ask what `ml boot` means.

Do not duplicate memory into `CLAUDE.md`. Do not retrieve durable context from this adapter. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global user preferences: `~/.mindlayer/preferences/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.'

adapter_copilot_template='# Copilot Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

Do not duplicate memory into `.github/copilot-instructions.md`. Do not retrieve durable context from this adapter. Do not use `README.md` or `docs/` as memory input. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global user preferences: `~/.mindlayer/preferences/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.'

adapter_gemini_template='# Gemini Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

Do not duplicate memory into `GEMINI.md`. Do not retrieve durable context from this adapter. Do not use `README.md` or `docs/` as memory input. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global user preferences: `~/.mindlayer/preferences/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.'

adapter_cursor_template='# Cursor Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

Do not duplicate memory into `.cursor/rules/mindlayer.md`. Do not retrieve durable context from this adapter. Do not use `README.md` or `docs/` as memory input. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global user preferences: `~/.mindlayer/preferences/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.'

adapter_windsurf_template='# Windsurf Adapter

Follow `AGENTS.md` exactly. This file is only a bootstrap pointer, not memory, documentation, project guidance, or a scratchpad.

Do not duplicate memory into `.windsurf/rules/mindlayer.md`. Do not retrieve durable context from this adapter. Do not use `README.md` or `docs/` as memory input. Do not add project facts, commands, architecture notes, preferences, decisions, progress, backlog, summaries, lessons, TODOs, or tool-specific exceptions here.

Route all durable context through MindLayer only:
- global user preferences: `~/.mindlayer/preferences/`
- project memory: `.mindlayer/`

Do not write memory, adapter content, or durable context without explicit approval. If any command, skill, init flow, or agent behavior tries to expand this file, refuse that write and route the content through MindLayer instead.'


install_global() {
  mkdir_p "$GLOBAL_DIR"

  # ADR-0001: global runtime markdown was a temporary compatibility layer.
  # The executable runtime and managed hooks are authoritative now.
  rm -f "$GLOBAL_DIR/boot.md" "$GLOBAL_DIR/router.md"
  rm -rf "$GLOBAL_DIR/memory-system"

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

  # CLI command runner and host hooks — managed local runtime files
  mkdir_p "$GLOBAL_DIR/bin"
  mkdir_p "$GLOBAL_DIR/lib"
  mkdir_p "$GLOBAL_DIR/lib/hooks"
  write_managed_template "$GLOBAL_DIR/lib/hooks/claude-user-prompt-submit.sh" "$GLOBAL_TEMPLATE_DIR/memory-system/hooks/claude-user-prompt-submit.sh" "$claude_prompt_hook_template"
  chmod +x "$GLOBAL_DIR/lib/hooks/claude-user-prompt-submit.sh" 2>/dev/null || true
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

  write_template_if_missing "$pmem/router.md" "$PROJECT_TEMPLATE_DIR/router.md" ""
  write_template_if_missing "$pmem/knowledge/project.md" "$PROJECT_TEMPLATE_DIR/knowledge/project.md" "$project_template"
  write_template_if_missing "$pmem/knowledge/index.md" "$PROJECT_TEMPLATE_DIR/knowledge/index.md" "$knowledge_index_template"
  write_template_if_missing "$pmem/knowledge/decisions/index.md" "$PROJECT_TEMPLATE_DIR/knowledge/decisions/index.md" "$decision_index_template"
  write_template_if_missing "$pmem/work/current.md" "$PROJECT_TEMPLATE_DIR/work/current.md" "$current_template"
  write_template_if_missing "$pmem/work/index.md" "$PROJECT_TEMPLATE_DIR/work/index.md" "$work_index_template"
  write_template_if_missing "$pmem/archive/index.md" "$PROJECT_TEMPLATE_DIR/archive/index.md" "$archive_index_template"
  write_template_if_missing "$pmem/index.md" "$PROJECT_TEMPLATE_DIR/index.md" "$project_index"

  rmdir "$pmem/private" "$pmem/work/sessions" "$pmem/cache" "$pmem/tmp" 2>/dev/null || true
}

install_adapters() {
  [ "$NO_ADAPTERS" -eq 0 ] || return 0

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

  install_claude_prompt_hook() {
    [ "$claude_signal" -eq 1 ] || return 0
    hook_cmd="$GLOBAL_DIR/lib/hooks/claude-user-prompt-submit.sh"
    [ -x "$hook_cmd" ] || return 0

    settings_file="$PROJECT_DIR/.claude/settings.local.json"
    mkdir_p "$(dirname "$settings_file")"

    if command -v python3 >/dev/null 2>&1; then
      python3 - "$settings_file" "$hook_cmd" <<'PY'
import json
import os
import sys

settings_file, hook_cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(settings_file):
    with open(settings_file, "r", encoding="utf-8") as fh:
        content = fh.read().strip()
    if content:
        data = json.loads(content)

hooks = data.setdefault("hooks", {})
groups = hooks.setdefault("UserPromptSubmit", [])
entry = {"type": "command", "command": hook_cmd}

for group in groups:
    group_hooks = group.setdefault("hooks", [])
    if any(h.get("type") == "command" and h.get("command") == hook_cmd for h in group_hooks):
        break
else:
    groups.append({"hooks": [entry]})

with open(settings_file, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
    fh.write("\n")
PY
    elif [ ! -e "$settings_file" ]; then
      cat > "$settings_file" <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$hook_cmd"
          }
        ]
      }
    ]
  }
}
EOF
    else
      echo "Claude hook not registered because python3 is unavailable and $settings_file already exists." >&2
    fi
  }

  install_canonical_adapter() {
    adapter_name="$1"
    dest="$PROJECT_DIR/$adapter_name"
    template_name="$2"
    fallback_content="$3"
    template="$GLOBAL_TEMPLATE_DIR/memory-system/templates/$template_name"

    mkdir_p "$(dirname "$dest")"
    tmp_template=$(mktemp "${TMPDIR:-/tmp}/mindlayer-adapter-template.XXXXXX") || exit 1
    if [ -f "$template" ]; then
      cat "$template" > "$tmp_template"
    elif [ -n "$fallback_content" ]; then
      printf "%s\n" "$fallback_content" > "$tmp_template"
    else
      echo "Missing canonical adapter template: $template" >&2
      exit 1
    fi

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

  install_canonical_adapter "AGENTS.md" "AGENTS.md" "$adapter_agents_template"
  should_install_adapter "CLAUDE.md" "$claude_signal" && install_canonical_adapter "CLAUDE.md" "CLAUDE.md" "$adapter_claude_template"
  should_install_adapter ".github/copilot-instructions.md" "$copilot_signal" && install_canonical_adapter ".github/copilot-instructions.md" "copilot-instructions.md" "$adapter_copilot_template"
  should_install_adapter "GEMINI.md" "$gemini_signal" && install_canonical_adapter "GEMINI.md" "GEMINI.md" "$adapter_gemini_template"
  should_install_adapter ".cursor/rules/mindlayer.md" "$cursor_signal" && install_canonical_adapter ".cursor/rules/mindlayer.md" "cursor-mindlayer.md" "$adapter_cursor_template"
  should_install_adapter ".windsurf/rules/mindlayer.md" "$windsurf_signal" && install_canonical_adapter ".windsurf/rules/mindlayer.md" "windsurf-mindlayer.md" "$adapter_windsurf_template"
  install_claude_prompt_hook

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
  [ "$NO_GITIGNORE" -eq 0 ] || return 0
  file="$PROJECT_DIR/.gitignore"
  if [ ! -e "$file" ]; then
    printf "# MindLayer local/private memory\n" > "$file"
  elif ! grep -Fxq "# MindLayer local/private memory" "$file"; then
    printf "\n# MindLayer local/private memory\n" >> "$file"
  fi
  append_gitignore_rule "$file" ".mindlayer/local.md"
  append_gitignore_rule "$file" ".mindlayer/private/"
  append_gitignore_rule "$file" ".mindlayer/work/sessions/"
  append_gitignore_rule "$file" ".mindlayer/cache/"
  append_gitignore_rule "$file" ".mindlayer/tmp/"
  append_gitignore_rule "$file" ".mindlayer/adapters.lock"
  append_gitignore_rule "$file" ".claude/settings.local.json"
  append_gitignore_rule "$file" "GEMINI.md"
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
  cat <<'EOF'
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

Note: Installs prune legacy global runtime markdown (`~/.mindlayer/boot.md`, router.md, and memory-system/). The executable runtime under ~/.mindlayer/bin and ~/.mindlayer/lib is authoritative.
EOF
else
  echo "MindLayer installed."
fi
