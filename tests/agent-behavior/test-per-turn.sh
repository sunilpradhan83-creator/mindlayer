#!/usr/bin/env bash
# Rigorous contract tests for MindLayer per-turn behavioral contracts.
#
# Tests three core contracts:
#   1. Load Announcement  — every file load must be announced with reason
#   2. Memory Candidate   — durable content must surface a save proposal
#   3. Retrieval Suggestion — relevant unloaded index entries must be flagged
#   4. Token Burned Block — must appear on every turn, never blank
#   5. Lazy module layout — per-turn core stays small and modules route lazily
#
# Deterministic — no live model required. Tests output shape of simulated
# agent responses against per-turn.md contract definitions.

set -u

PASS_COUNT=0
FAIL_COUNT=0
CURRENT_SCENARIO=""

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf "PASS  %s\n" "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf "FAIL  %s\n" "$1"; }
scenario() { CURRENT_SCENARIO="$1"; printf "\n## %s\n" "$CURRENT_SCENARIO"; }

MODULES="load-announce memory-candidate retrieval lateral-intent session-warning post-write"

# ---------------------------------------------------------------------------
# Spec layout assertions
# ---------------------------------------------------------------------------

assert_core_per_turn_present() {
  grep -Fq "# Per-Turn Core" "$1" &&
    grep -Fq "Token Burned:" "$1" &&
    grep -Fq "Next Step:" "$1" &&
    grep -Fq "memory-system/per-turn/" "$1"
}

assert_core_per_turn_small() {
  words=$(wc -w < "$1")
  [ "$words" -le 220 ]
}

assert_module_exists() {
  [ -f "global-template/memory-system/per-turn/$1.md" ]
}

assert_module_synced() {
  module="$1"
  cmp -s "$HOME/.mindlayer/memory-system/per-turn/$module.md" "global-template/memory-system/per-turn/$module.md"
}

assert_core_synced() {
  cmp -s "$HOME/.mindlayer/memory-system/per-turn.md" "global-template/memory-system/per-turn.md"
}

assert_router_has_module_trigger() {
  module="$1"
  grep -Fq "memory-system/per-turn/$module.md" "global-template/router.md" &&
    grep -Fq "memory-system/per-turn/$module.md" "$HOME/.mindlayer/router.md"
}

# ---------------------------------------------------------------------------
# Load announcement assertions
# ---------------------------------------------------------------------------

assert_has_load_announcement() {
  # Must match: Loaded: <path> — <reason>  (non-empty path and reason)
  grep -Eq "^Loaded: .{3,} — .{3,}" "$1"
}

assert_load_announcement_format() {
  file="$1"
  # Must NOT have announcement without reason (missing " — ")
  if grep -Eq "^Loaded: " "$file"; then
    grep -Eq "^Loaded: .{3,} — .{3,}" "$file"
  else
    return 0
  fi
}

assert_no_duplicate_boot_announcement() {
  file="$1"
  # boot.md, router.md, per-turn.md are loaded at boot — must not be re-announced mid-session
  ! grep -Eq "^Loaded: ~/\.mindlayer/(boot|router)\.md" "$file"
}

assert_no_load_announcement() {
  ! grep -Eq "^Loaded: .+ — .+" "$1"
}

# ---------------------------------------------------------------------------
# Memory candidate assertions
# ---------------------------------------------------------------------------

assert_has_memory_candidate() {
  # Must match: Memory candidate: <desc> → <file.md> — say 'save' or 'skip'
  grep -Eq "^Memory candidate: .{5,} → .+\.md" "$1"
}

assert_memory_candidate_has_target() {
  file="$1"
  if grep -Eq "^Memory candidate:" "$file"; then
    grep -Eq "^Memory candidate: .{5,} → .+\.md" "$file"
  else
    return 0
  fi
}

