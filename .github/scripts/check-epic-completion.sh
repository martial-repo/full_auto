#!/usr/bin/env bash
# check-epic-completion.sh
# Checks if all sub-issues of a parent epic are done.
# If so, marks the epic as done and closes it.
# Usage: GH_TOKEN=<token> REPO=<owner/repo> bash check-epic-completion.sh <sub_issue_number>

set -euo pipefail

SUB_ISSUE_NUMBER="${1:?Usage: check-epic-completion.sh <sub_issue_number>}"
REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"

echo "Checking epic completion triggered by sub-issue #$SUB_ISSUE_NUMBER..."

# ──────────────────────────────────────────────────────────────
# Find parent epic
# ──────────────────────────────────────────────────────────────
ISSUE_BODY=$(gh issue view "$SUB_ISSUE_NUMBER" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")

EPIC_NUMBER=$(echo "$ISSUE_BODY" | grep -ioP '(?i)part of\s+#\K[0-9]+' | head -1 || echo "")

if [ -z "$EPIC_NUMBER" ]; then
  echo "No parent epic found for sub-issue #$SUB_ISSUE_NUMBER. Skipping epic completion check."
  exit 0
fi

echo "Parent epic: #$EPIC_NUMBER"

# ──────────────────────────────────────────────────────────────
# Find all sub-issues for this epic
# ──────────────────────────────────────────────────────────────
ALL_SUB_ISSUES=$(gh issue list --repo "$REPO" \
  --label "type:sub-issue" \
  --state all \
  --json number,state,labels,body \
  --jq ".[] | select(.body | test(\"(?i)part of #$EPIC_NUMBER\")) | {number: .number, state: .state, labels: [.labels[].name]}" 2>/dev/null || echo "")

if [ -z "$ALL_SUB_ISSUES" ]; then
  echo "No sub-issues found for epic #$EPIC_NUMBER. Skipping."
  exit 0
fi

TOTAL=$(echo "$ALL_SUB_ISSUES" | jq -s 'length')
DONE=$(echo "$ALL_SUB_ISSUES" | jq -s '[.[] | select(.state == "closed" or (.labels | contains(["phase:done"])))] | length')
PENDING=$((TOTAL - DONE))

echo "Epic #$EPIC_NUMBER progress: $DONE/$TOTAL sub-issues done"

if [ "$PENDING" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
  echo "🎉 All $TOTAL sub-issues are done! Closing epic #$EPIC_NUMBER..."

  # Build delivery summary table
  SUMMARY_TABLE=$(echo "$ALL_SUB_ISSUES" | jq -r -s \
    '.[] | "| #\(.number) | \(if .state == "closed" then "✅ Done" else "❌ Incomplete" end) |"')

  EPIC_COMMENT="## ✅ AUTOMATED STEP COMPLETE – Epic Completed

All $TOTAL sub-issues have been delivered and released. 🎉

### Delivery Summary
| Sub-issue | Status |
|-----------|--------|
$SUMMARY_TABLE

The epic is now **Done**. Thank you for using the full_auto governance system."

  gh issue edit "$EPIC_NUMBER" --repo "$REPO" \
    --add-label "phase:done" \
    --remove-label "phase:in-progress" \
    --remove-label "phase:todo" \
    --remove-label "phase:release" 2>/dev/null || true

  gh issue close "$EPIC_NUMBER" --repo "$REPO" \
    --comment "$EPIC_COMMENT" 2>/dev/null || true

  REPO="$REPO" bash "$(dirname "$0")/sync-to-project.sh" "$EPIC_NUMBER" "Done" || true

  echo "✅ Epic #$EPIC_NUMBER closed as Done"
else
  echo "Epic #$EPIC_NUMBER still has $PENDING pending sub-issue(s). Posting progress update..."

  PROGRESS_TABLE=$(echo "$ALL_SUB_ISSUES" | jq -r -s \
    '.[] | "| #\(.number) | \(if .state == "closed" or (.labels | contains(["phase:done"])) then "✅ Done" elif (.labels | contains(["phase:in-progress"])) then "🔄 In Progress" elif (.labels | contains(["phase:qa"])) then "🔍 QA" elif (.labels | contains(["phase:todo"])) then "📋 Todo" else "⏳ Pending" end) |"')

  gh issue comment "$EPIC_NUMBER" --repo "$REPO" --body "## 📊 Epic Progress Update

**Completed**: $DONE/$TOTAL sub-issues

| Sub-issue | Status |
|-----------|--------|
$PROGRESS_TABLE

Continuing execution..." 2>/dev/null || true
fi
