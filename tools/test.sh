#!/usr/bin/env bash
# Run MindLayer's local validation suite.

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"

printf "MindLayer test suite\n"
printf "====================\n\n"

printf "1. Lint memory and adapters\n"
bash "$ROOT_DIR/tools/lint.sh" --project "$ROOT_DIR"

printf "\n2. Negative source-boundary lint test\n"
bash "$ROOT_DIR/tests/lint/test-source-boundaries.sh"

printf "\n3. Local install readiness\n"
bash "$ROOT_DIR/tests/local-install/test-install.sh"

printf "\n4. Agent first-interaction contract\n"
bash "$ROOT_DIR/tests/agent-behavior/test-first-interaction.sh"
