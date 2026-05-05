# /m-session

Report current session context cost and recommend whether to continue, compact, or start a new session.

## Inspect

Estimate the following from the current session:

- Conversation history: words and estimated tokens
- MindLayer memory loaded this session: which files, estimated tokens
- Total session context: combined estimate
- Approximate context window usage as a percentage

When exact token counts are unavailable, estimate as words × 1.3 or characters ÷ 4. Mark estimates as approximate.

## Thresholds

- Light (< 30%): continue, no action needed
- Moderate (30–60%): note it, no action needed
- Heavy (60–80%): suggest compact or new session
- Critical (> 80%): strongly recommend new session or compact now

## Recommendation Logic

- Mid-task and heavy or critical → recommend `/compact`
- At task boundary and heavy or critical → recommend new session (MindLayer boot is cheap, restores context with zero history overhead)
- Light or moderate → continue

## Output

Return:

- Session context:
  - Conversation: ~N words, ~N est. tokens
  - MindLayer memory loaded: ~N words, ~N est. tokens
  - Total: ~N est. tokens (~N% of context window)
- Status: light | moderate | heavy | critical
- Recommendation: continue | compact | new session
- Reason:
