#!/usr/bin/env bash
set -euo pipefail

# Build and deploy a Cloudflare Worker using local config overrides.
#
# Usage:
#   scripts/deploy-worker.sh db-sync [--env staging|prod] [--skip-build]
#   scripts/deploy-worker.sh publish [--env staging|prod] [--skip-build]
#
# Reads resource IDs from .env.open-source.local (or env vars) and generates
# a wrangler.local.toml with real values, builds the worker, deploys, and
# cleans up.
#
# Required env vars (set in .env.open-source.local):
#   DB_SYNC_D1_ID, DB_SYNC_D1_NAME, DB_SYNC_R2_BUCKET  (db-sync default env)
#   PUBLISH_R2_BUCKET                                    (publish default env)
#   See .env.open-source.example for the full list.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source .env.open-source.local if it exists
if [[ -f "$ROOT_DIR/.env.open-source.local" ]]; then
  set -a
  source "$ROOT_DIR/.env.open-source.local"
  set +a
fi

WORKER="${1:-}"
shift || true

# Check for --skip-build flag
SKIP_BUILD=false
DEPLOY_ARGS=()
for arg in "$@"; do
  if [[ "$arg" == "--skip-build" ]]; then
    SKIP_BUILD=true
  else
    DEPLOY_ARGS+=("$arg")
  fi
done

if [[ -z "$WORKER" ]]; then
  echo "Usage: scripts/deploy-worker.sh <db-sync|publish> [--env staging|prod] [--skip-build]" >&2
  exit 1
fi

case "$WORKER" in
  db-sync)
    WORKER_DIR="$ROOT_DIR/deps/db-sync/worker"
    BUILD_DIR="$ROOT_DIR/deps/db-sync"
    TEMPLATE="$WORKER_DIR/wrangler.toml"
    LOCAL_CONFIG="$WORKER_DIR/wrangler.local.toml"

    sed \
      -e "s|REPLACE_WITH_SYNC_ASSETS_BUCKET|${DB_SYNC_R2_BUCKET:?DB_SYNC_R2_BUCKET not set}|g" \
      -e "s|REPLACE_WITH_SYNC_DB_NAME|${DB_SYNC_D1_NAME:?DB_SYNC_D1_NAME not set}|g" \
      -e "s|REPLACE_WITH_SYNC_DB_ID|${DB_SYNC_D1_ID:?DB_SYNC_D1_ID not set}|g" \
      -e "s|REPLACE_WITH_COGNITO_CLIENT_ID|${COGNITO_CLIENT_ID:-69cs1lgme7p8kbgld8n5kseii6}|g" \
      -e "s|https://cognito-idp.<region>.amazonaws.com/<user-pool-id>|${COGNITO_ISSUER:-https://cognito-idp.us-east-1.amazonaws.com/us-east-1_dtagLnju8}|g" \
      -e "s|REPLACE_WITH_SENTRY_DSN|${DB_SYNC_SENTRY_DSN:-}|g" \
      -e "s|REPLACE_WITH_STAGING_SYNC_ASSETS_BUCKET|${DB_SYNC_STAGING_R2_BUCKET:-logseq-sync-assets-dev}|g" \
      -e "s|REPLACE_WITH_STAGING_SYNC_DB_NAME|${DB_SYNC_STAGING_D1_NAME:-logseq-sync-graph-meta-staging}|g" \
      -e "s|REPLACE_WITH_STAGING_SYNC_DB_ID|${DB_SYNC_STAGING_D1_ID:-STAGING_DB_ID_NOT_SET}|g" \
      -e "s|REPLACE_WITH_PROD_SYNC_ASSETS_BUCKET|${DB_SYNC_PROD_R2_BUCKET:-logseq-sync-assets-prod}|g" \
      -e "s|REPLACE_WITH_PROD_SYNC_DB_NAME|${DB_SYNC_PROD_D1_NAME:-logseq-sync-graphs-prod}|g" \
      -e "s|REPLACE_WITH_PROD_SYNC_DB_ID|${DB_SYNC_PROD_D1_ID:-PROD_DB_ID_NOT_SET}|g" \
      "$TEMPLATE" > "$LOCAL_CONFIG"
    ;;

  publish)
    WORKER_DIR="$ROOT_DIR/deps/publish/worker"
    BUILD_DIR="$ROOT_DIR/deps/publish"
    TEMPLATE="$WORKER_DIR/wrangler.toml"
    LOCAL_CONFIG="$WORKER_DIR/wrangler.local.toml"

    sed \
      -e "s|REPLACE_WITH_PUBLISH_DEV_BUCKET|${PUBLISH_R2_BUCKET:?PUBLISH_R2_BUCKET not set}|g" \
      -e "s|REPLACE_WITH_COGNITO_CLIENT_ID|${COGNITO_CLIENT_ID:-69cs1lgme7p8kbgld8n5kseii6}|g" \
      -e "s|https://cognito-idp.<region>.amazonaws.com/<user-pool-id>|${COGNITO_ISSUER:-https://cognito-idp.us-east-1.amazonaws.com/us-east-1_dtagLnju8}|g" \
      -e "s|REPLACE_WITH_PUBLISH_STAGING_BUCKET|${PUBLISH_STAGING_R2_BUCKET:-logseq-publish-dev}|g" \
      -e "s|REPLACE_WITH_PUBLISH_PROD_BUCKET|${PUBLISH_PROD_R2_BUCKET:-logseq-publish-prod}|g" \
      -e "s|REPLACE_WITH_PUBLISH_CUSTOM_DOMAIN|${PUBLISH_CUSTOM_DOMAIN:-logseq.io}|g" \
      "$TEMPLATE" > "$LOCAL_CONFIG"
    ;;

  *)
    echo "Unknown worker: $WORKER. Use 'db-sync' or 'publish'." >&2
    exit 1
    ;;
esac

echo "Generated $LOCAL_CONFIG"

# Build step
if [[ "$SKIP_BUILD" == "false" ]]; then
  echo "Building $WORKER worker..."
  cd "$BUILD_DIR"
  yarn release
  cd "$ROOT_DIR"
else
  echo "Skipping build (--skip-build)"
fi

# Deploy
echo "Deploying $WORKER..."
cd "$WORKER_DIR"
npx wrangler deploy --config wrangler.local.toml "${DEPLOY_ARGS[@]}"

echo "Deploy complete. Cleaning up local config."
rm -f "$LOCAL_CONFIG"
