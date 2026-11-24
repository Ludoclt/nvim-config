#!/usr/bin/env bash
# Bring this machine in line with the repository: pull the latest commits,
# then install the exact plugin versions recorded in lazy-lock.json.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! git -C "$repo" diff --quiet -- lazy-lock.json; then
  echo "lazy-lock.json has local changes (probably a local :Lazy update)." >&2
  echo "Plugin updates come from the weekly pull request. Drop the local ones with:" >&2
  echo "  git -C $repo checkout -- lazy-lock.json" >&2
  exit 1
fi

git -C "$repo" pull --ff-only
nvim --headless "+Lazy! restore" +qa
echo
echo "Plugins match lazy-lock.json. Mason tools update on the next start (:Mason to check)."
