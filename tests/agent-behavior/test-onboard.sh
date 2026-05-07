#!/usr/bin/env bash
# Contract tests for MindLayer ml onboard behavioral contracts.
#
# Tests four core contracts:
#   1. Trigger    — onboard fires when ml-onboard-complete absent and project.md is starter-only
#   2. No-trigger — onboard skips when ml-onboard-complete present in index
#   3. Proposal   — each phase uses correct proposal format, one per turn
#   4. Completion — completion flag entry is written to index after flow ends
#
# Deterministic — no live model required. Tests output shape of simulated
# agent responses against onboard.md contract definitions.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

# ---------------------------------------------------------------------------
# Onboard trigger assertions
# ---------------------------------------------------------------------------

assert_onboard_fires() {
  # Must contain the onboard trigger surface in boot receipt
  grep -Eq "Onboarding:.*pending|ml onboard will run" "$1"
}

assert_onboard_skipped() {
  # Must NOT contain onboard pending line when complete flag is present
  ! grep -Eq "Onboarding:.*pending|ml onboard will run" "$1"
}

assert_onboard_load_announced() {
  # onboard.md load must be announced
  grep -Eq "^Loaded: .*onboard\.md — .{3,}" "$1"
}

# ---------------------------------------------------------------------------
# Phase 1 — adapter conflict proposal assertions
# ---------------------------------------------------------------------------

assert_phase1_format() {
  # Must contain "Onboarding — adapter conflict:" header
  grep -Eq "^Onboarding — adapter conflict:" "$1"
}

assert_phase1_has_file() {
  # Must name the file being scanned
  grep -Eq "^File: .+" "$1"
}

assert_phase1_has_found() {
  # Must quote the conflicting content
  grep -Eq "^Found: \".+\"" "$1"
}

assert_phase1_has_conflict_reason() {
  # Must explain why it conflicts
  grep -Eq "^Conflict: .{5,}" "$1"
}

assert_phase1_has_proposed_changes() {
  # Must show proposed changes
  grep -Eq "^Proposed changes:" "$1"
}

assert_phase1_has_approval_prompt() {
  # Must end with approval prompt
  grep -Eq "Say 'apply'.*'adapter only'.*'skip'.*'stop'" "$1"
}

assert_phase1_single_conflict() {
  # Must propose at most one conflict per turn
  count=$(grep -Ec "^Onboarding — adapter conflict:" "$1" || true)
  [ "$count" -le 1 ]
}

# ---------------------------------------------------------------------------
# Phase 2 — memory extraction proposal assertions
# ---------------------------------------------------------------------------

assert_phase2_format() {
  # Must contain "Onboarding — memory candidate:" header
  grep -Eq "^Onboarding — memory candidate:" "$1"
}

assert_phase2_has_destination() {
  # Must name destination file
  grep -Eq "^- Destination: .+\.md" "$1"
}

assert_phase2_has_scope() {
  # Must state scope: global or project
  grep -Eq "^- Scope: (global|project)" "$1"
}

assert_phase2_has_type() {
  # Must state type
  grep -Eq "^- Type: (preference|decision|context|principle|playbook)" "$1"
}

assert_phase2_approval_prompt() {
  grep -Eq "Say 'save'.*'skip'.*'stop'" "$1"
}

# ---------------------------------------------------------------------------
# Phase 3 — project context proposal assertions
# ---------------------------------------------------------------------------

assert_phase3_format() {
  grep -Eq "^Onboarding — project context:" "$1"
}

assert_phase3_has_source() {
  grep -Eq "^Source: .+" "$1"
}

assert_phase3_has_destination_file() {
  grep -Eq "^- File: \.mindlayer/.+\.md" "$1"
}

assert_phase3_approval_prompt() {
  grep -Eq "Say 'save'.*'skip'.*'stop'" "$1"
}

# ---------------------------------------------------------------------------
# Completion flag assertions
# ---------------------------------------------------------------------------

assert_completion_flag_written() {
  # Index must contain ml-onboard-complete entry
  grep -Fq "id: ml-onboard-complete" "$1"
}

assert_completion_flag_status() {
  # Entry must have status: complete
  grep -Fq "status: complete" "$1"
}

