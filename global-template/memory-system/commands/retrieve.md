# ml retrieve

<!-- managed by MindLayer installer — last_updated: YYYY-MM-DD -->

Fetch specific MindLayer memory for the query provided by the user.

Usage:

```text
ml retrieve <query>
```

## Procedure

1. Treat the text after `ml retrieve` as the query.
2. Search indexes first:
   - `~/.mindlayer/preferences/index.md`
   - project `.mindlayer/index.md`
3. Match by title, tags, summary, type, status, importance, and last updated date.
4. Load only relevant sections from the destination files.
5. Cite the source file and section for each retrieved item.
6. If content is large, summarize it instead of dumping the full text.
7. If no match is found, say so and suggest narrower queries or relevant files to inspect.

## Output

Return:

- Query:
- Matches:
- Retrieved context:
- Sources:
- Skipped:

Do not load or print entire memory files unless explicitly necessary.
