---
name: mloop
description: Use Superpowers spec/plan workflow with Root-as-Planner plus Generator/Evaluator agents, spec review, dual plan review, independent evaluation, automatic repair loops, and evolution proposal. Use for non-trivial coding tasks, mloop/loop3e requests, multi-model workflows, independent evaluation, evidence-based acceptance, and evolution loops.
---

# Loop3E + Superpowers Workflow

Use this skill when the user asks for `mloop`, `loop3e`, multi-model development, independent evaluation, non-trivial implementation, bug fixes with validation, refactors with tests, or evidence-based acceptance.

Do not use it for trivial one-line edits, pure explanation, pure translation, or tasks unrelated to code/technical docs.

## Role Mapping

- Root Codex: owns conversation, clarification, spec drafting, acceptance criteria, gate routing, and final summary.
- Generator: `loop_generator`, model `MiniMax-M3`
- Evaluator: `loop_evaluator`, model `deepseek-v4-pro`, provider `loop3e_evaluator`

## Artifact Ownership

Superpowers owns long-lived assets:

- `docs/superpowers/specs/`
- `docs/superpowers/plans/`

Loop3E owns runtime artifacts under `.loop3e/`.

Do not create `.loop3e/spec.md` or `.loop3e/acceptance.md`; point to the Superpowers spec and plan instead.

## Required Runtime Files

Create `.loop3e/` only when a loop run starts. Use these files:

```text
.loop3e/current_spec.txt
.loop3e/current_plan.txt
.loop3e/spec_review.json
.loop3e/spec_review.md
.loop3e/plan_review.json
.loop3e/plan_review.md
.loop3e/current_batch.md
.loop3e/generator_report.md
.loop3e/verdict.json
.loop3e/evaluator_report.md
.loop3e/lessons.md
.loop3e/evolution_proposal.md
.loop3e/rule_update_proposal.md
.loop3e/regression_candidates.md
.loop3e/run_log.md
```

## Gate Policy

- `APPROVED`: continue.
- `REQUEST_CHANGES`: route back to the author role automatically.
- `SPEC_ISSUE`: route to Root for spec clarification or user question.
- `ASK_USER`: stop and ask the user.
- `STOP`: stop and summarize.
- `PASS`: enter Evolution Review.
- `FAIL`: route blocking findings back to Generator.

Ask the user only for business decisions, scope changes, compatibility decisions, destructive migrations, API breaks, security/permission/billing/data-consistency trade-offs, external credentials, production access, loop limit exceeded, or repeated role conflict.

## Root Checkpoints

After each gate, Root must emit a short user-visible checkpoint so the user has control without opening files.

Use this shape:

```text
<Phase>: <STATUS>
- artifact: <path>
- blocking: <none|count and short reason>
- next: <next action>
```

Keep normal checkpoint output under 6 lines. Expand only for `ASK_USER`, `STOP`, `FAIL`, or when the user asks for details.

## Superpowers Skill Map

- Root MUST invoke `superpowers:using-superpowers` at mloop start. This loads the Superpowers invocation discipline; it does not replace the phase gates below.
- Root MUST invoke `superpowers:brainstorming` before spec drafting.
- Generator MUST invoke `superpowers:writing-plans` before plan drafting.
- For approved plan execution, Generator MUST use either `superpowers:subagent-driven-development` or `superpowers:executing-plans`; choose the lighter fit for task shape and available subagents.
- Before any completion claim, Root MUST invoke `superpowers:verification-before-completion`.
- Use conditional Superpowers skills when their trigger applies: `superpowers:test-driven-development` for code behavior changes, `superpowers:systematic-debugging` for bugs/test failures/Evaluator `FAIL`, `superpowers:receiving-code-review` for review findings, `superpowers:requesting-code-review` for substantial code diffs that need an extra independent review, `superpowers:using-git-worktrees` when isolation is needed, and `superpowers:finishing-a-development-branch` only when the user asks to merge, PR, clean up, or discard.
- Consider `superpowers:dispatching-parallel-agents` only when there are 2+ independent problem domains and subagents will not edit the same files.

## Workflow

1. Root MUST invoke `superpowers:using-superpowers`.
2. Inspect git status and append safety notes to `.loop3e/run_log.md`.
3. Root MUST invoke `superpowers:brainstorming` before drafting a spec. Use it to explore context, ask one clarifying question at a time, present a short design, and get user approval.
4. After brainstorming approval, Root creates or updates `docs/superpowers/specs/YYYY-MM-DD-<feature>-design.md` and writes `.loop3e/current_spec.txt`.
5. Evaluator reviews spec verifiability; Generator reviews spec feasibility; Root writes `.loop3e/spec_review.json`.
6. Generator MUST invoke `superpowers:writing-plans` to create `docs/superpowers/plans/YYYY-MM-DD-<feature>-implementation.md` and write `.loop3e/current_plan.txt`.
7. Root reviews plan alignment; Evaluator reviews plan verifiability; Root writes `.loop3e/plan_review.json`.
8. Generator must read `.loop3e/plan_review.json` before implementation. Continue only when status is `APPROVED`; revise the plan on `REQUEST_CHANGES`; stop on `SPEC_ISSUE`, `ASK_USER`, or `STOP`.
9. Generator MUST use either `superpowers:subagent-driven-development` or `superpowers:executing-plans` to execute the approved plan.
10. Use conditional Superpowers skills when their trigger applies, especially debugging/TDD/review skills for code changes or failures.
11. Before any completion claim, Root MUST invoke `superpowers:verification-before-completion` and record fresh verification evidence.
12. Evaluator independently verifies implementation and writes `.loop3e/verdict.json` plus `.loop3e/evaluator_report.md`.
13. On `FAIL`, Generator fixes only `blocking_findings`; repeat up to 3 implementation/evaluation rounds.
14. On `PASS`, Root owns evolution aggregation. Generator and Evaluator may contribute evidence through reports, but Root produces `.loop3e/lessons.md`, `.loop3e/evolution_proposal.md`, `.loop3e/rule_update_proposal.md`, and `.loop3e/regression_candidates.md`.

Do not auto-commit, push, create PRs, update `AGENTS.md`, update skills, or solidify evolution proposals without explicit user approval.

## Final Response

Include summary, spec path, plan path, changed files, tests/checks run, evaluator verdict, remaining risks, evolution proposals, and whether human approval is needed. Do not claim success unless Evaluator returned `PASS`.
