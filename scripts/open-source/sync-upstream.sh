#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'USAGE'
Usage:
  scripts/open-source/sync-upstream.sh --upstream <logseq|huncho> [--date YYYY-MM-DD] [--base-branch BRANCH]

Behavior:
  1) Ensures upstream remote exists and fetches the upstream default branch
  2) Updates mirror branch (upstream/logseq or upstream/huncho) via fast-forward
  3) Creates sync/<upstream>/<date> from base branch
  4) Applies integration step:
     - logseq: merge mirror branch into sync branch
     - huncho: subtree add/pull under packages/huncho

Notes:
  - If --base-branch is omitted, integration/main is used.
  - If integration/main does not exist, master is used as fallback.
USAGE
}

UPSTREAM=""
SYNC_DATE="$(date +%Y-%m-%d)"
BASE_BRANCH="integration/main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --upstream)
      UPSTREAM="${2:-}"
      shift 2
      ;;
    --date)
      SYNC_DATE="${2:-}"
      shift 2
      ;;
    --base-branch)
      BASE_BRANCH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$UPSTREAM" ]]; then
  echo "--upstream is required" >&2
  usage
  exit 1
fi

case "$UPSTREAM" in
  logseq)
    REMOTE_NAME="upstream-logseq"
    REMOTE_URL="https://github.com/logseq/logseq.git"
    DEFAULT_BRANCH="master"
    MIRROR_BRANCH="upstream/logseq"
    ;;
  huncho)
    REMOTE_NAME="upstream-huncho"
    REMOTE_URL="${HUNCHO_REMOTE_URL:-}"
    DEFAULT_BRANCH="${HUNCHO_DEFAULT_BRANCH:-main}"
    MIRROR_BRANCH="upstream/huncho"
    ;;
  *)
    echo "Unsupported upstream: $UPSTREAM" >&2
    exit 1
    ;;
esac

if [[ "$UPSTREAM" == "huncho" && -z "$REMOTE_URL" ]]; then
  echo "Huncho remote URL not set. Export HUNCHO_REMOTE_URL or update this script/UPSTREAMS.yaml." >&2
  exit 1
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not inside a git repository: $ROOT_DIR" >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
  if git show-ref --verify --quiet "refs/heads/master"; then
    echo "Base branch '$BASE_BRANCH' not found, falling back to 'master'"
    BASE_BRANCH="master"
  else
    echo "Base branch '$BASE_BRANCH' not found and no 'master' fallback available." >&2
    exit 1
  fi
fi

if git remote get-url "$REMOTE_NAME" >/dev/null 2>&1; then
  EXISTING_URL="$(git remote get-url "$REMOTE_NAME")"
  if [[ -n "$REMOTE_URL" && "$EXISTING_URL" != "$REMOTE_URL" ]]; then
    echo "Remote '$REMOTE_NAME' exists with different URL: $EXISTING_URL" >&2
    echo "Expected: $REMOTE_URL" >&2
    exit 1
  fi
else
  if [[ -z "$REMOTE_URL" ]]; then
    echo "Remote '$REMOTE_NAME' not found and no URL provided." >&2
    exit 1
  fi
  git remote add "$REMOTE_NAME" "$REMOTE_URL"
fi

echo "Fetching $REMOTE_NAME/$DEFAULT_BRANCH"
git fetch "$REMOTE_NAME" "$DEFAULT_BRANCH"

if git show-ref --verify --quiet "refs/heads/$MIRROR_BRANCH"; then
  git switch "$MIRROR_BRANCH" >/dev/null
  git merge --ff-only "$REMOTE_NAME/$DEFAULT_BRANCH"
else
  git switch -c "$MIRROR_BRANCH" "$REMOTE_NAME/$DEFAULT_BRANCH" >/dev/null
fi

SYNC_BRANCH="sync/$UPSTREAM/$SYNC_DATE"
if git show-ref --verify --quiet "refs/heads/$SYNC_BRANCH"; then
  SYNC_BRANCH="sync/$UPSTREAM/$SYNC_DATE-$(date +%H%M%S)"
fi

git switch "$BASE_BRANCH" >/dev/null
git switch -c "$SYNC_BRANCH" >/dev/null

if [[ "$UPSTREAM" == "logseq" ]]; then
  git merge --no-ff "$MIRROR_BRANCH" -m "chore(sync): merge $UPSTREAM upstream ($SYNC_DATE)"
else
  if [[ -d packages/huncho ]]; then
    git subtree pull --prefix=packages/huncho "$REMOTE_NAME" "$DEFAULT_BRANCH" -m "chore(sync): pull $UPSTREAM subtree ($SYNC_DATE)"
  else
    git subtree add --prefix=packages/huncho "$REMOTE_NAME" "$DEFAULT_BRANCH" -m "chore(sync): add $UPSTREAM subtree ($SYNC_DATE)"
  fi
fi

echo "Created sync branch: $SYNC_BRANCH"
echo "Next steps:"
echo "  1) Resolve conflicts if any"
echo "  2) Open PR: $SYNC_BRANCH -> $BASE_BRANCH"
echo "  3) Merge $BASE_BRANCH into main after integration checks"
