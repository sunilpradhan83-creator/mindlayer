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

printf "\n3. Recursive index-tree lint test\n"
bash "$ROOT_DIR/tests/lint/test-index-tree.sh"

printf "\n4. Local install readiness\n"
bash "$ROOT_DIR/tests/local-install/test-install.sh"

printf "\n5. Agent boot contract\n"
bash "$ROOT_DIR/tests/agent-behavior/test-boot.sh"

printf "\n6. Session continuity contract\n"
bash "$ROOT_DIR/tests/agent-behavior/test-continuity.sh"

printf "\n7. Per-turn behavioral contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-per-turn.sh"

printf "\n8. Onboard behavioral contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-onboard.sh"

printf "\n9. Memory diff behavioral contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-diff.sh"

printf "\n10. Auto-summarization suggestion contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-autosummarize.sh"

printf "\n11. Ranked load behavioral contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-load.sh"

printf "\n12. Boot receipt fixture contracts\n"
bash "$ROOT_DIR/tests/agent-behavior/test-boot-receipt.sh"

printf "\n13. ml CLI contracts\n"
bash "$ROOT_DIR/tests/ml/test-boot.sh"
bash "$ROOT_DIR/tests/ml/test-status.sh"
bash "$ROOT_DIR/tests/ml/test-diff.sh"
bash "$ROOT_DIR/tests/ml/test-load.sh"
bash "$ROOT_DIR/tests/ml/test-session.sh"
bash "$ROOT_DIR/tests/ml/test-save.sh"
bash "$ROOT_DIR/tests/ml/test-clean.sh"
bash "$ROOT_DIR/tests/ml/test-archive.sh"
bash "$ROOT_DIR/tests/ml/test-session-write.sh"
bash "$ROOT_DIR/tests/ml/test-script.sh"