assert_memory_candidate_not_adapter() {
  file="$1"
  # Adapters (AGENTS.md, CLAUDE.md, copilot-instructions.md) are not valid targets
  ! grep -Eq "^Memory candidate: .+ → (AGENTS|CLAUDE|copilot-instructions)\.md" "$file"
}

assert_single_memory_candidate() {
  file="$1"
  count=$(grep -Ec "^Memory candidate:" "$file" || true)
  [ "$count" -le 1 ]
}

assert_no_memory_candidate() {
  ! grep -Eq "^Memory candidate:" "$1"
}

assert_pending_candidate_resurfaced() {
  file="$1"
  # When a prior candidate was not saved or skipped, it must reappear
  grep -Eq "^Memory candidate: .{5,} → .+\.md" "$file"
}

# ---------------------------------------------------------------------------
# Retrieval suggestion assertions
# ---------------------------------------------------------------------------

assert_has_retrieval_suggestion() {
  grep -Eq "^Relevant memory not loaded: .{5,}" "$1"
}

assert_retrieval_suggestion_has_query() {
  file="$1"
  if grep -Eq "^Relevant memory not loaded:" "$file"; then
    grep -Eq "^Relevant memory not loaded: .+ — say 'ml load .+' to load" "$file"
  else
    return 0
  fi
}

assert_single_retrieval_suggestion() {
  file="$1"
  count=$(grep -Ec "^Relevant memory not loaded:" "$file" || true)
  [ "$count" -le 1 ]
}

assert_no_retrieval_suggestion() {
  ! grep -Eq "^Relevant memory not loaded:" "$1"
}

assert_no_suggestion_for_loaded_file() {
  file="$1"
  loaded_file="$2"
  ! grep -Fq "$loaded_file" "$file" 2>/dev/null || \
    ! grep -Eq "^Relevant memory not loaded: .*$loaded_file" "$file"
}

# ---------------------------------------------------------------------------
# Token Burned block assertions
# ---------------------------------------------------------------------------

assert_has_token_burned_block() {
  file="$1"
  grep -Fq "Token Burned:" "$file" || return 1
  grep -Eq "^  - Last turn: ~[0-9][0-9,]* words, ~[0-9][0-9,]* est\. tokens$" "$file" || return 1
  grep -Eq "^  - Session: ~[0-9][0-9,]* words, ~[0-9][0-9,]* est\. tokens$" "$file" || return 1
  grep -Fq "Next Step:" "$file" || return 1
}

assert_next_step_not_blank() {
  # Next Step must be followed by at least 5 characters of content
  grep -Eq "^Next Step: .{5,}" "$1"
}

assert_coming_up_only_when_needed() {
  file="$1"
  # Coming Up: must not appear when Next Step is clear and queue <= 2
  # We can only test the negative: if Coming Up: appears, it must list items
  if grep -Fq "Coming Up:" "$file"; then
    grep -Eq "^  - .+" "$file"
  else
    return 0
  fi
}

assert_no_coming_up_single_action() {
  file="$1"
  # If explicitly marked as single-action context, Coming Up: must not appear
  marker="$2"
  if grep -Fq "$marker" "$file"; then
    ! grep -Fq "Coming Up:" "$file"
  else
    return 0
  fi
}

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------

