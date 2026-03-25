#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: init.sh [--force]

Syncs AGENTS.md and .claude/CLAUDE.md:
- Creates AGENTS.md symlinks in any package root that contains .claude/CLAUDE.md
- Creates .claude/CLAUDE.md from AGENTS.md in any package root that has AGENTS.md but not .claude/CLAUDE.md

Options:
  --force  Replace existing AGENTS.md files/symlinks or .claude/CLAUDE.md files.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
elif [[ -n "${1:-}" ]]; then
  echo "Unknown argument: ${1}" >&2
  usage >&2
  exit 1
fi

# Process .claude/CLAUDE.md files and create AGENTS.md symlinks
while IFS= read -r claude; do
  pkg_root="$(dirname "$(dirname "$claude")")"
  link="$pkg_root/AGENTS.md"
  target=".claude/CLAUDE.md"

  # If we are in the root directory, pkg_root is "." (or absolute path equivalent)
  # The find command returns paths relative to CWD if given . or absolute if given absolute.
  # The reference script uses "$ROOT" which is absolute.

  if [[ -L "$link" ]]; then
    existing_target="$(readlink "$link")"
    if [[ "$existing_target" == "$target" ]]; then
      echo "OK: $link already points to $target"
      continue
    fi
    if [[ "$FORCE" -eq 0 ]]; then
      echo "SKIP: $link is a symlink to $existing_target (use --force to replace)"
      continue
    fi
  elif [[ -e "$link" && "$FORCE" -eq 0 ]]; then
    echo "SKIP: $link exists (use --force to replace)"
    continue
  fi

  ln -sfn "$target" "$link"
  echo "LINK: $link -> $target"
done < <(find "$ROOT" -type f -path '*/.claude/CLAUDE.md')

# Process AGENTS.md files and create .claude/CLAUDE.md from them (if not already present)
while IFS= read -r agents; do
  pkg_root="$(dirname "$agents")"
  claude="$pkg_root/.claude/CLAUDE.md"

  # Skip if .claude/CLAUDE.md already exists (unless --force)
  if [[ -e "$claude" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
      echo "SKIP: $claude already exists (use --force to replace)"
      continue
    fi
  fi

  # Create .claude directory if it doesn't exist
  mkdir -p "$(dirname "$claude")"

  # Copy AGENTS.md to .claude/CLAUDE.md
  cp "$agents" "$claude"
  echo "CREATE: $claude from $agents"
done < <(find "$ROOT" -type f -name 'AGENTS.md' ! -path '*/.claude/*')
