# Token Strategy

MindLayer uses layered loading to keep context small and transparent.

## L0 Bootstrap

Load only operating rules and essential indexes:

- `~/.mindlayer/memory-system.md`
- `~/.mindlayer/index.md`
- project `.mindlayer/index.md`

## L1 Indexes and Summaries

Use compact index entries and section summaries to decide whether more context is needed.

Indexes should include title, file, section, scope, type, tags, summary, importance, status, and last updated date.
Indexes should stay short enough to route retrieval, not replace the files they point to.

## L2 Full Sections on Demand

Load full sections only when the task or query requires them. Cite the source file and section. Summarize large content instead of dumping whole files.

Do not load empty scaffold files or `.mindlayer/local.md` by default. Load them only when an index marks them as relevant, the user task needs them, or they contain non-placeholder content.

## Transparency

Agents should state what they loaded, what they skipped, and why.

## Budget Discipline

Token savings depend on active maintenance, not just index-first retrieval.

- Set soft budgets for important memory files and warn before they are full.
- When a file nears its limit, prompt the user to clean up, compress, merge, or archive before adding more.
- Roll up old progress into summaries instead of keeping every step active forever.
- Keep indexes compact enough that reading them does not become equivalent to reading the memory itself.