check() {
  local label="$1"
  local fn="$2"
  local file="$3"
  if $fn "$file" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

check2() {
  local label="$1"
  local fn="$2"
  local file="$3"
  local arg2="$4"
  if $fn "$file" "$arg2" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: $label"
  else
    fail "$CURRENT_SCENARIO: $label"
  fi
}

SANDBOX="${TMPDIR:-/tmp}/mindlayer-per-turn-test.$$"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT
mkdir -p "$SANDBOX"

printf "MindLayer Per-Turn Behavioral Contract\n"
printf "=======================================\n"

# ===========================================================================
# SPEC LAYOUT: CORE + CONDITIONAL MODULES
# ===========================================================================

scenario "spec layout — core plus lazy modules"
check "core per-turn exists with Token Burned contract" assert_core_per_turn_present "global-template/memory-system/per-turn.md"
check "core per-turn stays small" assert_core_per_turn_small "global-template/memory-system/per-turn.md"
check "live core synced with global-template" assert_core_synced "global-template/memory-system/per-turn.md"

for module in $MODULES; do
  if assert_module_exists "$module" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: module exists: $module"
  else
    fail "$CURRENT_SCENARIO: module exists: $module"
  fi

  if assert_module_synced "$module" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: live module synced: $module"
  else
    fail "$CURRENT_SCENARIO: live module synced: $module"
  fi

  if assert_router_has_module_trigger "$module" 2>/dev/null; then
    pass "$CURRENT_SCENARIO: router trigger present: $module"
  else
    fail "$CURRENT_SCENARIO: router trigger present: $module"
  fi
done

# ===========================================================================
# CONTRACT 1: LOAD ANNOUNCEMENT
# ===========================================================================

scenario "load announcement — happy path single file"
f="$SANDBOX/load-single.md"
cat > "$f" <<'EOF'
Loaded: .mindlayer/knowledge/decisions.md — design question detected

Here is the answer to your question about the routing decision.

Memory candidate: routing decision rationale → decisions.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~80 words, ~104 est. tokens
  - Session: ~2,400 words, ~3,120 est. tokens

Next Step: Review the routing decision entry and confirm.
--------------------------------------------------------------
EOF
check "announcement present" assert_has_load_announcement "$f"
check "format valid (has reason)" assert_load_announcement_format "$f"
check "no boot file re-announced" assert_no_duplicate_boot_announcement "$f"

scenario "load announcement — multiple files loaded"
f="$SANDBOX/load-multi.md"
cat > "$f" <<'EOF'
Loaded: .mindlayer/knowledge/decisions.md — design question detected
Loaded: .mindlayer/knowledge/risks.md — risk concern detected

Answer content here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~60 words, ~78 est. tokens
  - Session: ~1,800 words, ~2,340 est. tokens

Next Step: Save the identified risk to risks.md.
--------------------------------------------------------------
EOF
check "announcements present" assert_has_load_announcement "$f"
check "format valid" assert_load_announcement_format "$f"

scenario "load announcement — no load, no announcement"
f="$SANDBOX/load-none.md"
cat > "$f" <<'EOF'
Here is the answer using already-loaded context.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~40 words, ~52 est. tokens
  - Session: ~1,200 words, ~1,560 est. tokens

Next Step: Run tests before pushing.
--------------------------------------------------------------
EOF
check "no spurious announcement" assert_no_load_announcement "$f"

scenario "load announcement — violation: missing reason"
f="$SANDBOX/load-no-reason.md"
cat > "$f" <<'EOF'
Loaded: .mindlayer/knowledge/decisions.md

Answer here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Confirm the decision.
--------------------------------------------------------------
EOF
if assert_load_announcement_format "$f" 2>/dev/null; then
  fail "load announcement — violation: missing reason: should have been rejected"
else
  pass "load announcement — violation: missing reason: correctly rejected"
fi

scenario "load announcement — violation: boot file re-announced"
f="$SANDBOX/load-boot-reannounce.md"
cat > "$f" <<'EOF'
Loaded: ~/.mindlayer/boot.md — re-loading boot context

Answer here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Continue with task.
--------------------------------------------------------------
EOF
if assert_no_duplicate_boot_announcement "$f" 2>/dev/null; then
  fail "load announcement — violation: boot re-announced: should have been rejected"
else
  pass "load announcement — violation: boot re-announced: correctly rejected"
fi

scenario "load announcement — violation: load happened but not announced"
f="$SANDBOX/load-silent.md"
cat > "$f" <<'EOF'
Based on the decisions file, the rationale is clear.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~600 words, ~780 est. tokens

Next Step: Proceed with implementation.
--------------------------------------------------------------
EOF
# Simulate: we know a file was loaded (referenced in response) but no announcement
if grep -q "decisions file" "$f" && ! assert_has_load_announcement "$f" 2>/dev/null; then
  pass "load announcement — violation: silent load detected"
else
  fail "load announcement — violation: silent load detected"
fi

# ===========================================================================
# CONTRACT 2: MEMORY CANDIDATE
# ===========================================================================

scenario "memory candidate — decision made"
f="$SANDBOX/candidate-decision.md"
cat > "$f" <<'EOF'
The routing decision is: always load decisions.md when any /m-* command fires.

Memory candidate: routing trigger now includes all /m-* commands → decisions.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~60 words, ~78 est. tokens
  - Session: ~1,800 words, ~2,340 est. tokens

Next Step: Approve or skip the memory candidate above.
--------------------------------------------------------------
EOF
check "candidate present" assert_has_memory_candidate "$f"
check "candidate has valid target" assert_memory_candidate_has_target "$f"
check "target is not an adapter" assert_memory_candidate_not_adapter "$f"
check "only one candidate per turn" assert_single_memory_candidate "$f"

scenario "memory candidate — risk identified"
f="$SANDBOX/candidate-risk.md"
cat > "$f" <<'EOF'
The router enforcement gap means rules can silently fail mid-session.

Memory candidate: router rules may silently fail when context drifts → risks.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~50 words, ~65 est. tokens
  - Session: ~1,500 words, ~1,950 est. tokens

Next Step: Approve or skip the memory candidate above.
--------------------------------------------------------------
EOF
check "risk candidate present" assert_has_memory_candidate "$f"
check "candidate has valid target" assert_memory_candidate_has_target "$f"

scenario "memory candidate — no durable content, no spurious candidate"
f="$SANDBOX/candidate-none.md"
cat > "$f" <<'EOF'
Here is the list of files in the directory.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~20 words, ~26 est. tokens
  - Session: ~600 words, ~780 est. tokens

Next Step: Run the test suite.
--------------------------------------------------------------
EOF
check "no spurious candidate" assert_no_memory_candidate "$f"

scenario "memory candidate — prior candidate re-surfaced"
f="$SANDBOX/candidate-resurfaced.md"
cat > "$f" <<'EOF'
Answer to user question here.

Memory candidate: SCRIPT philosophy defined this session → context.md — say 'save' or 'skip' (re-surfaced — not yet saved or skipped)

-------------------------------------------------------------
Token Burned:
  - Last turn: ~50 words, ~65 est. tokens
  - Session: ~2,000 words, ~2,600 est. tokens

Next Step: Approve or skip the pending memory candidate.
--------------------------------------------------------------
EOF
check "prior candidate resurfaced" assert_pending_candidate_resurfaced "$f"

scenario "memory candidate — violation: no target file"
f="$SANDBOX/candidate-no-target.md"
cat > "$f" <<'EOF'
A decision was made about routing.

Memory candidate: routing decision — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Save the decision.
--------------------------------------------------------------
EOF
if assert_memory_candidate_has_target "$f" 2>/dev/null; then
  fail "memory candidate — violation: no target: should have been rejected"
else
  pass "memory candidate — violation: no target: correctly rejected"
fi

scenario "memory candidate — violation: adapter as target"
f="$SANDBOX/candidate-adapter-target.md"
cat > "$f" <<'EOF'
The boot rule should be saved.

Memory candidate: boot rule update → AGENTS.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Save the rule.
--------------------------------------------------------------
EOF
if assert_memory_candidate_not_adapter "$f" 2>/dev/null; then
  fail "memory candidate — violation: adapter target: should have been rejected"
else
  pass "memory candidate — violation: adapter target: correctly rejected"
fi

scenario "memory candidate — violation: two candidates same turn"
f="$SANDBOX/candidate-two.md"
cat > "$f" <<'EOF'
Two things to save this turn.

Memory candidate: decision about routing → decisions.md — say 'save' or 'skip'
Memory candidate: risk about enforcement → risks.md — say 'save' or 'skip'

-------------------------------------------------------------
Token Burned:
  - Last turn: ~40 words, ~52 est. tokens
  - Session: ~1,200 words, ~1,560 est. tokens

Next Step: Save the first candidate.
--------------------------------------------------------------
EOF
if assert_single_memory_candidate "$f" 2>/dev/null; then
  fail "memory candidate — violation: two candidates: should have been rejected"
else
  pass "memory candidate — violation: two candidates: correctly rejected"
fi

# ===========================================================================
# CONTRACT 3: RETRIEVAL SUGGESTION
# ===========================================================================

scenario "retrieval suggestion — relevant unloaded entry flagged"
f="$SANDBOX/retrieval-flagged.md"
cat > "$f" <<'EOF'
Here is the answer about the routing question.

Relevant memory not loaded: Router Enforcement Gap (ml-20260507-003) — say 'ml load router enforcement' to load

-------------------------------------------------------------
Token Burned:
  - Last turn: ~50 words, ~65 est. tokens
  - Session: ~1,500 words, ~1,950 est. tokens

Next Step: Load the router enforcement entry or proceed without it.
--------------------------------------------------------------
EOF
check "retrieval suggestion present" assert_has_retrieval_suggestion "$f"
check "suggestion has query" assert_retrieval_suggestion_has_query "$f"
check "only one suggestion per turn" assert_single_retrieval_suggestion "$f"

scenario "retrieval suggestion — no relevant unloaded entry"
f="$SANDBOX/retrieval-none.md"
cat > "$f" <<'EOF'
All relevant context is already loaded. Here is the answer.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Proceed with implementation.
--------------------------------------------------------------
EOF
check "no spurious suggestion" assert_no_retrieval_suggestion "$f"

scenario "retrieval suggestion — no suggestion for already-loaded file"
f="$SANDBOX/retrieval-loaded.md"
cat > "$f" <<'EOF'
Based on decisions.md which is already loaded, here is the answer.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Confirm the decision.
--------------------------------------------------------------
EOF
check2 "no suggestion for loaded file" assert_no_suggestion_for_loaded_file "$f" "decisions.md"

scenario "retrieval suggestion — violation: missing query"
f="$SANDBOX/retrieval-no-query.md"
cat > "$f" <<'EOF'
Answer here.

Relevant memory not loaded: Router Enforcement Gap

-------------------------------------------------------------
Token Burned:
  - Last turn: ~20 words, ~26 est. tokens
  - Session: ~600 words, ~780 est. tokens

Next Step: Load the relevant memory.
--------------------------------------------------------------
EOF
if assert_retrieval_suggestion_has_query "$f" 2>/dev/null; then
  fail "retrieval suggestion — violation: no query: should have been rejected"
else
  pass "retrieval suggestion — violation: no query: correctly rejected"
fi

scenario "retrieval suggestion — violation: two suggestions same turn"
f="$SANDBOX/retrieval-two.md"
cat > "$f" <<'EOF'
Answer here.

Relevant memory not loaded: Router Enforcement Gap (ml-20260507-003) — say 'ml load router enforcement' to load
Relevant memory not loaded: SCRIPT Philosophy (ml-20260507-001) — say 'ml load SCRIPT' to load

-------------------------------------------------------------
Token Burned:
  - Last turn: ~40 words, ~52 est. tokens
  - Session: ~1,200 words, ~1,560 est. tokens

Next Step: Load the most relevant entry first.
--------------------------------------------------------------
EOF
if assert_single_retrieval_suggestion "$f" 2>/dev/null; then
  fail "retrieval suggestion — violation: two suggestions: should have been rejected"
else
  pass "retrieval suggestion — violation: two suggestions: correctly rejected"
fi

# ===========================================================================
# CONTRACT 4: TOKEN BURNED BLOCK
# ===========================================================================

scenario "token burned — happy path"
f="$SANDBOX/token-burned-valid.md"
cat > "$f" <<'EOF'
Answer here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~80 words, ~104 est. tokens
  - Session: ~2,400 words, ~3,120 est. tokens

Next Step: Run the test suite before pushing.
--------------------------------------------------------------
EOF
check "token burned block present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"
check "coming up only when needed" assert_coming_up_only_when_needed "$f"

scenario "token burned — coming up valid when ambiguity exists"
f="$SANDBOX/token-burned-coming-up.md"
cat > "$f" <<'EOF'
Answer here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~80 words, ~104 est. tokens
  - Session: ~2,400 words, ~3,120 est. tokens

Next Step: Update per-turn.md with load announcement contract (recommended)

Coming Up:
  - Update router.md to remove duplicate announcement rule
  - Add test-per-turn.sh to agent behavior tests
--------------------------------------------------------------
EOF
check "token burned block present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"
check "coming up has items" assert_coming_up_only_when_needed "$f"

scenario "token burned — violation: block missing"
f="$SANDBOX/token-burned-missing.md"
cat > "$f" <<'EOF'
Answer here. No status block appended.
EOF
if assert_has_token_burned_block "$f" 2>/dev/null; then
  fail "token burned — violation: missing block: should have been rejected"
else
  pass "token burned — violation: missing block: correctly rejected"
fi

scenario "token burned — violation: next step blank"
f="$SANDBOX/token-burned-blank-next.md"
cat > "$f" <<'EOF'
Answer here.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step:
--------------------------------------------------------------
EOF
if assert_next_step_not_blank "$f" 2>/dev/null; then
  fail "token burned — violation: blank next step: should have been rejected"
else
  pass "token burned — violation: blank next step: correctly rejected"
fi

scenario "token burned — violation: missing estimates"
f="$SANDBOX/token-burned-missing-estimates.md"
cat > "$f" <<'EOF'
Answer here.

-------------------------------------------------------------
Token Burned:
Next Step: Continue current task.
--------------------------------------------------------------
EOF
if assert_has_token_burned_block "$f" 2>/dev/null; then
  fail "token burned — violation: missing estimates: should have been rejected"
else
  pass "token burned — violation: missing estimates: correctly rejected"
fi

scenario "token burned — violation: coming up when single clear next step"
f="$SANDBOX/token-burned-spurious-coming-up.md"
# Mark as single-action context with a known marker
cat > "$f" <<'EOF'
Answer here. [SINGLE_ACTION]

-------------------------------------------------------------
Token Burned:
  - Last turn: ~30 words, ~39 est. tokens
  - Session: ~900 words, ~1,170 est. tokens

Next Step: Run tests.

Coming Up:
  - Push changes
--------------------------------------------------------------
EOF
if assert_no_coming_up_single_action "$f" "[SINGLE_ACTION]" 2>/dev/null; then
  fail "token burned — violation: spurious coming up: should have been rejected"
else
  pass "token burned — violation: spurious coming up: correctly rejected"
fi

# ===========================================================================
# DOGFOOD EDGE CASES
# ===========================================================================

scenario "dogfood — all three contracts in one valid turn"
f="$SANDBOX/dogfood-full-turn.md"
cat > "$f" <<'EOF'
Loaded: .mindlayer/knowledge/risks.md — risk concern detected in user message

The router enforcement gap is a known risk. The mitigation is the /m-script command in V4.

Memory candidate: /m-script as enforcement mitigation for router gap → risks.md — say 'save' or 'skip'

Relevant memory not loaded: SCRIPT Development Philosophy (ml-20260507-001) — say 'ml load SCRIPT' to load

-------------------------------------------------------------
Token Burned:
  - Last turn: ~90 words, ~117 est. tokens
  - Session: ~2,700 words, ~3,510 est. tokens

Next Step: Approve or skip the memory candidate above.
--------------------------------------------------------------
EOF
check "load announced" assert_has_load_announcement "$f"
check "load format valid" assert_load_announcement_format "$f"
check "memory candidate present" assert_has_memory_candidate "$f"
check "candidate has target" assert_memory_candidate_has_target "$f"
check "not adapter target" assert_memory_candidate_not_adapter "$f"
check "single candidate" assert_single_memory_candidate "$f"
check "retrieval suggestion present" assert_has_retrieval_suggestion "$f"
check "suggestion has query" assert_retrieval_suggestion_has_query "$f"
check "single suggestion" assert_single_retrieval_suggestion "$f"
check "token burned present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"

scenario "dogfood — session context warning at critical threshold"
f="$SANDBOX/dogfood-context-warning.md"
cat > "$f" <<'EOF'
Answer here.

Session context: critical (~85% used). Recommend: new session — say 'msession' for full report.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~40 words, ~52 est. tokens
  - Session: ~18,000 words, ~23,400 est. tokens

Next Step: Start a new session — save progress first with ml save.
--------------------------------------------------------------
EOF
check "token burned present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"
if grep -Fq "Session context: critical" "$f"; then
  pass "dogfood — session context warning: critical threshold triggers warning"
else
  fail "dogfood — session context warning: critical threshold triggers warning"
fi

scenario "dogfood — backlog empty triggers roadmap pull"
f="$SANDBOX/dogfood-backlog-empty.md"
cat > "$f" <<'EOF'
Task complete. All backlog items are done.

Backlog complete — next phase: V3 phase 3 (auto-summarization suggestions). Say 'pull next phase' to populate backlog.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~50 words, ~65 est. tokens
  - Session: ~3,000 words, ~3,900 est. tokens

Next Step: Say 'pull next phase' to start V3 phase 3, or review roadmap first.
--------------------------------------------------------------
EOF
check "token burned present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"
if grep -Fq "Backlog complete" "$f"; then
  pass "dogfood — backlog empty: roadmap pull surfaced"
else
  fail "dogfood — backlog empty: roadmap pull surfaced"
fi

scenario "dogfood — lateral intent routing fires correctly"
f="$SANDBOX/dogfood-lateral-intent.md"
cat > "$f" <<'EOF'
Here is the answer to your off-plan question.

Lateral intent: backlog candidate — say 'add to backlog' or 'add to roadmap' to capture, or I'll just proceed.

-------------------------------------------------------------
Token Burned:
  - Last turn: ~40 words, ~52 est. tokens
  - Session: ~1,200 words, ~1,560 est. tokens

Next Step: Continue with current backlog task.
--------------------------------------------------------------
EOF
check "token burned present" assert_has_token_burned_block "$f"
check "next step not blank" assert_next_step_not_blank "$f"
if grep -Fq "Lateral intent:" "$f"; then
  pass "dogfood — lateral intent: nudge surfaced"
else
  fail "dogfood — lateral intent: nudge surfaced"
fi

scenario "dogfood — violation: all contracts missing"
f="$SANDBOX/dogfood-all-missing.md"
cat > "$f" <<'EOF'
Here is the answer. Nothing else.
EOF
if assert_has_token_burned_block "$f" 2>/dev/null; then
  fail "dogfood — all contracts missing: token burned should fail"
else
  pass "dogfood — all contracts missing: token burned correctly rejected"
fi
if assert_has_load_announcement "$f" 2>/dev/null; then
  fail "dogfood — all contracts missing: no spurious load announcement"
else
  pass "dogfood — all contracts missing: no spurious load announcement"
fi
if assert_has_memory_candidate "$f" 2>/dev/null; then
  fail "dogfood — all contracts missing: no spurious memory candidate"
else
  pass "dogfood — all contracts missing: no spurious memory candidate"
fi

# ===========================================================================
# SUMMARY
# ===========================================================================

printf "\nMindLayer Per-Turn Contract Summary\n"
printf "Passed: %s\n" "$PASS_COUNT"
printf "Failed: %s\n" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf "Verdict: PER-TURN CONTRACT READY\n"
  exit 0
fi

printf "Verdict: PER-TURN CONTRACT FAILED\n"
exit 1
