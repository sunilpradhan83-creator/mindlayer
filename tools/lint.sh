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
#   E3  every index entry has required keys (id, title, file, section, scope, type, status, last_updated)
#   E4  no duplicate ids across project (and global, if --include-global)
#   E5  every index entry's `file` exists in .mindlayer/
#   E6  every index entry's `section` appears as a heading in its `file`
#   E7  source-boundary rules are present in adapters, boot prompt, and templates
#   W1  entries with last_updated older than --stale-days (default 180)
#   W2  any committed memory file is nearing --max-lines (default 240 of 300)
#   W3  any committed memory file exceeds --max-lines (default 300)
#   W4  files still containing "YYYY-MM-DD" placeholders (empty scaffold)
#   W5  ignorable paths present in git index (local.md, private/, sessions/, cache/, tmp/)
#   W6  adapter files (AGENTS.md / CLAUDE.md) missing the mindlayer marker block

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

# ---------------------------------------------------------------------------
# Parse an index file into a stream of one-entry-per-line records.
# Each output line looks like:
#   <indexpath>|<id>|<title>|<file>|<section>|<scope>|<type>|<status>|<last_updated>
# Missing keys appear as empty strings.
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

list_memory_files() {
  base="$1"
  find "$base" -maxdepth 1 -type f -name '*.md' ! -name 'local.md' | sort
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
    err "[E2] missing $index"
    return
  fi
  ok "$label index.md present"

  records=$(parse_index "$index")
  count=$(printf "%s\n" "$records" | grep -c . || true)
  ok "$label index has $count entries"

  while IFS='|' read -r idx id title file section scope type status last_updated; do
    [ -n "$id$title$file" ] || continue

    # E3 required keys
    missing=""
    [ -n "$id" ]           || missing="$missing id"
    [ -n "$title" ]        || missing="$missing title"
    [ -n "$file" ]         || missing="$missing file"
    [ -n "$section" ]      || missing="$missing section"
    [ -n "$scope" ]        || missing="$missing scope"
    [ -n "$type" ]         || missing="$missing type"
    [ -n "$status" ]       || missing="$missing status"
    [ -n "$last_updated" ] || missing="$missing last_updated"
    if [ -n "$missing" ]; then
      err "[E3] $idx entry '${id:-<no-id>}' missing keys:$missing"
    fi

    # E5 file existence
    if [ -n "$file" ]; then
      target="$base/$file"
      if [ ! -f "$target" ]; then
        err "[E5] $idx entry '$id' references missing file: $file"
      else
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

  # E4 duplicate ids within this index
  dups=$(printf "%s\n" "$records" | awk -F'|' 'NF>1 && $2!="" {print $2}' | sort | uniq -d)
  if [ -n "$dups" ]; then
    while IFS= read -r dup_id; do
      [ -n "$dup_id" ] && err "[E4] duplicate id in $index: $dup_id"
    done <<EOF
$dups
EOF
  fi

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
$(list_memory_files "$base")
EOF

  # W4 placeholder scaffolds in committed files
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    if grep -q "YYYY-MM-DD" "$p" 2>/dev/null; then
      warn "[W4] $p still contains 'YYYY-MM-DD' placeholders (likely empty scaffold)"
    fi
  done <<EOF
$(list_memory_files "$base")
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
    for path in ".mindlayer/local.md" ".mindlayer/private/" ".mindlayer/sessions/" ".mindlayer/cache/" ".mindlayer/tmp/"; do
      hit=$(printf "%s\n" "$tracked" | grep -E "^${path}" || true)
      if [ -n "$hit" ]; then
        warn "[W5] git is tracking '$path' — should be gitignored"
      fi
    done
  fi

  # W6 adapter marker block presence
  for adapter in "$PROJECT_DIR/AGENTS.md" "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/.github/copilot-instructions.md"; do
    [ -f "$adapter" ] || continue
    if ! grep -q "<!-- mindlayer:start -->" "$adapter"; then
      warn "[W6] $adapter is missing the <!-- mindlayer:start --> marker block"
    fi
  done

  # E7 source-boundary rules
  # Behavior rules live in memory-system/ subfiles; adapters are thin pointers.
  require_contains "$PROJECT_DIR/AGENTS.md" 'Read `~/.mindlayer/boot.md` first' "AGENTS.md"
  require_contains "$PROJECT_DIR/AGENTS.md" "first project-relevant request" "AGENTS.md"
  require_contains "$PROJECT_DIR/AGENTS.md" "Use this exact boot receipt format" "AGENTS.md"
  require_contains "$PROJECT_DIR/AGENTS.md" "Context share:" "AGENTS.md"
  require_contains "$PROJECT_DIR/AGENTS.md" "Token strategy:" "AGENTS.md"
  require_contains "$PROJECT_DIR/AGENTS.md" "Proactive Behavior" "AGENTS.md"

  require_contains "$PROJECT_DIR/CLAUDE.md" '`README.md` and `docs/` are human documentation' "CLAUDE.md"
  require_contains "$PROJECT_DIR/CLAUDE.md" "Do not duplicate memory into" "CLAUDE.md"
  require_contains "$PROJECT_DIR/CLAUDE.md" "retrieve durable context from this adapter" "CLAUDE.md"
  require_contains "$PROJECT_DIR/CLAUDE.md" "automatic MindLayer boot" "CLAUDE.md"

  require_contains "$PROJECT_DIR/.github/copilot-instructions.md" 'Do not use `README.md` or `docs/` as memory input.' "Copilot adapter"
  require_contains "$PROJECT_DIR/.github/copilot-instructions.md" "Do not retrieve durable context from this adapter." "Copilot adapter"
  require_contains "$PROJECT_DIR/.github/copilot-instructions.md" 'Read `~/.mindlayer/boot.md` first' "Copilot adapter"
  require_contains "$PROJECT_DIR/.github/copilot-instructions.md" "first project-relevant request" "Copilot adapter"

  require_contains "$PROJECT_DIR/prompts/m-init.md" 'Read `~/.mindlayer/boot.md` first' "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" 'Do not use `README.md` or `docs/` as memory input.' "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" "not memory stores" "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" "Go outside MindLayer memory only when necessary" "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" 'Always check project `.mindlayer/project.md`' "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" "low importance or starter-like" "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" "Automatic Boot Contract" "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-init.md" "Approximate context share by source" "/m-init prompt"
  require_contains "$PROJECT_DIR/prompts/m-save.md" "pending destination, action, duplicate check, and confidence" "/m-save prompt"
  require_contains "$PROJECT_DIR/prompts/m-status.md" "pending approvals" "/m-status prompt"
  require_contains "$PROJECT_DIR/prompts/m-status.md" "next useful action" "/m-status prompt"

  # Global template — rules split across memory-system/ subfiles
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" 'Do not use `README.md` or `docs/` as memory input' "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "not durable memory stores or retrieval sources" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "Go outside MindLayer memory only when necessary" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "Approval must be literal" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/read-write.md" "literal explicit approval" "global read-write template"
  require_contains "$PROJECT_DIR/global-template/memory-system/session.md" "## Session Continuity Behavior" "global session template"
  require_contains "$PROJECT_DIR/global-template/memory-system/session.md" "pending memory-write approvals" "global session template"
  require_contains "$PROJECT_DIR/global-template/boot.md" "first project-relevant request" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" "approximate context share by source" "global boot template"
  require_contains "$PROJECT_DIR/global-template/boot.md" 'check project `.mindlayer/project.md`' "global boot template"

  # Installer — check adapter block and embedded fallback vars
  require_contains "$PROJECT_DIR/install.sh" 'Read `~/.mindlayer/boot.md` first' "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "first project-relevant request" "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "Use this exact boot receipt format" "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "Context share:" "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "Token strategy:" "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "Proactive Behavior" "installer adapter block"
  require_contains "$PROJECT_DIR/install.sh" "not durable memory stores or retrieval sources" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Session Continuity Behavior" "installer session fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Write Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Read Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Routing Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Token Rules" "installer schema fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Backup Rules" "installer session fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Approval Rules" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Lifecycle Statuses" "installer schema fallback"
  require_contains "$PROJECT_DIR/install.sh" "## Index-First Retrieval" "installer commands fallback"
  require_contains "$PROJECT_DIR/install.sh" "literal explicit approval" "installer read-write fallback"
  require_contains "$PROJECT_DIR/install.sh" "Approval must be literal" "installer read-write fallback"
}

# ---------------------------------------------------------------------------
# Cross-index duplicate id check
# ---------------------------------------------------------------------------
cross_check_ids() {
  all_ids=""
  proj_idx="$PROJECT_DIR/.mindlayer/index.md"
  glob_idx="$HOME/.mindlayer/index.md"
  [ -f "$proj_idx" ] && all_ids="$all_ids$(parse_index "$proj_idx" | awk -F'|' '{print $2}')
"
  if [ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$glob_idx" ]; then
    all_ids="$all_ids$(parse_index "$glob_idx" | awk -F'|' '{print $2}')
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
