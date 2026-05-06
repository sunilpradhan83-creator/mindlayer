#!/usr/bin/env bash
# MindLayer local deploy-readiness test.
#
# Runs the installer in sandboxed temp homes/projects and reports whether the
# current working tree is ready to deploy from an install-safety perspective.

set -u

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-install-test.$$"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf "PASS  %s\n" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf "FAIL  %s\n" "$1"
}

scenario() {
  CURRENT_SCENARIO="$1"
  printf "\n## %s\n" "$CURRENT_SCENARIO"
}

check() {
  if "$@"; then
    pass "$CURRENT_SCENARIO: $*"
  else
    fail "$CURRENT_SCENARIO: $*"
  fi
}

assert_file_exists() {
  [ -f "$1" ]
}

assert_dir_exists() {
  [ -d "$1" ]
}

assert_not_exists() {
  [ ! -e "$1" ]
}

assert_contains() {
  file="$1"
  pattern="$2"
  [ -f "$file" ] && grep -Fq "$pattern" "$file"
}

assert_count() {
  expected="$1"
  file="$2"
  pattern="$3"
  [ -f "$file" ] || return 1
  actual=$(grep -F "$pattern" "$file" | wc -l | tr -d ' ')
  [ "$actual" = "$expected" ]
}

assert_git_has_commit() {
  dir="$1"
  [ -d "$dir/.git" ] || return 1
  git -C "$dir" log --oneline 2>/dev/null | grep -q .
}

assert_not_contains() {
  file="$1"
  pattern="$2"
  [ -f "$file" ] || return 0
  ! grep -Fq "$pattern" "$file"
}

