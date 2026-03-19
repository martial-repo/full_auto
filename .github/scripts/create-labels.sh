#!/usr/bin/env bash
# create-labels.sh
# Creates or updates all governance labels for the full_auto repository.
# Also removes legacy GitHub default labels that are not used in this project.
# Usage: GH_TOKEN=<token> REPO=<owner/repo> bash create-labels.sh

set -euo pipefail

REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "Creating labels for repository: $REPO"

# ──────────────────────────────────────────────────────────────
# Helper: create or update a label
# ──────────────────────────────────────────────────────────────
create_or_update_label() {
  local name="$1"
  local color="$2"
  local description="$3"

  if gh label list --repo "$REPO" --json name --jq '.[].name' | grep -qx "$name"; then
    gh label edit "$name" --repo "$REPO" \
      --color "$color" \
      --description "$description" 2>/dev/null && echo "  ↻ Updated: $name" || echo "  ⚠ Could not update: $name"
  else
    gh label create "$name" --repo "$REPO" \
      --color "$color" \
      --description "$description" 2>/dev/null && echo "  ✓ Created: $name" || echo "  ⚠ Could not create: $name"
  fi
}

# ──────────────────────────────────────────────────────────────
# Helper: delete a legacy label if it exists
# ──────────────────────────────────────────────────────────────
delete_legacy_label() {
  local name="$1"

  if gh label list --repo "$REPO" --json name --jq '.[].name' | grep -qx "$name"; then
    gh label delete "$name" --repo "$REPO" --yes 2>/dev/null && echo "  🗑 Deleted: $name" || echo "  ⚠ Could not delete: $name"
  else
    echo "  – Not found (skipping): $name"
  fi
}

# ──────────────────────────────────────────────────────────────
# PHASE labels (workflow states)
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Phase Labels ==="
create_or_update_label "phase:draft"        "BFD4F2" "Initial draft – not yet refined"
create_or_update_label "phase:refinement"   "C5DEF5" "Copilot refinement in progress"
create_or_update_label "phase:ready"        "0E8A16" "Refined and ready for execution"
create_or_update_label "phase:todo"         "FBCA04" "Approved for execution – awaiting start"
create_or_update_label "phase:in-progress"  "FF7619" "Execution in progress"
create_or_update_label "phase:qa"           "E4E669" "Under QA validation"
create_or_update_label "phase:release"      "D4C5F9" "Release approved – deploying"
create_or_update_label "phase:done"         "0075CA" "Completed and released"

# ──────────────────────────────────────────────────────────────
# TYPE labels (artifact type)
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Type Labels ==="
create_or_update_label "type:epic"          "7057FF" "High-level epic / feature chantier"
create_or_update_label "type:sub-issue"     "008672" "Atomic sub-task of an epic"
create_or_update_label "type:bug"           "D73A4A" "Bug or defect"
create_or_update_label "type:chore"         "E4E669" "Maintenance, tooling, dependencies"
create_or_update_label "type:docs"          "0075CA" "Documentation"
create_or_update_label "type:spike"         "D876E3" "Research or technical investigation"

# ──────────────────────────────────────────────────────────────
# PRIORITY labels
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Priority Labels ==="
create_or_update_label "priority:critical"  "B60205" "Critical – blocks everything"
create_or_update_label "priority:high"      "D93F0B" "High priority"
create_or_update_label "priority:medium"    "FBCA04" "Medium priority"
create_or_update_label "priority:low"       "0E8A16" "Low priority – nice to have"

# ──────────────────────────────────────────────────────────────
# COMPLEXITY labels
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Complexity Labels ==="
create_or_update_label "complexity:xs"      "F9D0C4" "XS – less than 2 hours"
create_or_update_label "complexity:s"       "FFDFC7" "S – 2 to 4 hours"
create_or_update_label "complexity:m"       "FFF0C7" "M – 4 to 8 hours"
create_or_update_label "complexity:l"       "D4EDDA" "L – 1 to 2 days"
create_or_update_label "complexity:xl"      "F8D7DA" "XL – more than 2 days"

# ──────────────────────────────────────────────────────────────
# STATUS labels (transient states)
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Status Labels ==="
create_or_update_label "status:blocked"     "B60205" "Blocked by a dependency"
create_or_update_label "status:needs-info"  "D876E3" "Needs clarification before proceeding"
create_or_update_label "status:on-hold"     "E4E669" "Voluntarily paused"
create_or_update_label "status:wontfix"     "EEEEEE" "Will not be addressed"

# ──────────────────────────────────────────────────────────────
# AGENT labels (which agent is responsible)
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Agent Labels ==="
create_or_update_label "agent:refinement"   "BFD4F2" "Assigned to Refinement Agent"
create_or_update_label "agent:execution"    "FF7619" "Assigned to Execution Agent"
create_or_update_label "agent:qa"           "E4E669" "Under QA Agent review"
create_or_update_label "agent:release"      "D4C5F9" "Under Release Agent control"

# ──────────────────────────────────────────────────────────────
# Remove legacy GitHub default labels not used in this project
# ──────────────────────────────────────────────────────────────
echo ""
echo "=== Removing Legacy Labels ==="
delete_legacy_label "bug"
delete_legacy_label "documentation"
delete_legacy_label "duplicate"
delete_legacy_label "enhancement"
delete_legacy_label "good first issue"
delete_legacy_label "help wanted"
delete_legacy_label "invalid"
delete_legacy_label "question"
delete_legacy_label "wontfix"

echo ""
echo "✅ Label setup complete for $REPO"
