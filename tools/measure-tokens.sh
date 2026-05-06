#!/usr/bin/env bash
# MindLayer token cost measurement
#
# Prints a comparison table of approximate token cost across loading strategies,
# so the README can show real numbers instead of vibes.
#
# Token approximation: chars / 4. This is the standard rough heuristic for
# English markdown. Reported as ~tokens; not a substitute for tiktoken.
#
# Strategies measured:
#   L0           L0 bootstrap files only (memory-system.md + indexes).
#   L0+identity  L0 plus project/.mindlayer/project.md and progress.md
#                (what MindLayer boot typically loads in practice).
#   FULL_MEM     Everything committed in project/.mindlayer/ except local.md,
#                private/, sessions/, cache/, tmp/. Worst case for memory.
#   ADAPTERS     AGENTS.md + CLAUDE.md + .github/copilot-instructions.md.
#   BASELINE     ADAPTERS + FULL_MEM. Approximates "load everything" behavior.

set -u

PROJECT_DIR="$(pwd)"
INCLUDE_GLOBAL=1

usage() {
  cat <<'EOF'
Usage: bash tools/measure-tokens.sh [options]

Options:
  --project <path>    Project root. Default: current directory.
  --no-global         Skip ~/.mindlayer/ files in L0.
  -h, --help          Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project) PROJECT_DIR="$2"; shift 2 ;;
    --no-global) INCLUDE_GLOBAL=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

PMEM="$PROJECT_DIR/.mindlayer"
GMEM="$HOME/.mindlayer"

count_chars() {
  total=0
  for f in "$@"; do
    [ -f "$f" ] || continue
    c=$(wc -c < "$f" | tr -d ' ')
    total=$((total + c))
  done
  echo "$total"
}

approx_tokens() {
  chars="$1"
  echo $(( (chars + 3) / 4 ))
}

print_row() {
  label="$1"; chars="$2"; files="$3"
  tokens=$(approx_tokens "$chars")
  printf "  %-14s  %8d chars  ~%6d tokens  (%s)\n" "$label" "$chars" "$tokens" "$files"
}

# ---- L0 bootstrap ---------------------------------------------------------
L0_FILES=""
[ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$GMEM/boot.md" ]                        && L0_FILES="$L0_FILES $GMEM/boot.md"
[ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$GMEM/router.md" ]                      && L0_FILES="$L0_FILES $GMEM/router.md"
[ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$GMEM/memory-system/per-turn.md" ]      && L0_FILES="$L0_FILES $GMEM/memory-system/per-turn.md"
[ "$INCLUDE_GLOBAL" -eq 1 ] && [ -f "$GMEM/index.md" ]                       && L0_FILES="$L0_FILES $GMEM/index.md"
[ -f "$PMEM/index.md" ]                                                       && L0_FILES="$L0_FILES $PMEM/index.md"
L0_CHARS=$(count_chars $L0_FILES)
L0_NAMES=$(echo "$L0_FILES" | sed "s|$HOME|~|g; s|$PROJECT_DIR/||g" | xargs -n1 echo 2>/dev/null | tr '\n' ' ')

# ---- L0 + identity --------------------------------------------------------
L0I_FILES="$L0_FILES"
[ -f "$PMEM/project.md" ]  && L0I_FILES="$L0I_FILES $PMEM/project.md"
[ -f "$PMEM/progress.md" ] && L0I_FILES="$L0I_FILES $PMEM/progress.md"
L0I_CHARS=$(count_chars $L0I_FILES)

# ---- FULL_MEM (everything committed in .mindlayer/) -----------------------
FULL_MEM_FILES=""
for f in project.md progress.md decisions.md context.md backlog.md risks.md index.md; do
  [ -f "$PMEM/$f" ] && FULL_MEM_FILES="$FULL_MEM_FILES $PMEM/$f"
done
FULL_MEM_CHARS=$(count_chars $FULL_MEM_FILES)

# ---- ADAPTERS -------------------------------------------------------------
ADAPTER_FILES=""
[ -f "$PROJECT_DIR/AGENTS.md" ]                          && ADAPTER_FILES="$ADAPTER_FILES $PROJECT_DIR/AGENTS.md"
[ -f "$PROJECT_DIR/CLAUDE.md" ]                          && ADAPTER_FILES="$ADAPTER_FILES $PROJECT_DIR/CLAUDE.md"
[ -f "$PROJECT_DIR/.github/copilot-instructions.md" ]    && ADAPTER_FILES="$ADAPTER_FILES $PROJECT_DIR/.github/copilot-instructions.md"
ADAPTER_CHARS=$(count_chars $ADAPTER_FILES)

# ---- BASELINE (everything) ------------------------------------------------
BASELINE_CHARS=$((ADAPTER_CHARS + FULL_MEM_CHARS))

# ---- Report ---------------------------------------------------------------
echo "MindLayer token cost — $PROJECT_DIR"
echo "Approximation: ~tokens = chars / 4"
echo "----------------------------------------"
print_row "L0"          "$L0_CHARS"         "$(echo $L0_FILES | wc -w) files"
print_row "L0+identity" "$L0I_CHARS"        "$(echo $L0I_FILES | wc -w) files"
print_row "FULL_MEM"    "$FULL_MEM_CHARS"   "$(echo $FULL_MEM_FILES | wc -w) files"
print_row "ADAPTERS"    "$ADAPTER_CHARS"    "$(echo $ADAPTER_FILES | wc -w) files"
print_row "BASELINE"    "$BASELINE_CHARS"   "ADAPTERS + FULL_MEM"
echo "----------------------------------------"

if [ "$BASELINE_CHARS" -gt 0 ] && [ "$L0_CHARS" -gt 0 ]; then
  ratio=$(awk -v b="$BASELINE_CHARS" -v l="$L0_CHARS" 'BEGIN { printf "%.1f", b / l }')
  saved=$(( BASELINE_CHARS - L0_CHARS ))
  saved_tokens=$(approx_tokens "$saved")
  echo "L0 vs BASELINE: ${ratio}x smaller (~$saved_tokens tokens saved per session start)"
fi

# Per-file breakdown for L0 transparency
echo
echo "L0 breakdown:"
for f in $L0_FILES; do
  c=$(wc -c < "$f" | tr -d ' ')
  t=$(approx_tokens "$c")
  pretty=$(echo "$f" | sed "s|$HOME|~|g; s|$PROJECT_DIR/||g")
  printf "  %-50s  %6d chars  ~%5d tokens\n" "$pretty" "$c" "$t"
done
