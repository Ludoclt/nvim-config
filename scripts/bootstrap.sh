#!/usr/bin/env bash
# Check the system packages this config needs (scripts/packages.txt).
#
#   scripts/bootstrap.sh             report what is missing and print the command
#   scripts/bootstrap.sh --install   run that command (sudo zypper / sudo pacman)
#
# Supports openSUSE (zypper) and Arch Linux (pacman). Nothing is installed
# without --install.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install=false
[[ "${1:-}" == "--install" ]] && install=true

if command -v zypper >/dev/null; then
  pm=zypper column=3
  install_cmd=(sudo zypper install --no-recommends)
elif command -v pacman >/dev/null; then
  pm=pacman column=4
  install_cmd=(sudo pacman -S --needed)
else
  echo "Unsupported distribution: needs zypper or pacman." >&2
  exit 1
fi

trim() { sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$1"; }

# true when version $1 >= $2
version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]; }

missing=() outdated=()
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
  IFS='|' read -r -a field <<<"$line"
  check="$(trim "${field[1]}")"
  package="$(trim "${field[$((column - 1))]}")"
  min="$(trim "${field[4]}")"
  purpose="$(trim "${field[5]}")"

  if [[ "$check" == !* ]]; then
    if bash -c "${check#!}" >/dev/null 2>&1; then
      printf '  ok       %-15s %s\n' "$package" "$purpose"
    else
      printf '  MISSING  %-15s %s\n' "$package" "$purpose"
      missing+=("$package")
    fi
    continue
  fi

  if ! command -v "$check" >/dev/null; then
    printf '  MISSING  %-15s %s\n' "$package" "$purpose"
    missing+=("$package")
  elif [[ -n "$min" ]]; then
    have="$("$check" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 || true)"
    if [[ -n "$have" ]] && version_ge "$have" "$min"; then
      printf '  ok       %-15s %s (%s)\n' "$package" "$purpose" "$have"
    else
      printf '  OLD      %-15s %s (%s, needs >= %s)\n' "$package" "$purpose" "${have:-unknown}" "$min"
      outdated+=("$package")
    fi
  else
    printf '  ok       %-15s %s\n' "$package" "$purpose"
  fi
done <"$repo/scripts/packages.txt"

echo
if ((${#outdated[@]})); then
  echo "Outdated: ${outdated[*]}"
  echo "Update the system first ($pm), or install a newer build of these by hand."
fi

if ((${#missing[@]} == 0)); then
  echo "All packages are installed. Next: start nvim (plugins install on first launch)."
  exit 0
fi

echo "Missing: ${missing[*]}"
if $install; then
  "${install_cmd[@]}" "${missing[@]}"
else
  echo "Install them with:"
  echo "  ${install_cmd[*]} ${missing[*]}"
  echo "or run: scripts/bootstrap.sh --install"
  exit 1
fi
