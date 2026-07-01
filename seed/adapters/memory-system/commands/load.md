# ml load

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Fetch specific MindLayer memory for the query provided by the user.

Usage:

```text
ml load <query>
```

Alias: `ml retrieve <query>` remains supported for backward compatibility.

## Procedure

1. Treat the text after `ml load` or `ml retrieve` as the query.
2. Search indexes first:
   - `~/.mindlayer/preferences/index.md`
   - project `.mindlayer/index.md`
3. Score every index entry deterministically. Do not use ML, embeddings, or a new storage layer.
4. Sort by score, then by `last_updated` descending when scores tie.
5. Load only relevant sections from the destination files.
6. Cite the source file and section for each loaded item.
7. If content is large, summarize it instead of dumping the full text.
8. If no match is found, say so and suggest narrower queries or relevant files to inspect.

## Ranking

Score index entries using this additive model:

| Signal | Points |
|---|---:|
| Exact title phrase match | +50 |
| Partial title keyword match | +25 |
| Tag match | +20 each |
| Summary keyword match | +10 each |
| Type or status match | +5 each |
| Importance: high | +10 |
| Importance: medium | +5 |
| Importance: low | +0 |
| Recent update within 30 days | +5 |
| Recent update within 90 days | +2 |

Archived entries:
- Skip archived entries unless the query explicitly includes archived, archive, old, historical, history, retired, or completed.
- When archived entries are explicitly requested, include them in ranking but subtract 10 points so active entries still win when equally relevant.

Tie-breakers:
1. Higher score wins.
2. Newer `last_updated` wins.
3. Higher importance wins.
4. Stable index order wins.

## Output

Return:

- Query:
- Matches:
- Ranking:
  ```text
  1. <title> (<id>) — score <N> — <why matched>
  ```
- Retrieved context:
- Sources:
- Skipped:

Do not load or print entire memory files unless explicitly necessary.