assert_index_sections_exist() {
  base="$1"
  index="$base/index.md"
  [ -f "$index" ] || return 1

  awk -v base="$base" '
    function heading_exists(path, section, line) {
      found = 0
      while ((getline line < path) > 0) {
        if (line ~ /^#{1,6}[[:space:]]+/) {
          sub(/^#{1,6}[[:space:]]+/, "", line)
          if (line == section) found = 1
        }
      }
      close(path)
      return found
    }
    function check_entry() {
      if (file == "" && section == "") return
      path = base "/" file
      if (file == "" || section == "" || system("[ -f \"" path "\" ]") != 0 || !heading_exists(path, section)) {
        bad = 1
      }
      file = ""
      section = ""
    }
    /^[[:space:]]*-[[:space:]]+id:[[:space:]]*/ { check_entry(); next }
    /^[[:space:]]+file:[[:space:]]*/ { sub(/^[[:space:]]+file:[[:space:]]*/, ""); file = $0; next }
    /^[[:space:]]+section:[[:space:]]*/ { sub(/^[[:space:]]+section:[[:space:]]*/, ""); section = $0; next }
    END { check_entry(); exit bad ? 1 : 0 }
  ' "$index"
}

run_install() {
  home_dir="$1"
  project_dir="$2"
  log_file="$3"
  HOME="$home_dir" bash "$ROOT_DIR/install.sh" --project "$project_dir" --no-onboard > "$log_file" 2>&1
}

cleanup() {
  if [ "$KEEP_TEST_DIR" = "1" ]; then
    printf "\nKept sandbox: %s\n" "$SANDBOX"
  else
    rm -rf "$SANDBOX"
  fi
}

trap cleanup EXIT

mkdir -p "$SANDBOX"

printf "MindLayer Local Install Readiness\n"
printf "Repo: %s\n" "$ROOT_DIR"
printf "Sandbox: %s\n" "$SANDBOX"

scenario "fresh project install"
fresh_home="$SANDBOX/fresh-home"
fresh_project="$SANDBOX/fresh-project"
fresh_log="$SANDBOX/fresh-install.log"
mkdir -p "$fresh_home" "$fresh_project"

if run_install "$fresh_home" "$fresh_project" "$fresh_log"; then
  pass "$CURRENT_SCENARIO: installer exits successfully"
else
  fail "$CURRENT_SCENARIO: installer exits successfully"
fi

check assert_file_exists "$fresh_home/.mindlayer/boot.md"
check assert_file_exists "$fresh_home/.mindlayer/router.md"
check assert_dir_exists "$fresh_home/.mindlayer/memory-system"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/per-turn.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/read-write.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/session.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/schema.md"
check assert_file_exists "$fresh_home/.mindlayer/index.md"
check assert_dir_exists "$fresh_home/.mindlayer/preferences"
check assert_file_exists "$fresh_home/.mindlayer/preferences/index.md"
check assert_file_exists "$fresh_home/.mindlayer/preferences/personal.md"
check assert_dir_exists "$fresh_home/.mindlayer/preferences/.git"
check assert_not_exists "$fresh_home/.mindlayer/memory.md"
check assert_not_exists "$fresh_home/.mindlayer/memory-system.md"
check assert_not_exists "$fresh_home/.mindlayer/preferences.md"
check assert_not_exists "$fresh_home/.mindlayer/principles.md"
check assert_not_exists "$fresh_home/.mindlayer/anti-patterns.md"
check assert_not_exists "$fresh_home/.mindlayer/prompts.md"
check assert_not_exists "$fresh_home/.mindlayer/playbook.md"
check assert_git_has_commit "$fresh_home/.mindlayer/preferences"
check assert_contains "$fresh_home/.mindlayer/boot.md" "first project-relevant request"
check assert_contains "$fresh_home/.mindlayer/memory-system/read-write.md" 'Do not use `README.md` or `docs/` as memory input'
check assert_contains "$fresh_home/.mindlayer/memory-system/read-write.md" 'always check project `.mindlayer/project.md`'
check assert_contains "$fresh_home/.mindlayer/memory-system/read-write.md" "explicit approval"
check assert_index_sections_exist "$fresh_home/.mindlayer"

for file in project.md progress.md decisions.md context.md backlog.md roadmap.md risks.md index.md local.md; do
  check assert_file_exists "$fresh_project/.mindlayer/$file"
done

check assert_file_exists "$fresh_project/AGENTS.md"
check assert_file_exists "$fresh_project/CLAUDE.md"
check assert_file_exists "$fresh_project/.github/copilot-instructions.md"
check assert_contains "$fresh_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_contains "$fresh_project/CLAUDE.md" "<!-- mindlayer:start -->"
check assert_contains "$fresh_project/.github/copilot-instructions.md" "<!-- mindlayer:start -->"
check assert_contains "$fresh_project/AGENTS.md" 'Read `~/.mindlayer/boot.md` first'
check assert_contains "$fresh_project/AGENTS.md" "first project-relevant request"
check assert_contains "$fresh_project/AGENTS.md" "Use this exact boot receipt format"
check assert_contains "$fresh_project/AGENTS.md" "Context share:"
check assert_contains "$fresh_project/AGENTS.md" "Token strategy:"
check assert_contains "$fresh_project/AGENTS.md" "Proactive Behavior"
check assert_contains "$fresh_project/CLAUDE.md" '`README.md` and `docs/` are human documentation'
check assert_contains "$fresh_project/CLAUDE.md" "Do not duplicate memory into"
check assert_contains "$fresh_project/CLAUDE.md" "automatic MindLayer boot"
check assert_contains "$fresh_project/.github/copilot-instructions.md" 'Do not use `README.md` or `docs/` as memory input.'
check assert_contains "$fresh_project/.github/copilot-instructions.md" "Do not retrieve durable context from this adapter."
check assert_contains "$fresh_project/.github/copilot-instructions.md" 'Read `~/.mindlayer/boot.md` first'
check assert_contains "$fresh_project/.github/copilot-instructions.md" "first project-relevant request"
check assert_contains "$fresh_project/.gitignore" ".mindlayer/local.md"
check assert_contains "$fresh_project/.gitignore" ".mindlayer/private/"
check assert_index_sections_exist "$fresh_project/.mindlayer"

scenario "existing project install and idempotence"
existing_home="$SANDBOX/existing-home"
existing_project="$SANDBOX/existing-project"
existing_log_1="$SANDBOX/existing-install-1.log"
existing_log_2="$SANDBOX/existing-install-2.log"
mkdir -p "$existing_home/.mindlayer" "$existing_project/.github" "$existing_project/.mindlayer"

cat > "$existing_home/.mindlayer/index.md" <<'EOF'
# Global Memory Index

Use this file as the compact search map for ~/.mindlayer/.

## Entries

- id: ml-global-20260502-001
  title: User global preferences
  file: preferences.md
  section: User Preferences
  scope: global
  type: preference
  tags: [mindlayer, preferences]
  summary: User-owned cross-project preferences; load only when the section contains substantive user-written preferences.
  importance: medium
  status: active
  last_updated: 2026-05-02
EOF

cat > "$existing_home/.mindlayer/preferences.md" <<'EOF'
# Global Preferences

## User Preferences

Custom global preference sentinel.
EOF

cat > "$existing_project/AGENTS.md" <<'EOF'
# Existing Agent Notes

Do not remove this project-specific instruction.
EOF

cat > "$existing_project/CLAUDE.md" <<'EOF'
# Existing Claude Notes

Keep this Claude sentinel.
EOF

cat > "$existing_project/.github/copilot-instructions.md" <<'EOF'
# Existing Copilot Notes

Keep this Copilot sentinel.
EOF

cat > "$existing_project/.gitignore" <<'EOF'
node_modules/
EOF

cat > "$existing_project/.mindlayer/project.md" <<'EOF'
# Project Memory

## Custom Project Identity

Custom project memory sentinel.
EOF

if run_install "$existing_home" "$existing_project" "$existing_log_1"; then
  pass "$CURRENT_SCENARIO: first installer run exits successfully"
else
  fail "$CURRENT_SCENARIO: first installer run exits successfully"
fi

if run_install "$existing_home" "$existing_project" "$existing_log_2"; then
  pass "$CURRENT_SCENARIO: second installer run exits successfully"
else
  fail "$CURRENT_SCENARIO: second installer run exits successfully"
fi

check assert_contains "$existing_home/.mindlayer/preferences.md" "Custom global preference sentinel."
check assert_file_exists "$existing_home/.mindlayer/boot.md"
check assert_contains "$existing_home/.mindlayer/boot.md" "first project-relevant request"
check assert_contains "$existing_project/.mindlayer/project.md" "Custom project memory sentinel."
check assert_contains "$existing_project/AGENTS.md" "Do not remove this project-specific instruction."
check assert_contains "$existing_project/CLAUDE.md" "Keep this Claude sentinel."
check assert_contains "$existing_project/.github/copilot-instructions.md" "Keep this Copilot sentinel."
check assert_contains "$existing_project/.gitignore" "node_modules/"
check assert_count 1 "$existing_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_count 1 "$existing_project/AGENTS.md" "<!-- mindlayer:end -->"
check assert_count 1 "$existing_project/CLAUDE.md" "<!-- mindlayer:start -->"
check assert_count 1 "$existing_project/.github/copilot-instructions.md" "<!-- mindlayer:start -->"
check assert_count 1 "$existing_project/.gitignore" ".mindlayer/local.md"
check assert_count 1 "$existing_project/.gitignore" ".mindlayer/private/"
check assert_file_exists "$existing_home/.mindlayer/index.md"
check assert_file_exists "$existing_project/.mindlayer/index.md"

scenario "adapter post-block content preserved"
postblock_home="$SANDBOX/postblock-home"
postblock_project="$SANDBOX/postblock-project"
postblock_log="$SANDBOX/postblock-install.log"
mkdir -p "$postblock_home" "$postblock_project/.github"

cat > "$postblock_project/AGENTS.md" <<'EOF'
# Agent Notes

<!-- mindlayer:start -->
Old MindLayer block content.
<!-- mindlayer:end -->

This content after the block must be preserved.
EOF

if run_install "$postblock_home" "$postblock_project" "$postblock_log"; then
  pass "$CURRENT_SCENARIO: installer exits successfully"
else
  fail "$CURRENT_SCENARIO: installer exits successfully"
fi

check assert_contains "$postblock_project/AGENTS.md" "This content after the block must be preserved."
check assert_count 1 "$postblock_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_count 1 "$postblock_project/AGENTS.md" "<!-- mindlayer:end -->"

scenario "managed template overwrite on reinstall"
managed_home="$SANDBOX/managed-home"
managed_project="$SANDBOX/managed-project"
managed_log_1="$SANDBOX/managed-install-1.log"
managed_log_2="$SANDBOX/managed-install-2.log"
mkdir -p "$managed_home/.mindlayer/memory-system" "$managed_home/.mindlayer/preferences" "$managed_project"

cat > "$managed_home/.mindlayer/boot.md" <<'EOF'
# Old Boot

old boot sentinel content
EOF

cat > "$managed_home/.mindlayer/preferences/personal.md" <<'EOF'
# Preferences

User custom preferences sentinel.
EOF

run_install "$managed_home" "$managed_project" "$managed_log_1" || true
run_install "$managed_home" "$managed_project" "$managed_log_2" || true

check assert_not_contains "$managed_home/.mindlayer/boot.md" "old boot sentinel content"
check assert_contains "$managed_home/.mindlayer/boot.md" "first project-relevant request"
check assert_contains "$managed_home/.mindlayer/preferences/personal.md" "User custom preferences sentinel."

scenario "boot contract"
check assert_contains "$fresh_home/.mindlayer/boot.md" "first project-relevant request"
check assert_file_exists "$fresh_home/.mindlayer/preferences/personal.md"
check assert_not_exists "$fresh_home/.mindlayer/memory.md"
check assert_contains "$fresh_project/AGENTS.md" '`/m-init` is a legacy/manual refresh alias'
check assert_contains "$fresh_project/AGENTS.md" "Context cost:"

printf "\nMindLayer Local Install Readiness Summary\n"
printf "Passed checks: %s\n" "$PASS_COUNT"
printf "Failed checks: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: READY TO DEPLOY\n"
  exit 0
fi

printf "Verdict: NOT READY TO DEPLOY\n"
printf "Inspect sandbox logs with KEEP_TEST_DIR=1 for details.\n"
exit 1
