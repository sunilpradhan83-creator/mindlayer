# /m-save

Analyze recent work and propose MindLayer memory writes. Do not write without explicit approval.

## Inspect

Consider:

- recent conversation or session context
- current user instruction
- diffs and touched files
- existing global and project indexes
- existing relevant memory sections

## Detect

Look for durable:

- preferences
- decisions
- constraints
- reusable patterns
- anti-patterns
- progress updates
- backlog items
- risks
- technical or domain context

Ignore transient chat, raw logs, and details that will not help future work.

## Classify and Route

Classify each candidate by:

- scope: `global` or `project`
- type: `preference`, `playbook`, `principle`, `anti-pattern`, `decision`, `context`, `progress`, `backlog`, or `risk`
- destination file
- action: `create`, `update`, or `skip`

Use global memory for cross-project preferences and reusable workflows. Use project memory for project identity, progress, decisions, context, backlog, and risks.

## Duplicate Check

Search indexes first, then relevant files. Prefer update over create when a memory already exists.

## Proposal Format

For each candidate, show:

```text
Memory Candidate:
- Title:
- Content:
- Scope:
- Type:
- Destination:
- Action: create | update | skip
- Reason:
- Duplicate check:
- Confidence:
```

Then ask for approval before writing. If approved, make only the approved changes and update the appropriate index compactly.

