#!/usr/bin/env bash
set -eu

PROJECT_DIR="$(pwd)"
GLOBAL_ONLY=0
PROJECT_ONLY=0
NO_ADAPTERS=0
NO_GITIGNORE=0
NO_ONBOARD=0
TOOL="all"

usage() {
  cat <<'EOF'
Usage: bash install.sh [options]

Options:
  --project <path>   Install project memory into path. Default: current directory.
  --global-only      Only create/update ~/.mindlayer.
  --project-only     Only create/update project .mindlayer and adapters.
  --no-adapters      Do not modify AGENTS.md, CLAUDE.md, or Copilot instructions.
  --no-gitignore     Do not modify .gitignore.
  --no-onboard       Minimal terminal output.
  --tool <name>      all, codex, claude, or copilot. Default: all.
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
    --tool)
      [ "$#" -ge 2 ] || { echo "Missing value for --tool" >&2; exit 1; }
      TOOL="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$TOOL" in
  all|codex|claude|copilot) ;;
  *) echo "Invalid --tool value: $TOOL" >&2; exit 1 ;;
esac

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

update_marked_block() {
  file="$1"
  block="$2"
  start="<!-- mindlayer:start -->"
  end="<!-- mindlayer:end -->"
  dir=$(dirname "$file")
  mkdir_p "$dir"

  if [ ! -e "$file" ]; then
    printf "%s\n" "$block" > "$file"
    return
  fi

  tmp=$(mktemp "${TMPDIR:-/tmp}/mindlayer.XXXXXX") || exit 1
  blockfile=$(mktemp "${TMPDIR:-/tmp}/mindlayer-block.XXXXXX") || exit 1
  printf "%s\n" "$block" > "$blockfile"

  awk -v start="$start" -v end="$end" -v blockfile="$blockfile" '
    BEGIN {
      while ((getline line < blockfile) > 0) {
        block = block line ORS
      }
      inblock = 0
      replaced = 0
    }
    $0 == start {
      printf "%s", block
      inblock = 1
      replaced = 1
      next
    }
    $0 == end && inblock {
      inblock = 0
      next
    }
    !inblock { print }
    END {
      if (!replaced) {
        print ""
        printf "%s", block
      }
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
  rm -f "$blockfile"
}

global_memory_system="# MindLayer Memory System

MindLayer is a markdown-first memory system for AI-native software development. It helps agents remember durable knowledge, retrieve it cheaply, and avoid unsafe or noisy memory behavior.

## Command Behavior

- MindLayer boot initializes the minimum useful context for the current session.
- MindLayer boot must read this file first when available, then indexes, then essential preferences, project identity, and current progress.
- Run MindLayer boot at session start or tool preflight when the host supports it. If no preflight hook exists, run it before answering the first project-relevant request.
- Do not treat a plain greeting as a project-relevant request. If boot has not already run, answer naturally and boot before the first substantive project task.
- /m-init is a legacy/manual refresh alias for showing or rerunning the boot receipt while hosts migrate to automatic boot.
- /m-retrieve <query> searches indexes first and loads only relevant sections.
- /m-save proposes memory writes from durable learnings and waits for approval.
- /m-status checks memory health and suggests fixes without writing.

## Rules

- Never write memory without explicit approval.
- Read this file first when initializing MindLayer behavior.
- Read indexes before full memory files.
- During MindLayer boot, always check project .mindlayer/project.md for stable project identity even when the project index marks it low importance or starter-like; report placeholder-only project identity as missing or starter-only.
- Do not use README.md or docs/ as memory input; they are human-facing documentation.
- Treat tool adapters such as AGENTS.md, CLAUDE.md, and Copilot instructions as thin instructions, not durable memory stores or retrieval sources.
- Do not load empty scaffold files or local.md by default.
- Load scaffold files or local.md only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Go outside MindLayer memory only when necessary for the current task.
- Prefer updating existing entries over creating duplicates.
- Do not store raw chat logs.
- Route global preferences to ~/.mindlayer/.
- Route project decisions, context, progress, backlog, and risks to project .mindlayer/.
- Use active, experimental, deprecated, and archived lifecycle statuses.
- Warn when memory files are nearing their size budget, not only after they overflow.
- Prompt for cleanup, merge, compression, or archive before adding more memory to near-limit files.
- Use index-first retrieval and keep token usage transparent."

global_index="# Global Memory Index

Use this file as the compact search map for ~/.mindlayer/.

## Entries

- id: ml-global-YYYYMMDD-000
  title: MindLayer Memory System
  file: memory-system.md
  section: MindLayer Memory System
  scope: global
  type: system
  tags: [mindlayer, memory-system, commands, retrieval]
  summary: Core MindLayer command behavior, read/write rules, routing, token discipline, approval rules, lifecycle statuses, and index-first retrieval.
  importance: high
  status: active
  last_updated: YYYY-MM-DD

- id: ml-global-YYYYMMDD-001
  title: MindLayer global preferences starter
  file: preferences.md
  section: Starter Preferences
  scope: global
  type: preference
  tags: [mindlayer, preferences]
  summary: Starter always-loaded preferences for safe, approval-based memory use.
  importance: high
  status: active
  last_updated: YYYY-MM-DD"

global_preferences="# Global Preferences

Always-loaded cross-project user preferences, habits, tool choices, and constraints.

## Starter Preferences

id: ml-global-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: preference
tags: [mindlayer, preferences, approval]
confidence: medium
status: active
source: manual

### Summary
Use MindLayer memory cautiously and require approval before writes.

### Details
The user prefers transparent memory behavior, low token usage, and explicit approval before durable memory changes.

### When to use
Use in every session as always-on global preference context.

### Related"

global_playbook="# Global Playbook

Reusable workflows and procedures.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: playbook
tags: []
confidence: high
status: active
source: manual

### Summary
Short summary.

### Details
Useful details.

### When to use
When this workflow applies.

### Related"

global_principles="# Global Principles

Stable engineering and product beliefs.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: principle
tags: []
confidence: high
status: active
source: manual

### Summary
Short summary.

### Details
Useful details.

### When to use
When this principle should influence decisions.

### Related"

global_anti_patterns="# Global Anti-Patterns

Mistakes and behaviors to avoid.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: anti-pattern
tags: []
confidence: high
status: active
source: manual

### Summary
Short summary.

### Details
Useful details.

### When to use
When this mistake might recur.

### Related"

global_prompts="# Global Prompts

Reusable prompt templates.

## Entry Template

id: ml-YYYYMMDD-001
created: YYYY-MM-DD
updated: YYYY-MM-DD
scope: global
type: playbook
tags: [prompt]
confidence: high
status: active
source: manual

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
  file: project.md
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

config_json='{
  "version": 1,
  "memory_system": "mindlayer",
  "global_memory": "~/.mindlayer",
  "write_requires_approval": true,
  "index_first_retrieval": true
}'

