#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

BASE_REF="${BASE_REF:-origin/master}"

PATTERNS=(
  'AuthKey_M79AR23T85_ASC\.p8'
  '62daa79d-0d34-4548-8ac4-817ec1b2d025'
  'dc09d27243b9492bbe15e0dd279ad7de@o416451\.ingest\.us\.sentry\.io/5311485'
  'a89190aa-0cb0-4b7e-9ae9-71fc1aa7996e'
  '00325aa2-c805-4693-b599-900a25dcde42'
  '4c80e058-69b5-4985-88d1-f53711d817ba'
  'logseq-sync\.fire00hazard\.workers\.dev'
  'logseq-sync\.shaunak-7d1\.workers\.dev'
  'fire00hazard@gmail\.com'
  'M79AR23T85'
  'LR9F42Y4CJ'
  'oz2j50fqo'
)

echo "Running open-source readiness scan against delta from $BASE_REF..."

if ! git rev-parse "$BASE_REF" >/dev/null 2>&1; then
  echo "Base ref '$BASE_REF' does not exist. Set BASE_REF to a valid ref." >&2
  exit 1
fi

CANDIDATE_FILES=()
while IFS= read -r file; do
  if [[ -n "$file" ]]; then
    CANDIDATE_FILES+=("$file")
  fi
done < <(git diff --name-only "$BASE_REF"..HEAD | \
  rg -v '^scripts/open-source/scan-readiness\.sh$' || true)

if [[ ${#CANDIDATE_FILES[@]} -eq 0 ]]; then
  echo "No changed files vs $BASE_REF. Nothing to scan."
  exit 0
fi

FAILED=0
for pattern in "${PATTERNS[@]}"; do
  if rg -n --hidden --glob '!.git/**' --glob '!node_modules/**' --glob '!**/*.lock' "$pattern" "${CANDIDATE_FILES[@]}" >/tmp/oyster-readiness.tmp 2>/dev/null; then
    echo "Pattern matched: $pattern"
    cat /tmp/oyster-readiness.tmp
    echo
    FAILED=1
  fi
done

rm -f /tmp/oyster-readiness.tmp

if [[ $FAILED -eq 1 ]]; then
  echo "Readiness scan FAILED: sensitive patterns detected."
  exit 1
fi

echo "Readiness scan PASSED: no sensitive patterns detected."
