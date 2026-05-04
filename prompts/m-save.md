# /m-save

Analyze recent work and propose MindLayer memory writes. Do not write without literal explicit approval.

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

When working inside the MindLayer repo, follow the repo source-of-truth boundaries:

- Do not write product learnings to the live `~/.mindlayer/` folder.
- Do not write product learnings into `project-template` placeholders.
- Use repo `.mindlayer/` for MindLayer product improvement memory.
- Use `global-template` only when intentionally changing default global behavior that should ship to MindLayer users.
- Update prompts or adapters when a saved product rule must become operational command behavior.

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
- Approval needed:
```

Then ask for approval before writing.

## Approval Rule

Approval must be clear and literal before editing durable memory or memory behavior. `approve`, `approved`, `go ahead`, or an equally explicit instruction counts. Acknowledgments or vague instructions such as `ok`, `got it`, `sounds good`, or `we need to save this` do not count as approval.

If approval is unclear, do not write. Keep the proposed write visible as pending and ask for explicit approval.

If approved, make only the approved changes and update the appropriate index compactly.

## Pending Writes

If a memory write has been proposed but not approved:

- keep it visible as pending in the next `/m-save` or related response
- remind the user before moving to unrelated memory work
- do not treat later acknowledgments as retroactive approval
- include the pending destination, action, duplicate check, and confidence in status or handoff output when relevant
