# Conventions – Reference

## Issue Naming Conventions

| Type | Format | Example |
|------|--------|---------|
| Epic | `[EPIC] <Short title>` | `[EPIC] User Authentication System` |
| Sub-issue | `[EPIC-<N>] <Verb> <noun>` | `[EPIC-10] Implement OAuth callback endpoint` |
| Bug | `[BUG] <Short description>` | `[BUG] Login fails with Google OAuth on mobile` |
| Spike | `[SPIKE] <Research topic>` | `[SPIKE] Evaluate session storage options` |

## Branch Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Feature (sub-issue) | `feature/<issue-number>-<slug>` | `feature/42-oauth-callback` |
| Epic branch | `epic/<issue-number>-<slug>` | `epic/10-user-authentication` |
| Bug fix | `fix/<issue-number>-<slug>` | `fix/55-mobile-login-crash` |
| Chore | `chore/<issue-number>-<slug>` | `chore/60-update-dependencies` |
| Documentation | `docs/<issue-number>-<slug>` | `docs/61-api-documentation` |
| Spike | `spike/<issue-number>-<slug>` | `spike/62-session-storage` |

**Slug rules**:
- Lowercase only
- Hyphens for spaces
- Maximum 30 characters
- No special characters

## Commit Message Conventions

Format: `<type>(<scope>): <description> (#<issue-number>)`

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `test` | Adding or updating tests |
| `docs` | Documentation changes |
| `refactor` | Code refactoring (no behavior change) |
| `chore` | Tooling, dependencies, CI |
| `style` | Formatting, no logic change |
| `perf` | Performance improvements |

**Examples**:
```
feat(auth): add GitHub OAuth callback endpoint (#42)
fix(auth): handle null token in session middleware (#55)
test(auth): add unit tests for OAuth flow (#42)
docs(api): update authentication endpoint documentation (#42)
chore(deps): update oauth library to v3.1.0 (#60)
```

## Label Conventions

### Phase Labels (one active at a time per issue)

Labels follow the pattern `phase:<state>`. An issue should have **exactly one** phase label at any time.

| Label | Color | Description |
|-------|-------|-------------|
| `phase:draft` | Light blue | Initial draft |
| `phase:refinement` | Medium blue | Under refinement |
| `phase:ready` | Green | Ready to execute |
| `phase:todo` | Yellow | Execution approved |
| `phase:in-progress` | Orange | Being implemented |
| `phase:qa` | Light yellow | Under QA review |
| `phase:release` | Purple | Being released |
| `phase:done` | Blue | Completed |

### Type Labels (permanent, define artifact type)

| Label | Description |
|-------|-------------|
| `type:epic` | High-level epic |
| `type:sub-issue` | Atomic sub-task |
| `type:bug` | Bug report |
| `type:chore` | Maintenance task |
| `type:docs` | Documentation |
| `type:spike` | Research/investigation |

### Priority Labels (one per issue)

| Label | Usage |
|-------|-------|
| `priority:critical` | Blocks everything, must be resolved immediately |
| `priority:high` | Important, should be in current sprint |
| `priority:medium` | Normal priority |
| `priority:low` | Nice to have, can be deferred |

### Complexity Labels (set during refinement)

| Label | Estimate |
|-------|----------|
| `complexity:xs` | < 2 hours |
| `complexity:s` | 2-4 hours |
| `complexity:m` | 4-8 hours |
| `complexity:l` | 1-2 days |
| `complexity:xl` | > 2 days |

## PR Conventions

### Title Format
`[#<issue-number>] <Short description of change>`

Examples:
- `[#42] Add OAuth callback endpoint`
- `[#55] Fix mobile login crash`

### Body Requirements
- Must include `Closes #<issue-number>` for the linked sub-issue
- Must include `Part of #<epic-number>` for the parent epic
- Must fill in the PR template checklist

### Labels
A PR should have:
- One phase label: `phase:qa` (when ready for review), `phase:done` (when merged)
- One type label matching the linked issue type

## Projects Board Conventions

| Column | Purpose | Items |
|--------|---------|-------|
| **Backlog** | Draft items | Epics in `phase:draft` |
| **Refinement** | Under refinement | Epics in `phase:refinement` |
| **Ready** | Waiting for execution go | Epics in `phase:ready` |
| **Todo** | Approved for execution | Epics in `phase:todo` |
| **In Progress** | Being developed | Epics + sub-issues in `phase:in-progress` |
| **QA** | Under validation | Sub-issues in `phase:qa`, PRs |
| **Release** | Being deployed | Items in `phase:release` |
| **Done** | Completed | Closed items |

**Important**: The Projects board columns must be named exactly as above for the sync scripts to work.

## Communication Conventions

### In Issues and PRs

| Marker | Meaning |
|--------|---------|
| `✅ AUTOMATED STEP COMPLETE` | Agent successfully completed a step |
| `🔴 HUMAN ACTION REQUIRED` | Human must act before automation continues |
| `⚠️ Guard Rail` | Safety check triggered |
| `📊` | Status report / progress update |
| `🤖` | Agent introduction |

### Decision Points (HUMAN ACTION REQUIRED)

When an agent posts `🔴 HUMAN ACTION REQUIRED`, a human must:
1. Read the agent's comment
2. Take the specified action
3. Automation will resume automatically

Never skip these prompts — they exist because the automation needs information or approval that cannot be determined automatically.
