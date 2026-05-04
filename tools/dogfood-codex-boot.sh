#!/usr/bin/env bash
# Opt-in real Codex dogfood check for MindLayer boot timing.
#
# This script uses the local Codex CLI to start fresh non-interactive sessions
# against a sandbox project. It is intentionally separate from tools/test.sh
# because it depends on local Codex auth, model availability, and network access.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-codex-dogfood.$$"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"
CODEX_BIN="${CODEX_BIN:-codex}"
REAL_HOME="${HOME}"
CODEX_HOME_DIR="${CODEX_HOME:-$REAL_HOME/.codex}"

cleanup() {
  if [ "$KEEP_TEST_DIR" = "1" ]; then
    printf "\nKept sandbox: %s\n" "$SANDBOX"
  else
    rm -rf "$SANDBOX"
  fi
}

run_codex() {
  prompt="$1"
  output_file="$2"
  log_file="$3"

  HOME="$SANDBOX/home" \
  CODEX_HOME="$CODEX_HOME_DIR" \
  "$CODEX_BIN" -a never exec \
    --cd "$SANDBOX/project" \
    --sandbox read-only \
    --ephemeral \
    --output-last-message "$output_file" \
    "$prompt" > "$log_file" 2>&1
}

assert_contains() {
  file="$1"
  pattern="$2"
  grep -Fq "$pattern" "$file"
}

assert_not_contains() {
  file="$1"
  pattern="$2"
  ! grep -Fq "$pattern" "$file"
}

trap cleanup EXIT
mkdir -p "$SANDBOX/home" "$SANDBOX/project"

printf "MindLayer Codex Dogfood Boot Check\n"
printf "==================================\n"
printf "Repo: %s\n" "$ROOT_DIR"
printf "Sandbox: %s\n" "$SANDBOX"
printf "Codex binary: %s\n" "$CODEX_BIN"
printf "Codex home: %s\n\n" "$CODEX_HOME_DIR"

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  printf "FAIL  Codex binary not found: %s\n" "$CODEX_BIN" >&2
  exit 1
fi

HOME="$SANDBOX/home" bash "$ROOT_DIR/install.sh" --project "$SANDBOX/project" --no-onboard >/dev/null
printf "PASS  installed MindLayer into sandbox HOME and project\n"

hi_response="$SANDBOX/hi-response.md"
hi_log="$SANDBOX/hi-codex.log"
project_response="$SANDBOX/project-response.md"
project_log="$SANDBOX/project-codex.log"

printf "\n1. Fresh greeting session\n"
if run_codex "hi" "$hi_response" "$hi_log"; then
  printf "PASS  codex exec completed for greeting\n"
else
  printf "FAIL  codex exec failed for greeting\n" >&2
  sed -n '1,160p' "$hi_log" >&2 || true
  exit 1
fi

if assert_not_contains "$hi_response" "MindLayer context loaded."; then
  printf "PASS  greeting did not emit MindLayer boot receipt\n"
else
  printf "FAIL  greeting emitted MindLayer boot receipt\n" >&2
  sed -n '1,160p' "$hi_response" >&2
  exit 1
fi

printf "\n2. Fresh project-question session\n"
if run_codex "what is this project?" "$project_response" "$project_log"; then
  printf "PASS  codex exec completed for project question\n"
else
  printf "FAIL  codex exec failed for project question\n" >&2
  sed -n '1,160p' "$project_log" >&2 || true
  exit 1
fi

if assert_contains "$project_response" "MindLayer context loaded."; then
  printf "PASS  project question emitted MindLayer boot receipt\n"
else
  printf "FAIL  project question did not emit MindLayer boot receipt\n" >&2
  sed -n '1,220p' "$project_response" >&2
  exit 1
fi

if assert_contains "$project_response" "~/.mindlayer/memory-system.md"; then
  printf "PASS  boot receipt loaded ~/.mindlayer/memory-system.md\n"
else
  printf "FAIL  boot receipt did not list ~/.mindlayer/memory-system.md\n" >&2
  sed -n '1,220p' "$project_response" >&2
  exit 1
fi

if assert_contains "$project_response" "~/.mindlayer/preferences.md" && assert_contains "$project_response" "starter"; then
  printf "PASS  boot receipt mentioned starter-only preferences handling\n"
else
  printf "FAIL  boot receipt did not mention starter-only preferences handling\n" >&2
  sed -n '1,220p' "$project_response" >&2
  exit 1
fi

printf "\nVerdict: REAL CODEX BOOT DOGFOOD PASSED\n"
