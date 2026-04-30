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

- /m-init loads the minimum useful context for the current session.
- /m-retrieve <query> searches indexes first and loads only relevant sections.
- /m-save proposes memory writes from durable learnings and waits for approval.
- /m-status checks memory health and suggests fixes without writing.

## Rules

- Never write memory without explicit approval.
- Read indexes before full memory files.
- Do not load empty scaffold files or local.md by default.
- Load scaffold files or local.md only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.
- Prefer updating existing entries over creating duplicates.
- Do not store raw chat logs.
- Route global preferences to ~/.mindlayer/.
- Route project decisions, context, progress, backlog, and risks to project .mindlayer/.
- Use active, experimental, deprecated, and archived lifecycle statuses.
- Use index-first retrieval and keep token usage transparent."

global_index="# Global Memory Index

Use this file as the compact search map for ~/.mindlayer/.

## Entries

- id: ml-${DATE//-/}-001
  title: MindLayer global memory starter
  file: memory.md
  section: Starter Preferences
  scope: global
  type: preference
  tags: [mindlayer, memory]
  summary: Starter preferences for safe, approval-based memory use.
  importance: high
  status: active
  last_updated: $DATE"

global_memory="# Global Memory

Stable cross-project user preferences, habits, tool choices, and constraints.

## Starter Preferences

id: ml-${DATE//-/}-001
created: $DATE
updated: $DATE
scope: global
type: preference
tags: [mindlayer, memory, approval]
confidence: medium
status: active
source: manual

### Summary
Use MindLayer memory cautiously and require approval before writes.

### Details
The user prefers transparent memory behavior, low token usage, and explicit approval before durable memory changes.

### When to use
Use when deciding whether to save or update long-term memory.

### Related"

entry_template_global="# Entry Template

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
When this memory should be retrieved.

### Related"

project_index="# Project Memory Index

Use this file as the compact search map for project .mindlayer/.

## Entries

- id: ml-YYYYMMDD-001
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
When this memory should be retrieved.

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
Use during /m-init to understand current project state.

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
  write_if_missing "$GLOBAL_DIR/memory-system.md" "$global_memory_system"
  write_if_missing "$GLOBAL_DIR/index.md" "$global_index"
  write_if_missing "$GLOBAL_DIR/memory.md" "$global_memory"
  write_if_missing "$GLOBAL_DIR/playbook.md" "# Global Playbook

Reusable workflows and procedures.

$entry_template_global"
  write_if_missing "$GLOBAL_DIR/principles.md" "# Global Principles

Stable engineering and product beliefs.

$entry_template_global"
  write_if_missing "$GLOBAL_DIR/anti-patterns.md" "# Global Anti-Patterns

Mistakes and behaviors to avoid.

$entry_template_global"
  write_if_missing "$GLOBAL_DIR/prompts.md" "# Global Prompts

Reusable prompt templates.

$entry_template_global"
  write_if_missing "$GLOBAL_DIR/config.json" "$config_json"
}

install_project_memory() {
  pmem="$PROJECT_DIR/.mindlayer"
  mkdir_p "$pmem"
  mkdir_p "$pmem/private"
  mkdir_p "$pmem/sessions"
  mkdir_p "$pmem/cache"
  mkdir_p "$pmem/tmp"

  write_if_missing "$pmem/project.md" "$project_template"
  write_if_missing "$pmem/progress.md" "$progress_template"
  write_if_missing "$pmem/decisions.md" "$decision_template"
  write_if_missing "$pmem/context.md" "$context_template"
  write_if_missing "$pmem/backlog.md" "$backlog_template"
  write_if_missing "$pmem/risks.md" "$risk_template"
  write_if_missing "$pmem/index.md" "$project_index"
  write_if_missing "$pmem/local.md" "$local_template"

  if [ ! -e "$pmem/memory.md" ] && [ ! -L "$pmem/memory.md" ]; then
    if ln -s "$GLOBAL_DIR/memory.md" "$pmem/memory.md" 2>/dev/null; then
      :
    else
      write_if_missing "$pmem/memory.md" "# Global Memory Pointer

Global memory lives at:

~/.mindlayer/memory.md

Do not duplicate global memory into the project."
    fi
  fi
}

install_adapters() {
  [ "$NO_ADAPTERS" -eq 0 ] || return

  codex_block='<!-- mindlayer:start -->
MindLayer memory is stored outside this adapter.

Global memory: `~/.mindlayer/`
Project memory: `.mindlayer/`

Use `/m-init` when the user asks to initialize memory context.
Use `/m-retrieve <query>` when specific memory is needed.
Use `/m-save` only to propose memory writes; never write without approval.
Use `/m-status` to check memory health.

Rules:
- Do not use `README.md` as memory input.
- Use index files before full files.
- Prefer update over duplicate.
- Keep token usage transparent.
- Do not dump raw conversations into memory.
<!-- mindlayer:end -->'

  claude_block='<!-- mindlayer:start -->
Follow `AGENTS.md`.

MindLayer memory sources of truth are `~/.mindlayer/` and project `.mindlayer/`.

Do not duplicate memory into `CLAUDE.md`. Do not write memory without approval. Use `/m-init` behavior at session start when requested.
<!-- mindlayer:end -->'

  copilot_block='<!-- mindlayer:start -->
Follow `AGENTS.md`.

Use project `.mindlayer/` for project context. Use `~/.mindlayer/` for global user memory when available.

Do not modify memory files unless explicitly requested. Keep generated changes minimal and safe.
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
  append_gitignore_rule "$file" ".mindlayer/memory.md"
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
Open your AI coding tool and run:

/m-init
EOF
else
  echo "MindLayer installed."
fi
