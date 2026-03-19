# Setup Guide

This guide walks through every step required to configure the `full_auto` governance system from scratch.

## Prerequisites

| Item | Required | Notes |
|------|----------|-------|
| GitHub repository | ✅ | `martial-repo/full_auto` |
| GitHub Copilot license | ✅ | Copilot for Business or Enterprise |
| GitHub Projects (v2) | ✅ | Create a new project linked to the repo |
| `GHP_TOKEN` secret | ✅ | Personal Access Token with repo, project, issues scopes |
| `GH_PAT_TOKEN` secret | ⚠️ Optional | Alternative PAT for specific workflows |
| Copilot coding agent enabled | ✅ | Enable in org/repo settings |

---

## Step 1 – Create the GitHub Project Board

1. Go to **github.com/martial-repo** → **Projects** → **New project**
2. Choose **Board** layout
3. Name it: `full_auto – Pilotage`
4. Create the following **Status** columns (in order):

| Column Name | Description |
|-------------|-------------|
| `Backlog` | Draft items not yet refined |
| `Refinement` | Under Copilot refinement |
| `Ready` | Refined, waiting for go signal |
| `Todo` | Approved for execution |
| `In Progress` | Being implemented |
| `QA` | Under validation |
| `Release` | Being deployed |
| `Done` | Completed |

5. **Important**: Column names must match exactly — they are used by the sync scripts.
6. Link the project to the `full_auto` repository:
   - Project settings → Manage access → Link repository

7. Note the **project number** from the URL: `https://github.com/orgs/martial-repo/projects/NUMBER`

---

## Step 2 – Configure Secrets and Variables

### Secrets (GitHub → Repository Settings → Secrets and variables → Actions → Secrets)

| Secret | Value | Description |
|--------|-------|-------------|
| `GHP_TOKEN` | PAT token | Token with `repo`, `project`, `issues`, `pull_requests` scopes |
| `GH_PAT_TOKEN` | PAT token | Alternative PAT (same scopes) |

> **Token permissions needed**:
> - `repo` (full repository access)
> - `read:org` (organization access)
> - `project` (Projects v2 access)

### Variables (GitHub → Repository Settings → Secrets and variables → Actions → Variables)

| Variable | Value | Description |
|----------|-------|-------------|
| `PROJECT_NUMBER` | `<number>` | The Projects board number from Step 1 |

To set via CLI:
```bash
gh variable set PROJECT_NUMBER --body "1" --repo martial-repo/full_auto
```

---

## Step 3 – Initialize Labels

Run the label setup workflow:

1. Go to **Actions** → **01 – Setup Labels**
2. Click **Run workflow**
3. Type `yes` in the confirmation field
4. Click **Run workflow**

Or run locally:
```bash
GH_TOKEN=<your-token> REPO=martial-repo/full_auto bash .github/scripts/create-labels.sh
```

This creates all labels defined in `.github/scripts/create-labels.sh`:
- `phase:*` labels (workflow states)
- `type:*` labels (artifact types)
- `priority:*` labels
- `complexity:*` labels
- `status:*` labels
- `agent:*` labels

---

## Step 4 – Enable Copilot Coding Agent

1. Go to **Organization Settings** → **Copilot** → **Coding agent**
2. Enable **Copilot coding agent** for the repository
3. Verify that `github-copilot[bot]` can be assigned to issues

---

## Step 5 – Enable Workflow Permissions

Go to **Repository Settings** → **Actions** → **General**:
- Set **Workflow permissions** to: `Read and write permissions`
- Enable: `Allow GitHub Actions to create and approve pull requests`

---

## Step 6 – Configure Branch Protection (Recommended)

Go to **Repository Settings** → **Branches** → **Add rule** for `main`:

- ✅ Require a pull request before merging
- ✅ Require approvals (minimum 1)
- ✅ Require status checks to pass: `pr-guard` (from workflow `04-pr-guard-rails.yml`)
- ✅ Dismiss stale PR approvals when new commits pushed
- ✅ Restrict who can push to matching branches (optional)

---

## Step 7 – Test the Setup

See `docs/governance/05-testing.md` for the full end-to-end test plan.

Quick smoke test:
1. Create a new issue using the **Epic** template
2. Add it to the Projects board
3. Add label `phase:refinement`
4. Verify workflow `02-refinement.yml` triggers
5. Verify a comment is posted on the issue

---

## Troubleshooting

### Labels not created
- Verify `GHP_TOKEN` secret has `repo` scope
- Check the Actions log for `01-setup-labels` workflow

### Projects sync not working
- Verify `PROJECT_NUMBER` variable is set correctly
- Verify `GHP_TOKEN` has `project` scope
- Check the script output in Actions logs

### Copilot not assigned
- GitHub Copilot coding agent must be enabled at org level
- The `app/github-copilot` assignee requires specific permissions
- Fallback: assign Copilot manually from the GitHub UI

### Workflow permissions error
- Go to Settings → Actions → General → enable read/write permissions

---

## Optional: Configure Automatic Projects Sync via Label Triggers

To automatically sync issues when labels change (instead of requiring manual board moves):

The `05-sync-projects.yml` workflow handles this automatically. When a label like `phase:todo` is applied to an issue, the issue's Projects board status is updated to `Todo`.

This means you can trigger phase transitions **either**:
- By moving items in the Projects board (requires the label to also be applied — set up via Projects automation rules), **or**
- By directly applying the label to the issue

To set up Projects automation rules (trigger label when column changes):
1. Open your project
2. Click the ⚡ icon on a column → **Add automation**
3. Select **Auto-add item** or create custom rules
4. Note: GitHub Projects automation for label application is available in Enterprise plans