# ---------------------------------------------------------------------------
# Shared: one proposal per turn
# ---------------------------------------------------------------------------

assert_single_proposal_per_turn() {
  file="$1"
  phase1=$(grep -Ec "^Onboarding — adapter conflict:" "$file" || true)
  phase2=$(grep -Ec "^Onboarding — memory candidate:" "$file" || true)
  phase3=$(grep -Ec "^Onboarding — project context:" "$file" || true)
  total=$(( phase1 + phase2 + phase3 ))
  [ "$total" -le 1 ]
}

# ---------------------------------------------------------------------------
# Simulate agent responses
# ---------------------------------------------------------------------------

TMPDIR_LOCAL="${TMPDIR:-/tmp}/mindlayer-onboard-test.$$"
mkdir -p "$TMPDIR_LOCAL"

cleanup() { rm -rf "$TMPDIR_LOCAL"; }
trap cleanup EXIT

make_response() {
  local name="$1"
  local content="$2"
  local file="$TMPDIR_LOCAL/$name"
  printf "%s\n" "$content" > "$file"
  echo "$file"
}

# ---------------------------------------------------------------------------
# Scenario 1: Boot with starter-only project — onboard should fire
# ---------------------------------------------------------------------------

scenario "boot — starter-only project triggers onboard"

