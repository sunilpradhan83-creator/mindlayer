#!/usr/bin/env bash
# MindLayer linter
#
# Turns the conventions in AGENTS.md into machine-checked invariants.
# Runs against project .mindlayer/ (and optionally ~/.mindlayer/).
#
# Exit codes:
#   0  all checks passed (warnings allowed unless --strict)
#   1  one or more errors
#
# Checks performed:
#   E1  project .mindlayer/ exists
#   E2  project .mindlayer/index.md exists
#   E3  every index entry has required keys (id, title, file)
#   E4  no duplicate ids across project (and global, if --include-global)
#   E5  every resolved leaf or pointer entry's `file` exists
#   E6  every resolved leaf entry's `section` appears as a heading in its `file`
#   E7  source-boundary rules are present in adapters, boot prompt, and templates
#   W1  entries with last_updated older than --stale-days (default 180)
#   W2  any committed memory file is nearing --max-lines (default 240 of 300)
#   W3  any committed memory file exceeds --max-lines (default 300)
#   W4  files still containing "YYYY-MM-DD" placeholders (empty scaffold)
#   W5  ignorable paths present in git index (local.md, private/, sessions/, cache/, tmp/)

set -u

PROJECT_DIR="$(pwd)"
INCLUDE_GLOBAL=0
STRICT=0
STALE_DAYS=180
MAX_LINES=300
WARN_LINES=240

usage() {
  cat <<'EOF'
Usage: bash tools/lint.sh [options]

Options:
  --project <path>      Project root. Default: current directory.
  --include-global      Also lint ~/.mindlayer/.
  --strict              Treat warnings as errors.
  --stale-days <n>      Warn when last_updated is older than n days. Default: 180.
  --warn-lines <n>      Warn when a memory file reaches n lines. Default: 240.
  --max-lines <n>       Warn when a memory file exceeds n lines. Default: 300.
  -h, --help            Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --include-global) INCLUDE_GLOBAL=1; shift ;;
    --strict) STRICT=1; shift ;;
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    --warn-lines) WARN_LINES="$2"; shift 2 ;;
    --max-lines) MAX_LINES="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

ERRORS=0
WARNINGS=0

err()  { printf "ERROR  %s\n" "$1"; ERRORS=$((ERRORS + 1)); }
warn() { printf "WARN   %s\n" "$1"; WARNINGS=$((WARNINGS + 1)); }
ok()   { printf "OK     %s\n" "$1"; }

require_contains() {
  file="$1"
  pattern="$2"
  label="$3"

  [ -f "$file" ] || return
  if ! grep -Fq "$pattern" "$file"; then
    err "[E7] $label missing source-boundary rule: $pattern"
  fi
}

require_file() {
  file="$1"
  label="$2"

  if [ ! -f "$file" ]; then
    err "[E7] $label missing required file: $file"
  fi
}

require_not_contains() {
  file="$1"
  pattern="$2"
  label="$3"

  [ -f "$file" ] || return
  if grep -Fq "$pattern" "$file"; then
    err "[E7] $label contains removed adapter delimiter: $pattern"
  fi
}

require_same_file() {
  actual="$1"
  expected="$2"
  label="$3"

  if [ ! -f "$actual" ]; then
    err "[E7] $label missing file: $actual"
    return
  fi
  if [ ! -f "$expected" ]; then
    err "[E7] $label missing canonical template: $expected"
    return
  fi
  if ! cmp -s "$actual" "$expected"; then
    err "[E7] $label must exactly match canonical template: $expected"
  fi
}

# ---------------------------------------------------------------------------
# Parse an index file into a stream of one-entry-per-line records.
# Each output line looks like:
#   <indexpath>|<id>|<title>|<file>|<section>|<scope>|<type>|<status>|<last_updated>
# Missing keys appear as empty strings.
# Supports both the legacy YAML-ish entry form and summary entries:
#   - id | title | file | summary
# ---------------------------------------------------------------------------
parse_index() {
  index_path="$1"
  [ -f "$index_path" ] || return 0
  awk -v idx="$index_path" '
    function emit() {
      if (id != "" || title != "" || file != "") {
        printf "%s|%s|%s|%s|%s|%s|%s|%s|%s\n",
          idx, id, title, file, section, scope, type, status, last_updated
      }
      id=""; title=""; file=""; section=""; scope=""; type=""; status=""; last_updated=""
    }
    /^[[:space:]]*-[[:space:]]+[^|]+[[:space:]]*\|/ {
      emit()
      line = $0
      sub(/^[[:space:]]*-[[:space:]]+/, "", line)
      n = split(line, parts, /[[:space:]]*\|[[:space:]]*/)
      id = parts[1]
      title = parts[2]
      file = parts[3]
      next
    }
    /^[[:space:]]*-[[:space:]]+id:[[:space:]]*/ {
      emit()
      sub(/^[[:space:]]*-[[:space:]]+id:[[:space:]]*/, "", $0)
      id = $0
      next
    }
    /^[[:space:]]+title:[[:space:]]*/        { sub(/^[[:space:]]+title:[[:space:]]*/, ""); title = $0; next }
    /^[[:space:]]+file:[[:space:]]*/         { sub(/^[[:space:]]+file:[[:space:]]*/, ""); file = $0; next }
    /^[[:space:]]+section:[[:space:]]*/      { sub(/^[[:space:]]+section:[[:space:]]*/, ""); section = $0; next }
    /^[[:space:]]+scope:[[:space:]]*/        { sub(/^[[:space:]]+scope:[[:space:]]*/, ""); scope = $0; next }
    /^[[:space:]]+type:[[:space:]]*/         { sub(/^[[:space:]]+type:[[:space:]]*/, ""); type = $0; next }
    /^[[:space:]]+status:[[:space:]]*/       { sub(/^[[:space:]]+status:[[:space:]]*/, ""); status = $0; next }
    /^[[:space:]]+last_updated:[[:space:]]*/ { sub(/^[[:space:]]+last_updated:[[:space:]]*/, ""); last_updated = $0; next }
    END { emit() }
  ' "$index_path"
}

is_pointer_entry() {
  id="$1"
  file="$2"

  case "$file" in
    */index.md) return 0 ;;
  esac
  case "$id" in
    ml-index-ptr-*) return 0 ;;
  esac
  return 1
}

record_target_path() {
  base="$1"
  idx="$2"
  file="$3"
  idx_dir="$(dirname "$idx")"

  case "$file" in
    /*) printf "%s\n" "$file"; return ;;
  esac

  if [ -f "$base/$file" ]; then
    printf "%s\n" "$base/$file"
    return
  fi
  if [ -f "$idx_dir/$file" ]; then
    printf "%s\n" "$idx_dir/$file"
    return
  fi
  if [ -f "$base/knowledge/$file" ]; then
    printf "%s\n" "$base/knowledge/$file"
    return
  fi
  if [ -f "$base/pipeline/$file" ]; then
    printf "%s\n" "$base/pipeline/$file"
    return
  fi
  if [ -f "$PROJECT_DIR/$file" ]; then
    printf "%s\n" "$PROJECT_DIR/$file"
    return
  fi
  if [ -f "$PROJECT_DIR/global-template/$file" ]; then
    printf "%s\n" "$PROJECT_DIR/global-template/$file"
    return
  fi
  if [ -f "$HOME/.mindlayer/$file" ]; then
    printf "%s\n" "$HOME/.mindlayer/$file"
    return
  fi

  case "$file" in
    */*) printf "%s\n" "$base/$file" ;;
    *) printf "%s\n" "$idx_dir/$file" ;;
  esac
}

collect_index_tree() {
  base="$1"
  index_path="$2"
  seen="$3"

  [ -f "$index_path" ] || return 0
  case "$seen" in
    *"|$index_path|"*) return 0 ;;
  esac
  seen="$seen$index_path|"

  records=$(parse_index "$index_path")
  printf "%s\n" "$records"

  while IFS='|' read -r idx id title file section scope type status last_updated; do
    [ -n "$id$title$file" ] || continue
    if is_pointer_entry "$id" "$file"; then
      target=$(record_target_path "$base" "$idx" "$file")
      [ -f "$target" ] || continue
      collect_index_tree "$base" "$target" "$seen"
    fi
  done <<EOF
$records
EOF
}

days_since() {
  ymd="$1"
  case "$ymd" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) echo "-1"; return ;;
  esac
  then_epoch=$(date -d "$ymd" +%s 2>/dev/null || echo "")
  [ -n "$then_epoch" ] || { echo "-1"; return; }
  now_epoch=$(date +%s)
  echo $(( (now_epoch - then_epoch) / 86400 ))
}

