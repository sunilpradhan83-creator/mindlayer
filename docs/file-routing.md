# File Routing

Use the narrowest durable destination.

## Global Files

- `memory-system.md`: MindLayer operating rules.
- `index.md`: compact search map for global memory.
- `preferences.md`: always-loaded cross-project user preferences and constraints.
- `playbook.md`: reusable workflows.
- `principles.md`: stable engineering and product beliefs.
- `anti-patterns.md`: mistakes and behaviors to avoid.
- `prompts.md`: reusable prompt templates.

## Project Files

- `project.md`: stable project identity, goals, users, stack, architecture, and core modules.
- `progress.md`: current phase, completed work, active work, and next step.
- `decisions.md`: project-specific decisions and rationale.
- `context.md`: technical and domain context.
- `backlog.md`: future tasks.
- `risks.md`: known risks, blockers, and fragile areas.
- `index.md`: compact search map for project memory.
- `local.md`: personal local notes ignored by Git.

Global memory does not need a mirrored project file. Read and write it directly from `~/.mindlayer/`.

## Rule of Thumb

If it applies across projects, route it global. If it only makes sense in this repository, route it project.