boot_pending=$(make_response "boot-pending.txt" "MindLayer context loaded.

Loaded:
- ~/.mindlayer/boot.md
- ~/.mindlayer/router.md

Current understanding:
Project identity: missing (placeholder only).

Current progress:
No progress recorded yet.

Onboarding:
pending — ml onboard will run on first project-relevant request.

Context cost:
Approx. 420 words loaded (~546 est. tokens).

Ready.
What would you like to work on?")

if assert_onboard_fires "$boot_pending"; then
  pass "onboard pending surfaces in boot receipt"
else
  fail "onboard pending missing from boot receipt"
fi

# ---------------------------------------------------------------------------
# Scenario 2: Boot with ml-onboard-complete in index — onboard skips
# ---------------------------------------------------------------------------

scenario "boot — ml-onboard-complete present, onboard skips"

boot_complete=$(make_response "boot-complete.txt" "MindLayer context loaded.

Loaded:
- ~/.mindlayer/boot.md
- ~/.mindlayer/router.md
- .mindlayer/index.md (24 entries)
- .mindlayer/project.md

Current understanding:
MindLayer — markdown-first memory system for AI-native developers.

Current progress:
V3 phase 2 in progress.

Context cost:
Approx. 580 words loaded (~754 est. tokens).

Ready.
What would you like to work on?")

if assert_onboard_skipped "$boot_complete"; then
  pass "onboard pending absent when ml-onboard-complete present"
else
  fail "onboard pending incorrectly surfaces when ml-onboard-complete present"
fi

# ---------------------------------------------------------------------------
# Scenario 3: onboard.md load must be announced
# ---------------------------------------------------------------------------

scenario "onboard.md load announcement"

onboard_load=$(make_response "onboard-load.txt" "Loaded: ~/.mindlayer/memory-system/commands/onboard.md — ml onboard trigger: ml-onboard-complete absent and project.md is starter-only

Starting onboarding flow. Scanning adapter files first.

Onboarding — adapter conflict:
File: AGENTS.md
Found: \"always load README.md as context at session start\"
Conflict: MindLayer boot skips README.md by design — it is human documentation, not memory input. Loading it every session wastes tokens and violates token discipline.

Proposed changes:
1. Adapter edit — remove or rephrase:
   Before: \"always load README.md as context at session start\"
   After:  [remove]

Say 'apply' to remove this line, 'adapter only' to edit the adapter without saving to MindLayer, 'skip' to leave as-is, or 'stop' to end onboarding.")

if assert_onboard_load_announced "$onboard_load"; then
  pass "onboard.md load announced with reason"
else
  fail "onboard.md load not announced"
fi

# ---------------------------------------------------------------------------
# Scenario 4: Phase 1 — valid adapter conflict proposal
# ---------------------------------------------------------------------------

scenario "phase 1 — adapter conflict proposal format"

phase1_response=$(make_response "phase1-valid.txt" "Onboarding — adapter conflict:
File: AGENTS.md
Found: \"always load README.md as context at session start\"
Conflict: MindLayer boot skips README.md by design — it is human documentation, not memory input.

Proposed changes:
1. Adapter edit — remove or rephrase:
   Before: \"always load README.md as context at session start\"
   After:  [remove]

Say 'apply' to make this change, 'adapter only' to edit the adapter only, 'skip' to leave as-is, or 'stop' to end onboarding.")

if assert_phase1_format "$phase1_response"; then
  pass "phase 1 header present"
else
  fail "phase 1 header missing"
fi

if assert_phase1_has_file "$phase1_response"; then
  pass "phase 1 file named"
else
  fail "phase 1 file not named"
fi

if assert_phase1_has_found "$phase1_response"; then
  pass "phase 1 conflicting content quoted"
else
  fail "phase 1 conflicting content not quoted"
fi

if assert_phase1_has_conflict_reason "$phase1_response"; then
  pass "phase 1 conflict reason present"
else
  fail "phase 1 conflict reason missing"
fi

if assert_phase1_has_proposed_changes "$phase1_response"; then
  pass "phase 1 proposed changes present"
else
  fail "phase 1 proposed changes missing"
fi

if assert_phase1_has_approval_prompt "$phase1_response"; then
  pass "phase 1 approval prompt correct"
else
  fail "phase 1 approval prompt missing or incorrect"
fi

if assert_phase1_single_conflict "$phase1_response"; then
  pass "phase 1 single conflict per turn"
else
  fail "phase 1 multiple conflicts in one turn (batching violation)"
fi

# ---------------------------------------------------------------------------
# Scenario 5: Phase 1 — violation: batching multiple conflicts
# ---------------------------------------------------------------------------

scenario "phase 1 — violation: multiple conflicts batched"

phase1_batched=$(make_response "phase1-batched.txt" "Onboarding — adapter conflict:
File: AGENTS.md
Found: \"always load README.md as context\"
Conflict: violates token discipline.

Proposed changes:
1. Adapter edit: remove line.

Onboarding — adapter conflict:
File: CLAUDE.md
Found: \"load docs/ at startup\"
Conflict: violates token discipline.

Proposed changes:
1. Adapter edit: remove line.

Say 'apply' to make both changes, 'skip', or 'stop'.")

if ! assert_phase1_single_conflict "$phase1_batched"; then
  pass "batched conflicts correctly detected as violation"
else
  fail "batched conflicts not detected — contract not enforced"
fi

# ---------------------------------------------------------------------------
# Scenario 6: Phase 2 — valid memory extraction proposal
# ---------------------------------------------------------------------------

scenario "phase 2 — memory extraction proposal format"

phase2_response=$(make_response "phase2-valid.txt" "Onboarding — memory candidate:
Found in: AGENTS.md
Content: \"Always use conventional commits for this project. Format: type(scope): description\"
Reason: recurring workflow preference worth preserving across sessions.

Proposed write:
- Destination: .mindlayer/decisions.md
- Scope: project
- Type: decision

Say 'save' to migrate to MindLayer, 'skip' to leave in adapter only, or 'stop' to end onboarding.")

if assert_phase2_format "$phase2_response"; then
  pass "phase 2 header present"
else
  fail "phase 2 header missing"
fi

if assert_phase2_has_destination "$phase2_response"; then
  pass "phase 2 destination file named"
else
  fail "phase 2 destination file missing"
fi

if assert_phase2_has_scope "$phase2_response"; then
  pass "phase 2 scope stated"
else
  fail "phase 2 scope missing"
fi

if assert_phase2_has_type "$phase2_response"; then
  pass "phase 2 type stated"
else
  fail "phase 2 type missing"
fi

if assert_phase2_approval_prompt "$phase2_response"; then
  pass "phase 2 approval prompt correct"
else
  fail "phase 2 approval prompt missing or incorrect"
fi

# ---------------------------------------------------------------------------
# Scenario 7: Phase 3 — valid project context proposal
# ---------------------------------------------------------------------------

scenario "phase 3 — project context proposal format"

phase3_response=$(make_response "phase3-valid.txt" "Onboarding — project context:
Source: README.md
Found: This is a TypeScript monorepo using pnpm workspaces. Core packages: api/, web/, shared/.

Proposed write:
- File: .mindlayer/project.md
- Section: Project Identity
- Content: TypeScript monorepo using pnpm workspaces. Core packages: api/ (Express REST API), web/ (Next.js frontend), shared/ (types and utilities).
- Reason: stable project identity — useful at every session boot.

Say 'save', 'skip', or 'stop'.")

if assert_phase3_format "$phase3_response"; then
  pass "phase 3 header present"
else
  fail "phase 3 header missing"
fi

if assert_phase3_has_source "$phase3_response"; then
  pass "phase 3 source named"
else
  fail "phase 3 source missing"
fi

if assert_phase3_has_destination_file "$phase3_response"; then
  pass "phase 3 destination file in .mindlayer/"
else
  fail "phase 3 destination file missing or not in .mindlayer/"
fi

if assert_phase3_approval_prompt "$phase3_response"; then
  pass "phase 3 approval prompt correct"
else
  fail "phase 3 approval prompt missing or incorrect"
fi

# ---------------------------------------------------------------------------
# Scenario 8: Single proposal per turn across phases
# ---------------------------------------------------------------------------

scenario "single proposal per turn — cross-phase enforcement"

single_turn=$(make_response "single-turn.txt" "Onboarding — project context:
Source: README.md
Found: TypeScript monorepo.

Proposed write:
- File: .mindlayer/project.md
- Section: Project Identity
- Content: TypeScript monorepo using pnpm workspaces.
- Reason: stable identity.

Say 'save', 'skip', or 'stop'.")

if assert_single_proposal_per_turn "$single_turn"; then
  pass "single proposal per turn (phase 3 only)"
else
  fail "multiple proposals in one turn (batching violation)"
fi

mixed_turn=$(make_response "mixed-turn.txt" "Onboarding — adapter conflict:
File: AGENTS.md
Found: \"load README.md\"
Conflict: violates token discipline.

Proposed changes:
1. Adapter edit: remove line.

Onboarding — project context:
Source: README.md
Found: TypeScript monorepo.

Proposed write:
- File: .mindlayer/project.md
- Section: Project Identity
- Content: TypeScript monorepo.
- Reason: stable identity.

Say 'apply' or 'save'.")

if ! assert_single_proposal_per_turn "$mixed_turn"; then
  pass "mixed-phase batching correctly detected as violation"
else
  fail "mixed-phase batching not detected — contract not enforced"
fi

# ---------------------------------------------------------------------------
# Scenario 9: Completion flag written to index
# ---------------------------------------------------------------------------

scenario "completion flag written to index"

index_with_flag=$(make_response "index-with-flag.md" "# Project Memory Index

## Entries

- id: ml-onboard-complete
  title: Onboarding Complete
  file: index.md
  section: Entries
  scope: project
  type: onboarding
  tags: [onboarding]
  summary: ml onboard completed. One-time flow done — this command will not fire again.
  importance: low
  status: complete
  last_updated: 2026-05-07")

if assert_completion_flag_written "$index_with_flag"; then
  pass "ml-onboard-complete entry present in index"
else
  fail "ml-onboard-complete entry missing from index"
fi

if assert_completion_flag_status "$index_with_flag"; then
  pass "completion flag has status: complete"
else
  fail "completion flag missing status: complete"
fi

index_without_flag=$(make_response "index-without-flag.md" "# Project Memory Index

## Entries

- id: ml-project-20260430-001
  title: Project starter context
  file: project.md
  section: Entry Template
  scope: project
  type: context
  tags: []
  summary: Starter project context entry.
  importance: low
  status: active
  last_updated: 2026-05-07")

if ! assert_completion_flag_written "$index_without_flag"; then
  pass "correctly detects missing ml-onboard-complete flag"
else
  fail "false positive — flag detected when absent"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf "\nMindLayer Onboard Contract Summary\n"
printf "Passed: %s\n" "$PASS_COUNT"
printf "Failed: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: ONBOARD CONTRACT READY\n"
  exit 0
fi

printf "Verdict: ONBOARD CONTRACT FAILURES\n"
exit 1
