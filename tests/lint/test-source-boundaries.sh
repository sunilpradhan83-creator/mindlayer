#!/usr/bin/env bash
# Negative lint test for MindLayer source-boundary rules.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
SANDBOX="${TMPDIR:-/tmp}/mindlayer-lint-test.$$"
KEEP_TEST_DIR="${KEEP_TEST_DIR:-0}"

cleanup() {
  if [ "$KEEP_TEST_DIR" = "1" ]; then
    printf "Kept sandbox: %s\n" "$SANDBOX"
  else
    rm -rf "$SANDBOX"
  fi
}

trap cleanup EXIT

mkdir -p "$SANDBOX/project"

copy_path() {
  src="$1"
  dest="$SANDBOX/project/$1"
  if [ -d "$ROOT_DIR/$src" ]; then
    mkdir -p "$dest"
    cp -R "$ROOT_DIR/$src/." "$dest/"
  elif [ -f "$ROOT_DIR/$src" ]; then
    mkdir -p "$(dirname "$dest")"
    cp "$ROOT_DIR/$src" "$dest"
  fi
}

copy_path ".mindlayer"
copy_path ".github"
copy_path "global-template"
copy_path "tools"
copy_path "install.sh"
copy_path "AGENTS.md"
copy_path "CLAUDE.md"

sed -i '/proactive behavior/d' "$SANDBOX/project/AGENTS.md"

if bash "$SANDBOX/project/tools/lint.sh" --project "$SANDBOX/project" > "$SANDBOX/lint.log" 2>&1; then
  printf "FAIL  expected lint to fail when AGENTS.md proactive behavior reference is removed\n"
  cat "$SANDBOX/lint.log"
  exit 1
fi

if ! grep -Fq "[E7] AGENTS.md must exactly match canonical template" "$SANDBOX/lint.log"; then
  printf "FAIL  expected E7 source-boundary error in lint output\n"
  cat "$SANDBOX/lint.log"
  exit 1
fi

printf "PASS  source-boundary lint fails when AGENTS.md loses proactive behavior reference\n"
