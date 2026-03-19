#!/usr/bin/env bash
# sync-to-project.sh
# Syncs an issue to the GitHub Projects v2 board.
# Usage: GH_TOKEN=<token> REPO=<owner/repo> bash sync-to-project.sh <issue_number> <status>
#
# Requires repository variable PROJECT_NUMBER to be set.
# Status values must match the Projects board column names exactly.

set -euo pipefail

ISSUE_NUMBER="${1:?Usage: sync-to-project.sh <issue_number> <status>}"
TARGET_STATUS="${2:?Usage: sync-to-project.sh <issue_number> <status>}"

REPO="${REPO:-$(gh repo view --json nameWithOwner --jq '.nameWithOwner')}"
OWNER="${REPO%%/*}"

# Get PROJECT_NUMBER from repo variables (set via GitHub UI or gh variable set)
PROJECT_NUMBER="${PROJECT_NUMBER:-}"

if [ -z "$PROJECT_NUMBER" ]; then
  PROJECT_NUMBER=$(gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/actions/variables/PROJECT_NUMBER" \
    --jq '.value' 2>/dev/null || echo "")
fi

if [ -z "$PROJECT_NUMBER" ]; then
  echo "⚠ PROJECT_NUMBER not set. Skipping Projects sync for issue #$ISSUE_NUMBER."
  echo "  To enable sync: gh variable set PROJECT_NUMBER --body '<number>' --repo $REPO"
  exit 0
fi

echo "Syncing issue #$ISSUE_NUMBER to Projects board $PROJECT_NUMBER (status: $TARGET_STATUS)..."

# ──────────────────────────────────────────────────────────────
# Step 1: Get project ID
# ──────────────────────────────────────────────────────────────
PROJECT_ID=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) { id }
    }
  }' -f owner="$OWNER" -F number="$PROJECT_NUMBER" \
  --jq '.data.user.projectV2.id' 2>/dev/null || \
  gh api graphql -f query='
    query($owner: String!, $number: Int!) {
      organization(login: $owner) {
        projectV2(number: $number) { id }
      }
    }' -f owner="$OWNER" -F number="$PROJECT_NUMBER" \
    --jq '.data.organization.projectV2.id' 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ]; then
  echo "⚠ Could not find project #$PROJECT_NUMBER for owner $OWNER. Skipping sync."
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Step 2: Get issue node ID
# ──────────────────────────────────────────────────────────────
ISSUE_NODE_ID=$(gh api "/repos/$REPO/issues/$ISSUE_NUMBER" --jq '.node_id' 2>/dev/null || echo "")

if [ -z "$ISSUE_NODE_ID" ]; then
  echo "⚠ Could not find issue #$ISSUE_NUMBER. Skipping sync."
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Step 3: Add issue to project (idempotent)
# ──────────────────────────────────────────────────────────────
ITEM_ID=$(gh api graphql -f query='
  mutation($projectId: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
      item { id }
    }
  }' -f projectId="$PROJECT_ID" -f contentId="$ISSUE_NODE_ID" \
  --jq '.data.addProjectV2ItemById.item.id' 2>/dev/null || echo "")

if [ -z "$ITEM_ID" ]; then
  # Item may already exist – try to find it
  ITEM_ID=$(gh api graphql -f query='
    query($projectId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              content {
                ... on Issue { number }
              }
            }
          }
        }
      }
    }' -f projectId="$PROJECT_ID" \
    --jq ".data.node.items.nodes[] | select(.content.number == $ISSUE_NUMBER) | .id" 2>/dev/null || echo "")
fi

if [ -z "$ITEM_ID" ]; then
  echo "⚠ Could not add/find issue #$ISSUE_NUMBER in project. Skipping status update."
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Step 4: Get the Status field ID and option ID
# ──────────────────────────────────────────────────────────────
STATUS_FIELD_ID=$(gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options { id name }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" \
  --jq '.data.node.fields.nodes[] | select(.name == "Status") | .id' 2>/dev/null || echo "")

STATUS_OPTION_ID=$(gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options { id name }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" \
  --jq ".data.node.fields.nodes[] | select(.name == \"Status\") | .options[] | select(.name == \"$TARGET_STATUS\") | .id" 2>/dev/null || echo "")

if [ -z "$STATUS_FIELD_ID" ] || [ -z "$STATUS_OPTION_ID" ]; then
  echo "⚠ Could not find Status field or option '$TARGET_STATUS' in project. Skipping status update."
  echo "  Available columns should match: Backlog, Refinement, Ready, Todo, In Progress, QA, Release, Done"
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Step 5: Update the Status field
# ──────────────────────────────────────────────────────────────
gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $optionId }
    }) {
      projectV2Item { id }
    }
  }' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" \
  -f fieldId="$STATUS_FIELD_ID" -f optionId="$STATUS_OPTION_ID" > /dev/null 2>&1 && \
  echo "✅ Issue #$ISSUE_NUMBER synced to Projects – Status: $TARGET_STATUS" || \
  echo "⚠ Failed to update Projects status for issue #$ISSUE_NUMBER"