install_global() {
  mkdir_p "$GLOBAL_DIR"
  write_template_if_missing "$GLOBAL_DIR/memory-system.md" "$GLOBAL_TEMPLATE_DIR/memory-system.md" "$global_memory_system"
  write_template_if_missing "$GLOBAL_DIR/index.md" "$GLOBAL_TEMPLATE_DIR/index.md" "$global_index"
  ensure_global_memory_system_index
  write_template_if_missing "$GLOBAL_DIR/preferences.md" "$GLOBAL_TEMPLATE_DIR/preferences.md" "$global_preferences"
  write_template_if_missing "$GLOBAL_DIR/playbook.md" "$GLOBAL_TEMPLATE_DIR/playbook.md" "$global_playbook"
  write_template_if_missing "$GLOBAL_DIR/principles.md" "$GLOBAL_TEMPLATE_DIR/principles.md" "$global_principles"
  write_template_if_missing "$GLOBAL_DIR/anti-patterns.md" "$GLOBAL_TEMPLATE_DIR/anti-patterns.md" "$global_anti_patterns"
  write_template_if_missing "$GLOBAL_DIR/prompts.md" "$GLOBAL_TEMPLATE_DIR/prompts.md" "$global_prompts"
  write_template_if_missing "$GLOBAL_DIR/config.json" "$GLOBAL_TEMPLATE_DIR/config.json" "$config_json"
}

