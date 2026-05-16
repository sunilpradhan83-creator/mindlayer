#!/usr/bin/env bash
# Lint tests for recursive index pointer trees.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-index-tree-test.$$"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"

cleanup() {
  if [ "$KEEP_TEST_DIR" = "1" ]; then
    printf "Kept sandbox: %s\n" "$SANDBOX"
  else
    rm -rf "$SANDBOX"
  fi
}

trap cleanup EXIT

mkdir -p "$SANDBOX"

copy_path() {
  case_dir="$1"
  src="$2"
  dest="$case_dir/$src"
  if [ -d "$ROOT_DIR/$src" ]; then
    mkdir -p "$dest"
    cp -R "$ROOT_DIR/$src/." "$dest/"
  elif [ -f "$ROOT_DIR/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$ROOT_DIR/$src" "$dest"
  fi
}

make_project() {
  case_name="$1"
  case_dir="$SANDBOX/$case_name"

  mkdir -p "$case_dir"
  copy_path "$case_dir" ".github"
  copy_path "$case_dir" "global-template"
  copy_path "$case_dir" "tools"
  copy_path "$case_dir" "install.sh"
  copy_path "$case_dir" "AGENTS.md"
  copy_path "$case_dir" "CLAUDE.md"

  rm -rf "$case_dir/.mindlayer"
  mkdir -p "$case_dir/.mindlayer/knowledge"

  cat > "$case_dir/.mindlayer/index.md" <<'EOF'
# Project Memory Index

- ml-index-ptr-knowledge | Knowledge Index | knowledge/index.md | Index for knowledge/ subfolder
EOF

  cat > "$case_dir/.mindlayer/knowledge/index.md" <<'EOF'
# Knowledge Index

- ml-project-test | Project Identity | project.md | Test project memory.
EOF

  cat > "$case_dir/.mindlayer/knowledge/project.md" <<'EOF'
# Project Identity

Test project memory.
EOF

  printf "%s\n" "$case_dir"
}

assert_lint_passes() {
  case_dir="$1"
  label="$2"
  log="$case_dir/lint.log"

  if ! bash "$case_dir/tools/lint.sh" --project "$case_dir" > "$log" 2>&1; then
    printf "FAIL  %s\n" "$label"
    cat "$log"
    exit 1
  fi
  if grep -Fq "ERROR" "$log"; then
    printf "FAIL  %s emitted an unexpected error\n" "$label"
    cat "$log"
    exit 1
  fi
}

assert_lint_fails_with() {
  case_dir="$1"
  expected="$2"
  label="$3"
  log="$case_dir/lint.log"

  if bash "$case_dir/tools/lint.sh" --project "$case_dir" > "$log" 2>&1; then
    printf "FAIL  %s\n" "$label"
    cat "$log"
    exit 1
  fi
  if ! grep -Fq "$expected" "$log"; then
    printf "FAIL  %s missing expected output: %s\n" "$label" "$expected"
    cat "$log"
    exit 1
  fi
}

valid_project=$(make_project "valid")
assert_lint_passes "$valid_project" "valid pointer tree should pass lint"

missing_pointer=$(make_project "missing-pointer")
sed -i 's|knowledge/index.md|knowledge/missing/index.md|' "$missing_pointer/.mindlayer/index.md"
assert_lint_fails_with "$missing_pointer" "[E5]" "missing pointer target should fail E5"

missing_section=$(make_project "missing-section")
cat > "$missing_section/.mindlayer/knowledge/index.md" <<'EOF'
# Knowledge Index

- id: ml-project-test
  title: Project Identity
  file: project.md
  section: Project Identity
  scope: project
  type: knowledge
  status: active
  last_updated: 2026-05-16
EOF
cat > "$missing_section/.mindlayer/knowledge/project.md" <<'EOF'
# Different Heading

Test project memory.
EOF
assert_lint_fails_with "$missing_section" "[E6]" "missing subfolder leaf section should fail E6"

duplicate_id=$(make_project "duplicate-id")
sed -i 's/ml-project-test/ml-index-ptr-knowledge/' "$duplicate_id/.mindlayer/knowledge/index.md"
assert_lint_fails_with "$duplicate_id" "[E4]" "duplicate ids across root and subfolder should fail E4"

index_full=$(make_project "index-full")
cat > "$index_full/.mindlayer/index-full.md" <<'EOF'
# Deprecated Index Full

- ml-bad-index-full | Missing File | missing.md | This deprecated file must be ignored.
EOF
assert_lint_passes "$index_full" "deprecated index-full.md should be ignored"

printf "PASS  recursive index-tree lint contracts\n"
