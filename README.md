# full_auto – Automated GitHub Governance System

A complete GitHub governance system that enables automated software delivery piloting through GitHub Projects, Copilot Agents, and GitHub Actions.

## 🚀 What This Is

`full_auto` is a governance framework — not an application. It provides:

- **Structured workflow** from idea to production via GitHub Projects board
- **Automated refinement** via Copilot Refinement Agent (epic → sub-issues + dependencies)
- **Automated execution** via Copilot Execution Agent (sub-issues → branches + PRs)
- **Automated QA scaffolding** via QA Agent (structured review checklists)
- **Automated release** via Release Agent (merge + tracking + epic completion)
- **Guard rails** to prevent premature code work, wrong-phase PRs, and governance chaos

## 📋 Phase Flow

```
[PM] Draft → Refinement → Ready → [PM] Todo → In Progress → QA → [PM Approves] → Done
                ↑ Copilot           ↑ Copilot                 ↑ Copilot
```

## 📁 Quick Links

| Document | Description |
|----------|-------------|
| [System Overview](docs/governance/01-overview.md) | Architecture and components |
| [Workflow Guide](docs/governance/02-workflow.md) | Phase-by-phase workflow |
| [Agent Reference](docs/governance/03-agents.md) | What each agent does |
| [Setup Guide](docs/governance/04-setup.md) | How to configure the system |
| [Test Plan](docs/governance/05-testing.md) | End-to-end validation tests |
| [Conventions](docs/governance/06-conventions.md) | Naming and label conventions |

## ⚡ Quick Start

1. **Read** [Setup Guide](docs/governance/04-setup.md) and configure secrets + Projects board
2. **Run** the label initialization workflow: Actions → `01 – Setup Labels`
3. **Create** your first epic using the Epic issue template
4. **Move** it to Refinement in the Projects board
5. **Review** the refinement output and move to Todo when ready
6. **Watch** Copilot execute the sub-issues automatically

## 🔑 Required Secrets

| Secret | Description |
|--------|-------------|
| `GHP_TOKEN` | PAT with `repo`, `project`, `issues` scopes |
| `GH_PAT_TOKEN` | Alternative PAT (same scopes) |

## 📊 Projects Board Columns

`Backlog` → `Refinement` → `Ready` → `Todo` → `In Progress` → `QA` → `Release` → `Done`

## 🤖 Agents

| Agent | Triggered by | Does |
|-------|-------------|------|
| Refinement | `phase:refinement` on epic | Structures epic, creates sub-issues |
| Execution | `phase:todo` on sub-issue | Implements feature, opens PR |
| QA | PR ready for review | Posts review checklist |
| Release | PR approved | Merges, closes issues, tracks epic |