heading_exists() {
  file_path="$1"
  section="$2"
  [ -f "$file_path" ] || return 1
  awk -v s="$section" '
    /^#{1,6}[[:space:]]+/ {
      line = $0
      sub(/^#{1,6}[[:space:]]+/, "", line)
      if (line == s) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "$file_path"
}

# ---------------------------------------------------------------------------
# Lint a single .mindlayer/ directory.
# ---------------------------------------------------------------------------
lint_dir() {
  base="$1"
  label="$2"

  if [ ! -d "$base" ]; then
    [ "$label" = "project" ] && err "[E1] missing $base"
    return
  fi
  ok "$label .mindlayer found at $base"

  index="$base/index.md"
  if [ ! -f "$index" ]; then
    [ "$label" = "global" ] && { ok "$label index.md not present (global index removed — preferences/index.md is the catalog)"; return; }
    err "[E2] missing $index"
    return
  fi
  ok "$label index.md present"

  records=$(collect_index_tree "$base" "$index" "|")
  count=$(printf "%s\n" "$records" | grep -c . || true)
  ok "$label index tree has $count entries"

  while IFS='|' read -r idx id title file section scope type status last_updated; do
    [ -n "$id$title$file" ] || continue

    pointer=1
    if is_pointer_entry "$id" "$file"; then
      pointer=0
    fi

    # E3 required keys
    missing=""
    [ -n "$id" ]           || missing="$missing id"
    [ -n "$title" ]        || missing="$missing title"
    [ -n "$file" ]         || missing="$missing file"
    if [ -n "$missing" ]; then
      err "[E3] $idx entry '${id:-<no-id>}' missing keys:$missing"
    fi

    # E5 file existence
    if [ -n "$file" ]; then
      target=$(record_target_path "$base" "$idx" "$file")
      if [ ! -f "$target" ]; then
        err "[E5] $idx entry '$id' references missing file: $file"
      elif [ "$pointer" -ne 0 ]; then
        # E6 section heading existence
        if [ -n "$section" ] && ! heading_exists "$target" "$section"; then
          err "[E6] $idx entry '$id' references missing section '$section' in $file"
        fi
      fi
    fi

    # W1 staleness
    if [ -n "$last_updated" ]; then
      d=$(days_since "$last_updated")
      if [ "$d" -ge 0 ] && [ "$d" -gt "$STALE_DAYS" ]; then
        warn "[W1] $idx entry '$id' is stale ($d days since $last_updated)"
      fi
    fi
  done <<EOF
$records
EOF

  # E4 duplicate ids across the resolved tree
  dups=$(printf "%s\n" "$records" | awk -F'|' 'NF>1 && $2!="" {print $2}' | sort | uniq -d)
  if [ -n "$dups" ]; then
    while IFS= read -r dup_id; do
      [ -n "$dup_id" ] && err "[E4] duplicate id in $label index tree: $dup_id"
    done <<EOF
$dups
EOF
  fi

  leaf_files=$(
    while IFS='|' read -r idx id title file section scope type status last_updated; do
      [ -n "$id$title$file" ] || continue
      is_pointer_entry "$id" "$file" && continue
      [ -n "$file" ] || continue
      target=$(record_target_path "$base" "$idx" "$file")
      [ -f "$target" ] && printf "%s\n" "$target"
    done <<EOF_LEAVES
$records
EOF_LEAVES
  )

  # W2/W3 file size budgets — actively warn before the hard limit.
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    lines=$(wc -l < "$p" | tr -d ' ')
    if [ "$lines" -gt "$MAX_LINES" ]; then
      warn "[W3] $p has $lines lines (>$MAX_LINES). Archive stale entries, merge duplicates, or split the file before adding more memory."
    elif [ "$lines" -ge "$WARN_LINES" ]; then
      warn "[W2] $p has $lines lines (near limit: $WARN_LINES/$MAX_LINES). Prompt for cleanup soon: archive old entries, compress summaries, or move history into a more specific file."
    fi
  done <<EOF
$(printf "%s\n" "$leaf_files" | sort -u)
EOF

  # W4 placeholder scaffolds in resolved leaf files.
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if grep -q "YYYY-MM-DD" "$p" 2>/dev/null; then
      warn "[W4] $p still contains 'YYYY-MM-DD' placeholders (likely empty scaffold)"
    fi
  done <<EOF
$(printf "%s\n" "$leaf_files" | sort -u)
EOF
}

# ---------------------------------------------------------------------------
# Repo-level checks (project only).
# ---------------------------------------------------------------------------
lint_repo() {
  base="$PROJECT_DIR/.mindlayer"

  # W5 ignorable paths committed to git
  if [ -d "$PROJECT_DIR/.git" ] && command -v git >/dev/null 2>&1; then
    tracked=$(cd "$PROJECT_DIR" && git ls-files .mindlayer 2>/dev/null || true)
    for path in ".mindlayer/local.md" ".mindlayer/private/" ".mindlayer/knowledge/sessions/" ".mindlayer/cache/" ".mindlayer/tmp/"; do
      hit=$(printf "%s\n" "$tracked" | grep -E "^${path}" || true)
      if [ -n "$hit" ]; then
        warn "[W5] git is tracking '$path' — should be gitignored"
      fi
    done
  fi

  require_file "$PROJECT_DIR/global-template/memory-system/templates/AGENTS.md" "canonical AGENTS.md template"
  require_file "$PROJECT_DIR/global-template/memory-system/templates/CLAUDE.md" "canonical CLAUDE.md template"
  require_file "$PROJECT_DIR/global-template/memory-system/templates/copilot-instructions.md" "canonical Copilot template"
  require_file "$PROJECT_DIR/global-template/memory-system/templates/GEMINI.md" "canonical Gemini template"
  require_file "$PROJECT_DIR/global-template/memory-system/templates/cursor-mindlayer.md" "canonical Cursor template"
  require_file "$PROJECT_DIR/global-template/memory-system/templates/windsurf-mindlayer.md" "canonical Windsurf template"
  require_file "$PROJECT_DIR/global-template/memory-system/hooks/claude-user-prompt-submit.sh" "Claude UserPromptSubmit hook"

  # E7 source-boundary rules
  # Behavior rules live in memory-system/ subfiles; adapters are thin pointers.
  for adapter in \
    "$PROJECT_DIR/AGENTS.md" \
    "$PROJECT_DIR/CLAUDE.md" \
    "$PROJECT_DIR/.github/copilot-instructions.md" \
    "$PROJECT_DIR/GEMINI.md" \
    "$PROJECT_DIR/.cursor/rules/mindlayer.md" \
    "$PROJECT_DIR/.windsurf/rules/mindlayer.md"; do
    require_not_contains "$adapter" "<!-- mindlayer:start -->" "$adapter"
    require_not_contains "$adapter" "<!-- mindlayer:end -->" "$adapter"
  done

  require_same_file "$PROJECT_DIR/AGENTS.md" "$PROJECT_DIR/global-template/memory-system/templates/AGENTS.md" "AGENTS.md"
  require_same_file "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/global-template/memory-system/templates/CLAUDE.md" "CLAUDE.md"
  require_same_file "$PROJECT_DIR/.github/copilot-instructions.md" "$PROJECT_DIR/global-template/memory-system/templates/copilot-instructions.md" "Copilot adapter"
  [ -f "$PROJECT_DIR/GEMINI.md" ] && require_same_file "$PROJECT_DIR/GEMINI.md" "$PROJECT_DIR/global-template/memory-system/templates/GEMINI.md" "Gemini adapter"
  [ -f "$PROJECT_DIR/.cursor/rules/mindlayer.md" ] && require_same_file "$PROJECT_DIR/.cursor/rules/mindlayer.md" "$PROJECT_DIR/global-template/memory-system/templates/cursor-mindlayer.md" "Cursor adapter"
  [ -f "$PROJECT_DIR/.windsurf/rules/mindlayer.md" ] && require_same_file "$PROJECT_DIR/.windsurf/rules/mindlayer.md" "$PROJECT_DIR/global-template/memory-system/templates/windsurf-mindlayer.md" "Windsurf adapter"

  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" 'Read `~/.mindlayer/boot.md` first' "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" 'Do not use `README.md` or `docs/` as memory input.' "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" "not memory stores" "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" "Go outside MindLayer memory only when necessary" "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" 'Always check project `.mindlayer/knowledge/project.md`' "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" "low importance or starter-like" "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" "Automatic Boot Contract" "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/init.md" "Approximate context share by source" "ml init command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/save.md" "pending destination, action, duplicate check, and confidence" "ml save command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/status.md" "pending approvals" "ml status command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/status.md" "next useful action" "ml status command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/status.md" "Per-File Health" "ml status command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/status.md" "OK | WARN | CRITICAL" "ml status command"

  # Global template — rules split across memory-system/ subfiles
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" 'Do not use `README.md` or `docs/` as memory input' "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "not durable memory stores or retrieval sources" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "Go outside MindLayer memory only when necessary" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "Approval must be literal" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "literal explicit approval" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/session.md" "## Session Continuity Behavior" "global session command"
  require_contains "$PROJECT_DIR/global-template/memory-system/commands/session.md" "pending memory-write approvals" "global session command"
  require_contains "$PROJECT_DIR/global-template/boot.md" "first project-relevant request" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" "approximate context share by source" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" 'check project `.mindlayer/knowledge/project.md`' "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" "## Adapter Guard" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" ".mindlayer/adapters.lock" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" "Never discard user-added adapter content" "global boot template"

  # README — public docs must match the current CLI runtime and adapter model.
  require_contains "$PROJECT_DIR/README.md" 'local `ml` command runner' "README"
  require_contains "$PROJECT_DIR/README.md" '`ml clean`' "README"
  require_contains "$PROJECT_DIR/README.md" '`ml diff`' "README"
  require_contains "$PROJECT_DIR/README.md" '`ml script`' "README"
  require_contains "$PROJECT_DIR/README.md" "frozen full-file templates" "README"
  require_contains "$PROJECT_DIR/README.md" ".mindlayer/adapters.lock" "README"
  require_contains "$PROJECT_DIR/README.md" ".cursor/rules/mindlayer.md" "README"
  require_contains "$PROJECT_DIR/README.md" ".windsurf/rules/mindlayer.md" "README"

  # Installer — check canonical adapter template handling and embedded fallback vars
  require_contains "$PROJECT_DIR/install.sh" "memory-system/templates/AGENTS.md" "installer adapter templates"
  require_contains "$PROJECT_DIR/install.sh" "memory-system/templates/CLAUDE.md" "installer adapter templates"
  require_contains "$PROJECT_DIR/install.sh" "claude-user-prompt-submit.sh" "installer Claude hook"
  require_contains "$PROJECT_DIR/global-template/memory-system/hooks/claude-user-prompt-submit.sh" "UserPromptSubmit" "Claude UserPromptSubmit hook"
  require_contains "$PROJECT_DIR/global-template/memory-system/hooks/claude-user-prompt-submit.sh" "Token Burned" "Claude UserPromptSubmit hook"
  require_contains "$PROJECT_DIR/install.sh" ".mindlayer/adapters.lock" "installer adapter lock"
  require_contains "$PROJECT_DIR/install.sh" "sha256_file" "installer adapter lock"
  require_contains "$PROJECT_DIR/install.sh" "not durable memory stores or retrieval sources" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Write Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Read Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Routing Rules" "installer router fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Token Rules" "installer schema fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Approval Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Lifecycle Statuses" "installer schema fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Index-First Retrieval" "installer commands fallback"
  require_contains "$PROJECT_DIR/install.sh" "literal explicit approval" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "Approval must be literal" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "memory-system/commands/index.md" "installer commands index fallback"
}

# ---------------------------------------------------------------------------
# Cross-index duplicate id check
# ---------------------------------------------------------------------------
cross_check_ids() {
  all_ids=""
  proj_idx="$PROJECT_DIR/.mindlayer/index.md"
  glob_idx="$HOME/.mindlayer/index.md"
  [ -f "$proj_idx" ] && all_ids="$all_ids$(collect_index_tree "$PROJECT_DIR/.mindlayer" "$proj_idx" "|" | awk -F'|' '{print $2}')
"
  if [ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$glob_idx" ]; then
    all_ids="$all_ids$(collect_index_tree "$HOME/.mindlayer" "$glob_idx" "|" | awk -F'|' '{print $2}')
"
    dups=$(printf "%s" "$all_ids" | grep -v '^$' | sort | uniq -d)
    if [ -n "$dups" ]; then
      while IFS= read -r dup_id; do
        [ -n "$dup_id" ] && err "[E4] id appears in both global and project indexes: $dup_id"
      done <<EOF
$dups
EOF
    fi
  fi
}

echo "MindLayer lint — $PROJECT_DIR"
echo "----------------------------------------"

lint_dir "$PROJECT_DIR/.mindlayer" "project"

if [ "$INCLUDE_GLOBAL" -eq 1 ]; then
  echo
  lint_dir "$HOME/.mindlayer" "global"
fi

echo
lint_repo
cross_check_ids

echo
echo "----------------------------------------"
echo "Errors: $ERRORS  Warnings: $WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$WARNINGS" -gt 0 ]; then
  exit 1
fi
exit 0
