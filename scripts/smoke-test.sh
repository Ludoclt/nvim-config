#!/usr/bin/env bash
# Run the headless smoke test against this checkout, in isolated XDG dirs, so
# it never touches the Neovim data of the machine it runs on.
#
#   scripts/smoke-test.sh            install plugins from lazy-lock.json, test
#   scripts/smoke-test.sh --update   update plugins (rewrites lazy-lock.json), test
#
# Set SMOKE_HOME to reuse the same plugin cache across runs (default: .tests/).
# Set SMOKE_OFFLINE=1 where downloads are blocked: treesitter parsers and Mason
# packages are not installed, and checks that need them are skipped.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
home="${SMOKE_HOME:-$repo/.tests}"
mode=restore
[[ "${1:-}" == "--update" ]] && mode=update

export XDG_CONFIG_HOME="$home/config" XDG_DATA_HOME="$home/data"
export XDG_STATE_HOME="$home/state" XDG_CACHE_HOME="$home/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
ln -sfn "$repo" "$XDG_CONFIG_HOME/nvim"

echo "==> plugins: Lazy $mode"
nvim --headless "+Lazy! $mode" +qa

if [[ "${SMOKE_OFFLINE:-0}" != 1 ]]; then
  # Mason first: once its packages are in, later steps do not start background
  # installs that Neovim would abort when it quits.
  echo "==> Mason packages"
  (cd "$repo" && nvim --headless -c "luafile tests/install-tools.lua")
  echo "==> treesitter parsers"
  nvim --headless \
    "+lua require('nvim-treesitter').install(LazyVim.opts('nvim-treesitter').ensure_installed):wait(600000)" +qa
fi

echo "==> smoke test"
cd "$repo"
nvim --headless -c "luafile tests/smoke.lua"
