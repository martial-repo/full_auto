# Test Plan – End-to-End Governance System

This document describes how to validate that the governance system is working correctly from end to end.

## Prerequisites

Complete the setup in `docs/governance/04-setup.md` before running these tests.

---

## Test 1 – Label Initialization

**Objective**: Verify all labels are created correctly.

**Steps**:
1. Go to **Actions** → **01 – Setup Labels** → **Run workflow** → type `yes`
2. After completion, go to **Issues** → **Labels**

**Expected result**:
- All phase labels exist: `phase:draft`, `phase:refinement`, `phase:ready`, `phase:todo`, `phase:in-progress`, `phase:qa`, `phase:release`, `phase:done`
- All type labels exist: `type:epic`, `type:sub-issue`, `type:bug`, `type:chore`, `type:docs`, `type:spike`
- Priority, complexity, status, and agent labels exist

**Pass criteria**: All labels visible with correct colors and descriptions.

---

## Test 2 – Epic Draft Creation

**Objective**: Verify epic template works and creates issue with correct labels.

**Steps**:
1. Go to **Issues** → **New issue** → **🚀 Epic**
2. Fill in:
   - Objective: `Test epic for governance validation`
   - Context: `This is a test epic to validate the governance system`
   - Acceptance Criteria: `[ ] The governance system processes this epic correctly`
   - Priority: `Medium`
3. Submit

**Expected result**:
- Issue created with labels: `type:epic`, `phase:draft`
- Issue appears in Projects board under **Backlog**

**Pass criteria**: Issue has correct labels.

---

## Test 3 – Refinement Pipeline

**Objective**: Verify the refinement workflow triggers correctly.

**Steps**:
1. Take the epic created in Test 2
2. Add label `phase:refinement`
3. Wait 30-60 seconds

**Expected result**:
- Workflow `02-refinement.yml` triggered
- A comment is posted on the epic: `🤖 Refinement Agent – Activated`
- Copilot is assigned to the issue (or a note explains manual assignment)

**Pass criteria**: Comment posted on the issue.

**Negative test**: Apply `phase:refinement` to a non-epic issue → Guard should reject it and post an error comment.

---

## Test 4 – Guard Rail – Non-Epic Refinement

**Objective**: Verify guard rails block incorrect behavior.

**Steps**:
1. Create a regular issue (not using epic template)
2. Add label `phase:refinement`
3. Wait 30 seconds

**Expected result**:
- Workflow runs
- Comment posted explaining the guard rail
- Label `phase:refinement` is removed

**Pass criteria**: Label removed, error comment posted.

---

## Test 5 – Manual Refinement Simulation

Since Copilot refinement requires human review in the full flow, simulate the output:

**Steps**:
1. On the test epic (Test 2), manually:
   - Edit the epic body to add structured sections
   - Create 2-3 sub-issues using the **Sub-issue** template
   - Add `Part of #<epic-number>` to each sub-issue body
   - Add labels: `type:sub-issue`, `phase:draft`
   - Add `Blocked by: #<sub-issue-1>` to sub-issue 3
2. Add label `phase:ready` to the epic
3. Remove `phase:refinement` from the epic

**Expected result**:
- Epic has label `phase:ready`
- Sub-issues are created
- Projects board shows epic as **Ready**

---

## Test 6 – Execution Pipeline – Epic to Todo

**Objective**: Verify execution pipeline activates unblocked sub-issues.

**Steps**:
1. Add label `phase:todo` to the epic from Test 5

**Expected result**:
- Workflow `03-execution.yml` triggers
- Sub-issues without dependencies: moved to `phase:todo`
- Sub-issue 3 (blocked): receives `status:blocked`, stays in `phase:draft`
- Comment posted on epic: `✅ AUTOMATED STEP COMPLETE – Execution Started`

**Pass criteria**: Correct sub-issues activated, blocked ones correctly flagged.

---

## Test 7 – Execution Pipeline – Sub-issue Activation

**Objective**: Verify an unblocked sub-issue is assigned for execution.

**Steps**:
1. Observe a sub-issue that received `phase:todo` in Test 6
2. Wait for `03-execution.yml` to process it

**Expected result**:
- Sub-issue receives `phase:in-progress`
- Comment posted: `✅ AUTOMATED STEP COMPLETE – Execution Assigned`
- Copilot assigned (or note about manual assignment)

---

## Test 8 – PR Guard Rails

**Objective**: Verify PRs without linked issues are blocked.

**Steps**:
1. Create a branch `test/no-linked-issue`
2. Make a trivial change (e.g., add a comment)
3. Open a PR with a body that does NOT contain `Closes #NNN`

**Expected result**:
- Workflow `04-pr-guard-rails.yml` triggers
- Comment posted on PR explaining the guard
- PR check fails

**Pass criteria**: CI check fails with guard rail message.

---

## Test 9 – PR Guard Rails – Wrong Phase

**Objective**: Verify PRs for draft issues are blocked.

**Steps**:
1. Create a new sub-issue with `phase:draft`
2. Create a branch and open a PR with `Closes #<that-draft-issue-number>`

**Expected result**:
- Guard rail triggers
- Comment explains the issue is not in execution phase
- CI fails

---

## Test 10 – Full End-to-End Flow

**Objective**: Complete a full cycle from draft to done.

**Steps**:
1. Create an epic (Test 2)
2. Move to Refinement (Test 3)
3. Manually create one sub-issue (simulating Copilot output)
4. Move epic to Ready, then Todo (Test 6)
5. Let sub-issue activate (Test 7)
6. Manually create a PR with correct branch name `feature/<N>-test-flow`, `Closes #<sub-issue>`
7. Mark PR as ready for review
8. Verify QA checklist is posted (Test: QA Agent)
9. Approve the PR
10. Verify PR is merged (if auto-merge enabled)
11. Verify sub-issue is closed with `phase:done`
12. Verify epic shows progress update

**Pass criteria**: All steps complete without errors, issue flow matches expected labels.

---

## Regression Tests After Configuration Changes

After any change to workflows or scripts, rerun:
- Test 3 (refinement trigger)
- Test 4 (guard rails)
- Test 8 (PR guard)

These are the most fragile areas of the system.

---

## Known Limitations

| Limitation | Impact | Workaround |
|------------|--------|-----------|
| `app/github-copilot` assignment may not work via CLI | Copilot not auto-assigned | Assign manually in GitHub UI |
| Projects automation for labels requires Enterprise plan | Label sync is one-way (issue → project) | Apply labels manually on issues |
| Refinement agent creates a structured output but may need human review | Quality varies | Always review before moving to Ready |
| No AI model integration for refinement (uses `gh` CLI + templates) | Refinement is scaffolded, not AI-generated | Use Copilot coding agent via GitHub UI |
