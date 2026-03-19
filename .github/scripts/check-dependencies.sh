#!/usr/bin/env bash
# check-dependencies.sh
# Checks if all blocking dependencies of a sub-issue are resolved (phase:done).
# Usage: GH_TOKEN=<token> REPO=<owner/repo> bash check-dependencies.sh <issue_number>
# Sets GITHUB_OUTPUT: blocked=true|false, blocking_issues=<comma-separated>

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: check-dependencies.sh <issue_number>}"
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "Checking dependencies for issue #$ISSUE_NUMBER..."

# Get issue body
ISSUE_BODY=$(gh issue view "$ISSUE_NUMBER" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")

# Extract "Blocked by #NNN" references from the issue body
BLOCKED_BY=$(echo "$ISSUE_BODY" | grep -ioP 'blocked by[:\s]+#?\K[0-9]+(?:\s*,\s*#?[0-9]+)*' | \
  tr ',' '\n' | grep -oP '[0-9]+' | sort -u || echo "")

if [ -z "$BLOCKED_BY" ]; then
  echo "No blocking dependencies found."
  echo "blocked=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

echo "Found potential blockers: $BLOCKED_BY"

UNRESOLVED=""
for BLOCKER_NUM in $BLOCKED_BY; do
  BLOCKER_LABELS=$(gh issue view "$BLOCKER_NUM" --repo "$REPO" --json labels \
    --jq '[.labels[].name] | join(",")' 2>/dev/null || echo "not-found")

  if [ "$BLOCKER_LABELS" = "not-found" ]; then
    echo "  ⚠ Blocker #$BLOCKER_NUM not found – treating as resolved"
    continue
  fi

  if echo "$BLOCKER_LABELS" | grep -q "phase:done"; then
    echo "  ✅ Blocker #$BLOCKER_NUM is done"
  else
    echo "  🔴 Blocker #$BLOCKER_NUM is NOT done (labels: $BLOCKER_LABELS)"
    UNRESOLVED="$UNRESOLVED $BLOCKER_NUM"
  fi
done

UNRESOLVED=$(echo "$UNRESOLVED" | xargs) # trim

if [ -n "$UNRESOLVED" ]; then
  echo "blocked=true" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "blocking_issues=$UNRESOLVED" >> "${GITHUB_OUTPUT:-/dev/null}"

  # Post a comment on the blocked sub-issue
  BLOCKERS_LIST=$(echo "$UNRESOLVED" | tr ' ' '\n' | while read -r N; do echo "- #$N"; done)
  gh issue comment "$ISSUE_NUMBER" --repo "$REPO" --body "## 🔴 HUMAN ACTION REQUIRED – Execution Blocked

This sub-issue cannot start because the following dependencies are not yet complete:

$BLOCKERS_LIST

**Action**: Complete the blocking issues above. This sub-issue will be automatically activated once all blockers are in \`phase:done\`." 2>/dev/null || true

  gh issue edit "$ISSUE_NUMBER" --repo "$REPO" \
    --add-label "status:blocked" \
    --remove-label "phase:todo" 2>/dev/null || true

  echo "Sub-issue #$ISSUE_NUMBER is blocked by: $UNRESOLVED"
  exit 0
else
  echo "blocked=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  echo "blocking_issues=" >> "${GITHUB_OUTPUT:-/dev/null}"

  # Remove blocked status if it was set
  gh issue edit "$ISSUE_NUMBER" --repo "$REPO" \
    --remove-label "status:blocked" 2>/dev/null || true

  echo "All dependencies resolved for #$ISSUE_NUMBER"
fi
