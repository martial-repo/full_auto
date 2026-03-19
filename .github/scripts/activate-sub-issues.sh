#!/usr/bin/env bash
# activate-sub-issues.sh
# Finds all sub-issues of an epic and activates those that are unblocked.
# Used when an epic is moved to Todo, or when a sub-issue is completed.
# Usage: GH_TOKEN=<token> REPO=<owner/repo> bash activate-sub-issues.sh <epic_number>

set -euo pipefail

EPIC_NUMBER="${1:?Usage: activate-sub-issues.sh <epic_number>}"
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "Activating unblocked sub-issues for epic #$EPIC_NUMBER..."

# ──────────────────────────────────────────────────────────────
# Find all sub-issues referencing this epic via "Part of #EPIC"
# ──────────────────────────────────────────────────────────────
# Search open issues with type:sub-issue that reference this epic
SUB_ISSUES=$(gh issue list --repo "$REPO" \
  --label "type:sub-issue" \
  --state open \
  --json number,labels,body \
  --jq ".[] | select(.body | test(\"(?i)part of #$EPIC_NUMBER\")) | .number" 2>/dev/null || echo "")

if [ -z "$SUB_ISSUES" ]; then
  echo "No open sub-issues found for epic #$EPIC_NUMBER"
  exit 0
fi

echo "Found sub-issues: $SUB_ISSUES"

# ──────────────────────────────────────────────────────────────
# For each sub-issue, check if it's in draft/ready/todo and unblocked
# ──────────────────────────────────────────────────────────────
for ISSUE_NUM in $SUB_ISSUES; do
  LABELS=$(gh issue view "$ISSUE_NUM" --repo "$REPO" --json labels \
    --jq '[.labels[].name] | join(",")' 2>/dev/null || echo "")

  echo ""
  echo "Sub-issue #$ISSUE_NUM labels: $LABELS"

  # Skip issues already past todo phase
  if echo "$LABELS" | grep -qE "phase:(in-progress|qa|release|done)"; then
    echo "  → Already in execution/done phase, skipping"
    continue
  fi

  # Skip blocked issues
  if echo "$LABELS" | grep -q "status:blocked"; then
    echo "  → Currently blocked, skipping"
    continue
  fi

  # Only activate ready or draft sub-issues
  if ! echo "$LABELS" | grep -qE "phase:(draft|ready|todo)"; then
    echo "  → Not in an activatable phase, skipping"
    continue
  fi

  # Check dependencies
  BLOCK_OUTPUT=$(REPO="$REPO" bash "$(dirname "$0")/check-dependencies.sh" "$ISSUE_NUM" 2>&1 || true)
  echo "$BLOCK_OUTPUT"

  IS_BLOCKED=$(echo "$BLOCK_OUTPUT" | grep -o "blocked=true" || echo "")

  if [ -n "$IS_BLOCKED" ]; then
    echo "  → Sub-issue #$ISSUE_NUM is blocked, skipping"
    continue
  fi

  echo "  → Sub-issue #$ISSUE_NUM is unblocked – activating for execution"

  # Move to todo phase if not already there
  if ! echo "$LABELS" | grep -q "phase:todo"; then
    gh issue edit "$ISSUE_NUM" --repo "$REPO" \
      --add-label "phase:todo" \
      --remove-label "phase:draft" \
      --remove-label "phase:ready" 2>/dev/null || true
    echo "  ✅ Sub-issue #$ISSUE_NUM moved to phase:todo"
  fi
done

echo ""
echo "✅ Sub-issue activation complete for epic #$EPIC_NUMBER"
