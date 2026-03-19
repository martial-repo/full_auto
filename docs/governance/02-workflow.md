# Workflow – Detailed Phase Guide

## Phase 1: Draft (Backlog)

**Trigger**: PM creates an epic via the Epic issue template.

**Labels applied**: `type:epic`, `phase:draft`

**What happens**:
- Epic is created as a structured form in GitHub Issues
- It appears in the Projects board under **Backlog**
- No automation runs
- PM can edit and refine the draft manually at any time

**Human action required**: Review the draft and move it to **Refinement** when ready.

---

## Phase 2: Refinement

**Trigger**: PM adds label `phase:refinement` to the epic (or moves it to **Refinement** in Projects board, which triggers the same label).

**Workflow**: `02-refinement.yml`

**Guard rails**:
- Only `type:epic` issues can enter refinement
- Non-epic issues with `phase:refinement` label are rejected with a comment

**What the Refinement Agent does**:
1. Reads the full epic body
2. Rewrites the epic with a complete structured format
3. Creates sub-issues (one per atomic deliverable)
4. Maps dependencies between sub-issues
5. Assigns priorities and defines execution order
6. Posts a refinement summary comment on the epic
7. Applies `phase:ready` to the epic

**Duration**: Minutes to hours depending on epic complexity.

**Output**:
- Fully structured epic with acceptance criteria
- Sub-issues created with `type:sub-issue`, `phase:draft`
- Dependency map documented
- Recommended execution order defined

---

## Phase 3: Ready

**Trigger**: Refinement Agent applies `phase:ready` to the epic.

**What happens**:
- Projects board shows the epic as **Ready**
- Sub-issues are created but not yet activated
- No code work begins

**Human action required**: Review the refinement output:
- Are the sub-issues correct?
- Is the dependency map accurate?
- Is the priority order right?
- Move the epic to **Todo** when satisfied.

---

## Phase 4: Todo

**Trigger**: PM adds label `phase:todo` to the epic (or moves it to **Todo** in Projects board).

**Workflow**: `03-execution.yml`

**What happens**:
1. Workflow scans all sub-issues referencing the epic
2. Sub-issues with no blocking dependencies are activated: `phase:draft` → `phase:todo`
3. Blocked sub-issues remain in `phase:draft` with `status:blocked`
4. Each activated sub-issue triggers the execution pipeline

---

## Phase 5: In Progress

**Trigger**: Execution pipeline activates a sub-issue (`phase:todo` → `phase:in-progress`).

**What the Execution Agent does**:
1. Verifies parent epic status and dependencies
2. Creates branch `feature/<issue-number>-<slug>`
3. Implements the feature per acceptance criteria
4. Writes/updates tests
5. Opens a PR referencing the sub-issue
6. Applies `phase:qa` to the sub-issue

**Guard rails**:
- Agent cannot start execution if blockers are unresolved
- Branch naming convention is enforced
- PR must reference a valid issue

---

## Phase 6: QA

**Trigger**: Sub-issue receives `phase:qa` label (applied by Execution Agent when PR is opened).

**Workflow**: `04-pr-guard-rails.yml`

**What the QA Agent does**:
1. Posts a structured QA checklist on the PR
2. Summarizes acceptance criteria from the linked sub-issue
3. Highlights scope and security points

**Human action required**:
- Review the QA checklist
- Check the CI results (tests, linting)
- Either:
  - ✅ **Approve** the PR → triggers release pipeline
  - ❌ **Request changes** → sub-issue moves back to `phase:in-progress`

---

## Phase 7: Release

**Trigger**: PR is approved by human reviewer.

**Workflow**: `06-release.yml`

**What the Release Agent does**:
1. Merges the PR (squash merge for sub-issues)
2. Deletes the feature branch
3. Closes the sub-issue with `phase:done`
4. Checks if the parent epic is now complete
5. If complete: closes the epic with `phase:done`
6. If not: posts a progress update on the epic and activates newly unblocked sub-issues

---

## Phase 8: Done

**Trigger**: Release Agent applies `phase:done` and closes the issue.

**What happens**:
- Sub-issue is closed
- Projects board updated to **Done**
- Parent epic is checked for completion
- If all sub-issues done: epic is also closed and marked **Done**

---

## Label Transition Map

```
Draft ──(phase:refinement)──→ Refinement
Refinement ──(agent done)──→ Ready
Ready ──(phase:todo)──→ Todo
Todo ──(dep check pass)──→ In Progress
In Progress ──(PR opened)──→ QA
QA ──(approved)──→ Release
Release ──(merged)──→ Done
QA ──(changes requested)──→ In Progress (loop back)
```

## Error / Exception Flows

| Situation | What happens |
|-----------|-------------|
| `phase:refinement` on non-epic | Guard removes label, posts error comment |
| PR opened without linked issue | PR guard fails CI, posts error comment |
| PR opened for `phase:draft` issue | PR guard fails CI, posts error comment |
| Execution starts but blocker unresolved | Script posts blocked comment, adds `status:blocked` |
| PR changes requested by reviewer | Sub-issue moved back to `phase:in-progress` |
| Projects sync fails (no PROJECT_NUMBER) | Graceful skip with warning in workflow logs |
