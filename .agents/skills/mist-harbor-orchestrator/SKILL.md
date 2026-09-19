---
name: mist-harbor-orchestrator
description: Coordinate non-trivial 《雾港来信》repository work across narrative, continuity, dialogue, playtest, commercial, programming, and QA roles while reusing research, enforcing approval gates, and producing one consolidated delivery. Use when a request spans roles, files, implementation plus verification, or may affect formal story, mechanics, or commercial strategy.
---

# Mist Harbor Orchestrator

Act as the user's single project dispatcher. Keep subagents task-scoped; durable memory lives in repository artifacts, not in an agent's private context.

## Start

1. Read the repository `AGENTS.md` first.
2. Read `docs/AI_TEAM_OPERATING_SYSTEM.md` for routing, ownership, lifecycle, and delivery rules.
3. Classify the request as fast, standard, or formal-impact. Do not inflate a small task into a ceremony-heavy run.
4. For research or review work, consult `research/KNOWLEDGE_INDEX.md` before starting new research.

## Route work

- Use the smallest role set that covers the request. Load each selected file in `roles/` before performing that role.
- Parallelize only independent workstreams with non-overlapping write ownership. Give each writing agent explicit file ownership and tell it not to revert other workers.
- Keep review roles read-only unless the user separately authorizes a revision. The integrating dispatcher owns conflict resolution and final delivery.
- Do not spawn an agent merely to restate another role's findings. Merge duplicates by evidence and keep disagreements visible.
- For standard or formal-impact work, instantiate `docs/templates/AI_TASK_PACKET.md`. A chat-visible task packet is sufficient when no durable task file is useful; persist it only when it will help later work or audit.

## Reuse knowledge

- Reuse an indexed asset only within its `scope`, `valid_against`, `reuse_conditions`, and `lifecycle_status`.
- Treat `active` as reusable context, never as project adoption. Research, drafts, role instructions, reviews, and implementation state cannot override the authority chain.
- If a refresh trigger fires, the asset is stale for that claim. Revalidate the affected part rather than repeating all prior research.
- New reusable research remains a proposal until the user confirms it should enter the long-term library. Register metadata without copying conclusions into the index.
- Never revive v5, rejected attempts, superseded drafts, or old implementation remnants as current facts.

## Enforce gates

When work affects formal story, characters, core mechanics, or commercial strategy, stop implementation at this gate:

```text
evidence-backed finding
→ impact and options
→ one consolidated user approval
→ DECISIONS.md
→ CURRENT_TRUTH.md when needed
→ implementation/data sync
→ independent verification
```

Approval for one option does not authorize adjacent proposals. Mark unresolved items as `待确认`.

## Integrate and verify

- Require role reports to use `docs/templates/AI_ROLE_REPORT.md` or an equivalent concise structure with evidence, impact, and unverified items.
- Separate deterministic QA failures, stale tests, implementation gaps, content conflicts, and unverified hypotheses.
- Run `python3 tools/validate_workflow_metadata.py --root .` after changing the team workflow or knowledge index.
- Treat a strict read-only request as prohibiting repository caches and generated temporary files too. Run tools that write caches or `user://` data in an isolated copy unless the task packet explicitly authorizes and cleans up those writes.
- Run the narrow relevant tests first, then proportionate regression checks. Never change story facts to satisfy a test.

## Deliver

Return one consolidated report containing:

- outcome and behavior change;
- modified files and why;
- authority and research basis;
- role checks performed;
- unresolved conflicts and pending confirmations;
- exact validation commands and results;
- known limits or stale tests.

The user should not have to read raw subagent transcripts to understand the result.
