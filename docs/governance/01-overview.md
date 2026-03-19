# full_auto – Governance System Overview

## 🎯 Purpose

This document describes the automated governance system for the `full_auto` repository. The system enables a **Product Owner / PM** to pilot high-level work from GitHub Projects while **Copilot Agents** handle refinement, execution, QA, and release automatically.

## 🏗️ Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Projects Board                        │
│  Backlog → Refinement → Ready → Todo → In Progress → QA → Done  │
└────────────────────────┬────────────────────────────────────────┘
                         │ label changes trigger
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                   GitHub Actions Workflows                        │
│  01-setup-labels  │ 02-refinement │ 03-execution │ 04-guard-rails│
│  05-sync-projects │ 06-release                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │ invoke
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Copilot Agents                                 │
│   Refinement Agent │ Execution Agent │ QA Agent │ Release Agent  │
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Phase Flow

```
[PM creates Epic draft]
        │
        ▼
  phase:draft (Backlog)
        │
        │ PM moves to Refinement
        ▼
  phase:refinement ──→ Refinement Agent activated
        │                ├── Rewrites epic body
        │                ├── Creates sub-issues
        │                └── Maps dependencies
        ▼
  phase:ready (Ready to Go)
        │
        │ PM approves and moves to Todo
        ▼
  phase:todo ──→ Execution pipeline activated
        │          └── Sub-issues activated in dependency order
        ▼
  phase:in-progress ──→ Copilot implements sub-issues
        │                  └── PRs created automatically
        ▼
  phase:qa ──→ QA Agent posts checklist
        │        └── PM/Reviewer validates
        ▼
  phase:done ──→ Release Agent merges, epic completed
```

## 📁 Repository Structure

```
.github/
├── copilot-instructions.md          # Global Copilot rules
├── agents/
│   ├── refinement-agent.md          # Refinement Agent instructions
│   ├── execution-agent.md           # Execution Agent instructions
│   ├── qa-agent.md                  # QA Agent instructions
│   └── release-agent.md             # Release Agent instructions
├── ISSUE_TEMPLATE/
│   ├── config.yml                   # Template config
│   ├── epic.yml                     # Epic template
│   ├── sub-issue.yml                # Sub-issue template
│   └── bug_report.yml               # Bug report template
├── PULL_REQUEST_TEMPLATE.md         # PR template
├── workflows/
│   ├── 01-setup-labels.yml          # Initialize labels (manual)
│   ├── 02-refinement.yml            # Refinement pipeline
│   ├── 03-execution.yml             # Execution pipeline
│   ├── 04-pr-guard-rails.yml        # PR safety checks
│   ├── 05-sync-projects.yml         # Projects board sync
│   └── 06-release.yml               # Release pipeline
└── scripts/
    ├── create-labels.sh             # Label creation script
    ├── sync-to-project.sh           # Projects sync helper
    ├── check-dependencies.sh        # Dependency checker
    ├── activate-sub-issues.sh       # Sub-issue activator
    ├── check-epic-completion.sh     # Epic completion checker
    └── post-qa-checklist.sh         # QA checklist poster

docs/governance/
├── 01-overview.md                   # This file
├── 02-workflow.md                   # Detailed workflow
├── 03-agents.md                     # Agent documentation
├── 04-setup.md                      # Setup guide
├── 05-testing.md                    # Test plan
└── 06-conventions.md                # Naming conventions
```

## 👥 Roles

| Role | Responsibilities |
|------|-----------------|
| **Product Owner / PM** | Creates epics, moves items in Projects, approves QA |
| **Refinement Agent** | Structures epics, creates sub-issues, maps dependencies |
| **Execution Agent** | Implements sub-issues, creates PRs |
| **QA Agent** | Posts structured review checklists, assists human review |
| **Release Agent** | Merges approved PRs, tracks epic completion |

## 🔑 Key Principles

1. **Labels drive automation** – every phase transition is triggered by label changes
2. **Guard rails prevent chaos** – workflows block incorrect sequences
3. **Human gates remain** – QA approval and epic review require human decision
4. **Progressive disclosure** – sub-issues are activated only when their blockers are done
5. **Full audit trail** – every automated action is commented on the relevant issue/PR