ensure_global_memory_system_index() {
  index_file="$GLOBAL_DIR/index.md"
  [ -f "$index_file" ] || return
  if grep -Fq "file: memory-system.md" "$index_file"; then
    return
  fi

  cat >> "$index_file" <<EOF

- id: ml-global-${DATE//-/}-000
  title: MindLayer Memory System
  file: memory-system.md
  section: MindLayer Memory System
  scope: global
  type: system
  tags: [mindlayer, memory-system, commands, retrieval]
  summary: Core MindLayer command behavior, read/write rules, routing, token discipline, approval rules, lifecycle statuses, and index-first retrieval.
  importance: high
  status: active
  last_updated: $DATE
EOF
}

install_project_memory() {
  pmem="$PROJECT_DIR/.mindlayer"
  mkdir_p "$pmem"
  mkdir_p "$pmem/private"
  mkdir_p "$pmem/sessions"
  mkdir_p "$pmem/cache"
  mkdir_p "$pmem/tmp"

  write_template_if_missing "$pmem/project.md" "$PROJECT_TEMPLATE_DIR/project.md" "$project_template"
  write_template_if_missing "$pmem/progress.md" "$PROJECT_TEMPLATE_DIR/progress.md" "$progress_template"
  write_template_if_missing "$pmem/decisions.md" "$PROJECT_TEMPLATE_DIR/decisions.md" "$decision_template"
  write_template_if_missing "$pmem/context.md" "$PROJECT_TEMPLATE_DIR/context.md" "$context_template"
  write_template_if_missing "$pmem/backlog.md" "$PROJECT_TEMPLATE_DIR/backlog.md" "$backlog_template"
  write_template_if_missing "$pmem/risks.md" "$PROJECT_TEMPLATE_DIR/risks.md" "$risk_template"
  write_template_if_missing "$pmem/index.md" "$PROJECT_TEMPLATE_DIR/index.md" "$project_index"
  write_template_if_missing "$pmem/local.md" "$PROJECT_TEMPLATE_DIR/local.md" "$local_template"
}

install_adapters() {
  [ "$NO_ADAPTERS" -eq 0 ] || return

  codex_block='<!-- mindlayer:start -->
MindLayer memory is stored outside this adapter.

Global memory: `~/.mindlayer/`
Project memory: `.mindlayer/`

MindLayer boot should run at session start or tool preflight when the host supports it. If no preflight hook exists, run boot before answering the first project-relevant request. Do not treat a plain greeting as project-relevant.

Boot order:
1. Read `~/.mindlayer/memory-system.md` first when available.
2. Read `~/.mindlayer/index.md` and `.mindlayer/index.md`.
3. Load only essential global preferences, project identity, and current progress.

Use this exact boot receipt format when the boot is visible to the user:

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

Context cost:
Approx. N words loaded.

Ready.
What would you like to work on?
```

`/m-init` is a legacy/manual refresh alias for showing or rerunning the boot receipt.
Use `/m-retrieve <query>` when specific memory is needed.
Use `/m-save` only to propose memory writes; never write without approval.
Use `/m-status` to check memory health.

Rules:
- Do not use `README.md` or `docs/` as memory input.
- Use index files before full files.
- Prefer update over duplicate.
- Keep token usage transparent.
- Do not dump raw conversations into memory.
- Keep adapters thin; do not store or retrieve durable memory here.
- Go outside MindLayer memory only when necessary for the task.
<!-- mindlayer:end -->'

  claude_block='<!-- mindlayer:start -->
Follow `AGENTS.md`.

MindLayer memory sources of truth are `~/.mindlayer/` and project `.mindlayer/`. `README.md` and `docs/` are human documentation, not default AI memory input.

Do not duplicate memory into `CLAUDE.md` or retrieve durable context from this adapter. Do not write memory without approval. Follow `AGENTS.md` for automatic MindLayer boot; `/m-init` is only a legacy/manual refresh alias.
<!-- mindlayer:end -->'

  copilot_block='<!-- mindlayer:start -->
Follow `AGENTS.md`.

Use project `.mindlayer/` for project context. Use `~/.mindlayer/` for global user memory when available.

Run MindLayer boot at session start or before the first project-relevant request. Read `~/.mindlayer/memory-system.md` first when available, then indexes, and report a compact context receipt when visible to the user.

Do not use `README.md` or `docs/` as memory input. Do not retrieve durable context from this adapter. Do not modify memory files unless explicitly requested. Keep generated changes minimal and safe.
<!-- mindlayer:end -->'

  case "$TOOL" in
    all)
      update_marked_block "$PROJECT_DIR/AGENTS.md" "$codex_block"
      update_marked_block "$PROJECT_DIR/CLAUDE.md" "$claude_block"
      update_marked_block "$PROJECT_DIR/.github/copilot-instructions.md" "$copilot_block"
      ;;
    codex) update_marked_block "$PROJECT_DIR/AGENTS.md" "$codex_block" ;;
    claude) update_marked_block "$PROJECT_DIR/CLAUDE.md" "$claude_block" ;;
    copilot) update_marked_block "$PROJECT_DIR/.github/copilot-instructions.md" "$copilot_block" ;;
  esac
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
  append_gitignore_rule "$file" ".mindlayer/sessions/"
  append_gitignore_rule "$file" ".mindlayer/cache/"
  append_gitignore_rule "$file" ".mindlayer/tmp/"
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
Open your AI coding tool. MindLayer-aware adapters now boot minimal context automatically when the host supports session preflight, or before the first project-relevant request as a fallback. /m-init remains only a legacy/manual refresh alias.
EOF
else
  echo "MindLayer installed."
fi
