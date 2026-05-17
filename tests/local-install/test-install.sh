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

assert_files_equal() {
  expected="$1"
  actual="$2"
  [ -f "$expected" ] && [ -f "$actual" ] && cmp -s "$expected" "$actual"
}

assert_lock_hash_for() {
  lock_file="$1"
  adapter_name="$2"
  [ -f "$lock_file" ] || return 1
  awk -F= -v name="$adapter_name" '
    $1 == name && $2 ~ /^[0-9a-f]{64}$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$lock_file"
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
  path_prefix="${MINDLAYER_TEST_PATH_PREFIX:-}"
  if [ -n "$path_prefix" ]; then
    PATH="$path_prefix:/usr/bin:/bin" HOME="$home_dir" bash "$ROOT_DIR/install.sh" --project "$project_dir" --no-onboard > "$log_file" 2>&1
  else
    PATH="/usr/bin:/bin" HOME="$home_dir" bash "$ROOT_DIR/install.sh" --project "$project_dir" --no-onboard > "$log_file" 2>&1
  fi
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
fresh_bin="$SANDBOX/fresh-bin"
mkdir -p "$fresh_home" "$fresh_project"
mkdir -p "$fresh_home/.claude" "$fresh_home/.gemini" "$fresh_home/.windsurf" "$fresh_project/.github" "$fresh_project/.cursor" "$fresh_bin"
printf "#!/bin/sh\nexit 0\n" > "$fresh_bin/gh-copilot"
chmod +x "$fresh_bin/gh-copilot"

if MINDLAYER_TEST_PATH_PREFIX="$fresh_bin" run_install "$fresh_home" "$fresh_project" "$fresh_log"; then
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
check assert_file_exists "$fresh_home/.mindlayer/memory-system/schema.md"
check assert_dir_exists "$fresh_home/.mindlayer/memory-system/commands"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/index.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/init.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/load.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/save.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/status.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/archive.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/session.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/commands/onboard.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/hooks/claude-user-prompt-submit.sh"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/AGENTS.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/CLAUDE.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/copilot-instructions.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/GEMINI.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/cursor-mindlayer.md"
check assert_file_exists "$fresh_home/.mindlayer/memory-system/templates/windsurf-mindlayer.md"
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
check assert_contains "$fresh_home/.mindlayer/memory-system/read-write.md" 'always check project `.mindlayer/knowledge/project.md`'
check assert_contains "$fresh_home/.mindlayer/memory-system/read-write.md" "explicit approval"

for file in knowledge/project.md knowledge/index.md pipeline/progress.md pipeline/index.md knowledge/decisions/index.md knowledge/context.md pipeline/backlog.md pipeline/roadmap.md knowledge/risks.md index.md local.md; do
  check assert_file_exists "$fresh_project/.mindlayer/$file"
done

check assert_file_exists "$fresh_project/AGENTS.md"
check assert_file_exists "$fresh_project/CLAUDE.md"
check assert_file_exists "$fresh_project/.claude/settings.local.json"
check assert_file_exists "$fresh_project/.github/copilot-instructions.md"
check assert_file_exists "$fresh_project/GEMINI.md"
check assert_file_exists "$fresh_project/.cursor/rules/mindlayer.md"
check assert_file_exists "$fresh_project/.windsurf/rules/mindlayer.md"
check assert_file_exists "$fresh_project/.mindlayer/adapters.lock"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/AGENTS.md" "$fresh_project/AGENTS.md"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/CLAUDE.md" "$fresh_project/CLAUDE.md"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/copilot-instructions.md" "$fresh_project/.github/copilot-instructions.md"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/GEMINI.md" "$fresh_project/GEMINI.md"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/cursor-mindlayer.md" "$fresh_project/.cursor/rules/mindlayer.md"
check assert_files_equal "$fresh_home/.mindlayer/memory-system/templates/windsurf-mindlayer.md" "$fresh_project/.windsurf/rules/mindlayer.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" "AGENTS.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" "CLAUDE.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" ".github/copilot-instructions.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" "GEMINI.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" ".cursor/rules/mindlayer.md"
check assert_lock_hash_for "$fresh_project/.mindlayer/adapters.lock" ".windsurf/rules/mindlayer.md"
check assert_not_contains "$fresh_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_not_contains "$fresh_project/AGENTS.md" "<!-- mindlayer:end -->"
check assert_not_contains "$fresh_project/CLAUDE.md" "<!-- mindlayer:start -->"
check assert_not_contains "$fresh_project/CLAUDE.md" "<!-- mindlayer:end -->"
check assert_not_contains "$fresh_project/.github/copilot-instructions.md" "<!-- mindlayer:start -->"
check assert_not_contains "$fresh_project/.github/copilot-instructions.md" "<!-- mindlayer:end -->"
check assert_contains "$fresh_project/AGENTS.md" 'Read `~/.mindlayer/boot.md` first'
check assert_contains "$fresh_project/AGENTS.md" "first project-relevant request"
check assert_contains "$fresh_project/AGENTS.md" "Never answer a project question without booting first"
check assert_contains "$fresh_project/AGENTS.md" "Never ask the user if they want you to boot"
check assert_contains "$fresh_project/CLAUDE.md" "Do not duplicate memory into"
check assert_contains "$fresh_project/CLAUDE.md" "explicit approval"
check assert_contains "$fresh_project/.claude/settings.local.json" "UserPromptSubmit"
check assert_contains "$fresh_project/.claude/settings.local.json" "claude-user-prompt-submit.sh"
check assert_contains "$fresh_project/.github/copilot-instructions.md" 'Do not use `README.md` or `docs/` as memory input.'
check assert_contains "$fresh_project/.github/copilot-instructions.md" "Do not retrieve durable context from this adapter."
check assert_contains "$fresh_project/.gitignore" ".mindlayer/local.md"
check assert_contains "$fresh_project/.gitignore" ".mindlayer/private/"
check assert_contains "$fresh_project/.gitignore" ".mindlayer/adapters.lock"
check assert_contains "$fresh_project/.gitignore" ".claude/settings.local.json"
check assert_contains "$fresh_project/.gitignore" "GEMINI.md"
check assert_contains "$fresh_project/.gitignore" ".cursor/rules/mindlayer.md"
check assert_contains "$fresh_project/.gitignore" ".windsurf/rules/mindlayer.md"
check assert_index_sections_exist "$fresh_project/.mindlayer"

scenario "install skip flags"
skip_home="$SANDBOX/skip-home"
skip_project="$SANDBOX/skip-project"
skip_log="$SANDBOX/skip-install.log"
mkdir -p "$skip_home" "$skip_project"

if PATH="/usr/bin:/bin" HOME="$skip_home" bash "$ROOT_DIR/install.sh" --project "$skip_project" --no-adapters --no-gitignore --no-onboard > "$skip_log" 2>&1; then
  pass "$CURRENT_SCENARIO: installer exits successfully"
else
  fail "$CURRENT_SCENARIO: installer exits successfully"
fi

check assert_file_exists "$skip_home/.mindlayer/bin/ml"
check assert_file_exists "$skip_project/.mindlayer/knowledge/project.md"
check assert_not_exists "$skip_project/AGENTS.md"
check assert_not_exists "$skip_project/CLAUDE.md"
check assert_not_exists "$skip_project/.mindlayer/adapters.lock"
check assert_not_exists "$skip_project/.gitignore"

scenario "selective detection installs only detected adapters"
selective_home="$SANDBOX/selective-home"
selective_project="$SANDBOX/selective-project"
selective_log="$SANDBOX/selective-install.log"
mkdir -p "$selective_home/.claude" "$selective_project/.github"

if run_install "$selective_home" "$selective_project" "$selective_log"; then
  pass "$CURRENT_SCENARIO: installer exits successfully"
else
  fail "$CURRENT_SCENARIO: installer exits successfully"
fi

check assert_file_exists "$selective_project/AGENTS.md"
check assert_file_exists "$selective_project/CLAUDE.md"
check assert_file_exists "$selective_project/.claude/settings.local.json"
check assert_not_exists "$selective_project/.github/copilot-instructions.md"
check assert_not_exists "$selective_project/GEMINI.md"
check assert_not_exists "$selective_project/.cursor/rules/mindlayer.md"
check assert_not_exists "$selective_project/.windsurf/rules/mindlayer.md"
check assert_lock_hash_for "$selective_project/.mindlayer/adapters.lock" "AGENTS.md"
check assert_lock_hash_for "$selective_project/.mindlayer/adapters.lock" "CLAUDE.md"
check assert_not_contains "$selective_project/.mindlayer/adapters.lock" ".github/copilot-instructions.md="
check assert_not_contains "$selective_project/.mindlayer/adapters.lock" "GEMINI.md="
check assert_not_contains "$selective_project/.mindlayer/adapters.lock" ".cursor/rules/mindlayer.md="
check assert_not_contains "$selective_project/.mindlayer/adapters.lock" ".windsurf/rules/mindlayer.md="

scenario "existing project install and idempotence"
existing_home="$SANDBOX/existing-home"
existing_project="$SANDBOX/existing-project"
existing_log_1="$SANDBOX/existing-install-1.log"
existing_log_2="$SANDBOX/existing-install-2.log"
mkdir -p "$existing_home/.mindlayer" "$existing_project/.github" "$existing_project/.mindlayer/knowledge"

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

mkdir -p "$existing_project/.cursor/rules" "$existing_project/.windsurf/rules"
cp "$ROOT_DIR/global-template/memory-system/templates/AGENTS.md" "$existing_project/AGENTS.md"
cp "$ROOT_DIR/global-template/memory-system/templates/CLAUDE.md" "$existing_project/CLAUDE.md"
cp "$ROOT_DIR/global-template/memory-system/templates/copilot-instructions.md" "$existing_project/.github/copilot-instructions.md"
cp "$ROOT_DIR/global-template/memory-system/templates/GEMINI.md" "$existing_project/GEMINI.md"
cp "$ROOT_DIR/global-template/memory-system/templates/cursor-mindlayer.md" "$existing_project/.cursor/rules/mindlayer.md"
cp "$ROOT_DIR/global-template/memory-system/templates/windsurf-mindlayer.md" "$existing_project/.windsurf/rules/mindlayer.md"

cat > "$existing_project/.gitignore" <<'EOF'
node_modules/
EOF

cat > "$existing_project/.mindlayer/knowledge/project.md" <<'EOF'
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
check assert_contains "$existing_project/.mindlayer/knowledge/project.md" "Custom project memory sentinel."
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/AGENTS.md" "$existing_project/AGENTS.md"
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/CLAUDE.md" "$existing_project/CLAUDE.md"
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/copilot-instructions.md" "$existing_project/.github/copilot-instructions.md"
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/GEMINI.md" "$existing_project/GEMINI.md"
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/cursor-mindlayer.md" "$existing_project/.cursor/rules/mindlayer.md"
check assert_files_equal "$existing_home/.mindlayer/memory-system/templates/windsurf-mindlayer.md" "$existing_project/.windsurf/rules/mindlayer.md"
check assert_contains "$existing_project/.gitignore" "node_modules/"
check assert_not_contains "$existing_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_not_contains "$existing_project/AGENTS.md" "<!-- mindlayer:end -->"
check assert_not_contains "$existing_project/CLAUDE.md" "<!-- mindlayer:start -->"
check assert_not_contains "$existing_project/CLAUDE.md" "<!-- mindlayer:end -->"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" "AGENTS.md"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" "CLAUDE.md"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" ".github/copilot-instructions.md"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" "GEMINI.md"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" ".cursor/rules/mindlayer.md"
check assert_lock_hash_for "$existing_project/.mindlayer/adapters.lock" ".windsurf/rules/mindlayer.md"
check assert_count 1 "$existing_project/.gitignore" ".mindlayer/local.md"
check assert_count 1 "$existing_project/.gitignore" ".mindlayer/private/"
check assert_count 1 "$existing_project/.gitignore" ".mindlayer/adapters.lock"
check assert_count 1 "$existing_project/.gitignore" ".claude/settings.local.json"
check assert_file_exists "$existing_home/.mindlayer/memory-system/commands/index.md"
check assert_file_exists "$existing_project/.mindlayer/index.md"

scenario "new tool detected on reinstall"
newtool_home="$SANDBOX/newtool-home"
newtool_project="$SANDBOX/newtool-project"
newtool_log_1="$SANDBOX/newtool-install-1.log"
newtool_log_2="$SANDBOX/newtool-install-2.log"
mkdir -p "$newtool_home/.claude" "$newtool_project"

if run_install "$newtool_home" "$newtool_project" "$newtool_log_1"; then
  pass "$CURRENT_SCENARIO: first installer run exits successfully"
else
  fail "$CURRENT_SCENARIO: first installer run exits successfully"
fi

check assert_file_exists "$newtool_project/AGENTS.md"
check assert_file_exists "$newtool_project/CLAUDE.md"
check assert_not_exists "$newtool_project/GEMINI.md"
agents_hash_before=$(sha256sum "$newtool_project/AGENTS.md" | awk '{print $1}')
claude_hash_before=$(sha256sum "$newtool_project/CLAUDE.md" | awk '{print $1}')

mkdir -p "$newtool_home/.gemini"
if run_install "$newtool_home" "$newtool_project" "$newtool_log_2"; then
  pass "$CURRENT_SCENARIO: second installer run exits successfully"
else
  fail "$CURRENT_SCENARIO: second installer run exits successfully"
fi

check assert_files_equal "$newtool_home/.mindlayer/memory-system/templates/AGENTS.md" "$newtool_project/AGENTS.md"
check assert_files_equal "$newtool_home/.mindlayer/memory-system/templates/CLAUDE.md" "$newtool_project/CLAUDE.md"
check assert_files_equal "$newtool_home/.mindlayer/memory-system/templates/GEMINI.md" "$newtool_project/GEMINI.md"
check assert_contains "$newtool_project/.mindlayer/adapters.lock" "AGENTS.md=$agents_hash_before"
check assert_contains "$newtool_project/.mindlayer/adapters.lock" "CLAUDE.md=$claude_hash_before"
check assert_lock_hash_for "$newtool_project/.mindlayer/adapters.lock" "GEMINI.md"

scenario "locked adapter template drift overwrites"
drift_home="$SANDBOX/drift-home"
drift_project="$SANDBOX/drift-project"
drift_log_1="$SANDBOX/drift-install-1.log"
drift_log_2="$SANDBOX/drift-install-2.log"
mkdir -p "$drift_home" "$drift_project/.mindlayer"
mkdir -p "$drift_home/.claude"

if run_install "$drift_home" "$drift_project" "$drift_log_1"; then
  pass "$CURRENT_SCENARIO: initial installer exits successfully"
else
  fail "$CURRENT_SCENARIO: initial installer exits successfully"
fi

cat > "$drift_project/AGENTS.md" <<'EOF'
# Old Canonical Adapter

Prior locked template content.
EOF

old_hash=$(sha256sum "$drift_project/AGENTS.md" | awk '{print $1}')
grep -F "CLAUDE.md=" "$drift_project/.mindlayer/adapters.lock" > "$SANDBOX/drift-claude.lock"
{
  printf "AGENTS.md=%s\n" "$old_hash"
  cat "$SANDBOX/drift-claude.lock"
} > "$drift_project/.mindlayer/adapters.lock"

if run_install "$drift_home" "$drift_project" "$drift_log_2"; then
  pass "$CURRENT_SCENARIO: installer exits successfully after locked drift"
else
  fail "$CURRENT_SCENARIO: installer exits successfully after locked drift"
fi

check assert_files_equal "$drift_home/.mindlayer/memory-system/templates/AGENTS.md" "$drift_project/AGENTS.md"
check assert_not_contains "$drift_project/AGENTS.md" "Prior locked template content."
check assert_lock_hash_for "$drift_project/.mindlayer/adapters.lock" "AGENTS.md"
check assert_lock_hash_for "$drift_project/.mindlayer/adapters.lock" "CLAUDE.md"

scenario "adapter user content blocks overwrite"
postblock_home="$SANDBOX/postblock-home"
postblock_project="$SANDBOX/postblock-project"
postblock_log="$SANDBOX/postblock-install.log"
mkdir -p "$postblock_home" "$postblock_project/.github"
mkdir -p "$postblock_home/.claude"

cat > "$postblock_project/AGENTS.md" <<'EOF'
# Agent Notes

<!-- mindlayer:start -->
Old MindLayer block content.
<!-- mindlayer:end -->

This content after the block must be preserved.
EOF

mkdir -p "$postblock_project/.mindlayer"
prior_hash="0000000000000000000000000000000000000000000000000000000000000000"
printf "AGENTS.md=%s\n" "$prior_hash" > "$postblock_project/.mindlayer/adapters.lock"

if run_install "$postblock_home" "$postblock_project" "$postblock_log"; then
  fail "$CURRENT_SCENARIO: installer refuses to overwrite user content"
else
  pass "$CURRENT_SCENARIO: installer refuses to overwrite user content"
fi

check assert_contains "$postblock_log" "Install will not overwrite this file until the content is routed through ml save."
check assert_contains "$postblock_project/AGENTS.md" "Old MindLayer block content."
check assert_contains "$postblock_project/AGENTS.md" "This content after the block must be preserved."
check assert_contains "$postblock_project/AGENTS.md" "<!-- mindlayer:start -->"
check assert_contains "$postblock_project/AGENTS.md" "<!-- mindlayer:end -->"
check assert_files_equal "$postblock_home/.mindlayer/memory-system/templates/CLAUDE.md" "$postblock_project/CLAUDE.md"
check assert_lock_hash_for "$postblock_project/.mindlayer/adapters.lock" "CLAUDE.md"
check assert_lock_hash_for "$postblock_project/.mindlayer/adapters.lock" "AGENTS.md"
check assert_contains "$postblock_project/.mindlayer/adapters.lock" "AGENTS.md=$prior_hash"

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
check assert_contains "$fresh_project/AGENTS.md" "Commands and proactive behavior"
check assert_not_contains "$fresh_project/AGENTS.md" "Context cost:"

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
