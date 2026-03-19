# Agents – Reference Guide

## Overview

The governance system uses four specialized Copilot agents, each activated at a specific phase of the workflow. Each agent has a dedicated instruction file in `.github/agents/`.

## Agent Summary

| Agent | Instruction File | Activation |
|-------|-----------------|------------|
| Refinement Agent | `.github/agents/refinement-agent.md` | `phase:refinement` label on `type:epic` |
| Execution Agent | `.github/agents/execution-agent.md` | `phase:todo` label on `type:sub-issue` |
| QA Agent | `.github/agents/qa-agent.md` | PR marked ready for review with `phase:qa` |
| Release Agent | `.github/agents/release-agent.md` | PR approved by human reviewer |

---

## Refinement Agent

**File**: `.github/agents/refinement-agent.md`

**Purpose**: Transform a rough epic idea into a fully structured, executable backlog item.

**Input**: Epic issue in `phase:refinement`

**Output**:
- Rewritten epic body with complete structure
- Sub-issues with acceptance criteria
- Dependency map
- Execution order recommendation
- `phase:ready` applied to epic

**Key behaviors**:
- Stops and asks for clarification if critical info is missing
- Creates sub-issues atomically (1-3 days each)
- Never starts coding
- Posts explicit `🔴 HUMAN ACTION REQUIRED` when human input is needed

**Invocation**: Automatically assigned by `02-refinement.yml` workflow

---

## Execution Agent

**File**: `.github/agents/execution-agent.md`

**Purpose**: Implement a sub-issue following acceptance criteria.

**Input**: Sub-issue in `phase:in-progress`

**Output**:
- Feature branch `feature/<N>-<slug>`
- Implementation code
- Tests
- PR opened against `main`
- Sub-issue moved to `phase:qa`

**Key behaviors**:
- Checks parent epic status before starting
- Verifies all blocking dependencies are `phase:done`
- Uses Conventional Commits
- Never merges its own PRs
- Self-validates against acceptance criteria before opening PR

**Invocation**: Assigned via `03-execution.yml` workflow when sub-issue gets `phase:todo`

---

## QA Agent

**File**: `.github/agents/qa-agent.md`

**Purpose**: Structure the QA review for human reviewers.

**Input**: PR with `phase:qa` label

**Output**:
- Structured QA checklist comment on the PR
- Clear human action request

**Key behaviors**:
- Never approves PRs
- Never merges PRs
- Only assists the human reviewer
- Posts structured checklist with acceptance criteria cross-check

**Invocation**: `04-pr-guard-rails.yml` workflow when PR is marked ready for review

---

## Release Agent

**File**: `.github/agents/release-agent.md`

**Purpose**: Finalize delivery after human QA approval.

**Input**: PR approved by human reviewer

**Output**:
- PR merged
- Feature branch deleted
- Sub-issue closed as `phase:done`
- Epic progress updated
- Epic closed if all sub-issues done

**Key behaviors**:
- Never merges without human approval
- Never merges with failing CI checks
- Activates newly unblocked sub-issues after each merge
- Posts progress updates on the parent epic

**Invocation**: `06-release.yml` workflow on PR close (merged)

---

## Agent Communication Conventions

Agents use a standard comment format to communicate their actions and status.

### Markers

| Marker | Meaning |
|--------|---------|
| `✅ AUTOMATED STEP COMPLETE` | Agent finished a step successfully |
| `🔴 HUMAN ACTION REQUIRED` | Human must take action before automation can continue |
| `⚠️ Guard Rail` | Safety check triggered, prevented incorrect action |
| `📊` | Progress report or status update |
| `🤖` | Agent introduction or activation notice |

### Comment Structure

Every agent comment follows this structure:

```markdown
## [MARKER] [Agent Name] – [Short Title]

[Brief explanation of what happened or what is needed]

### [Section if needed]
[Details]

### Next Step (if applicable)
[What should happen next]
```

---

## Global Copilot Rules

Defined in `.github/copilot-instructions.md`. All agents must follow:

1. Never write code for issues outside `phase:in-progress`
2. Never create PRs for issues outside the execution phase
3. Always read labels before acting
4. Respect the dependency order
5. Never merge their own PRs
6. Use clear communication markers in comments
