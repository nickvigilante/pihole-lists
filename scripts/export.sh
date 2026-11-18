#!/usr/bin/env bash
# Write the live Pi-hole's deny rules and adlists into lists/.
#
# Use this after changing rules in the web UI, so the repo catches up.
# It overwrites lists/deny-exact.txt, lists/deny-regex.txt, and lists/adlists.txt,
# then shows the diff so you can review it before committing.
# Allow rules are never exported.
set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# dump TYPE FILE: refuse to overwrite a list with an empty result.
dump() {
  local type=$1 file=$2 tmp
  tmp=$(mktemp)
  if ! live "$type" >"$tmp" || [[ ! -s $tmp ]]; then
    rm -f "$tmp"
    echo "no data for $file; leaving it alone" >&2
    exit 1
  fi
  chmod 644 "$tmp"
  mv "$tmp" "$lists/$file"
}

dump 1 deny-exact.txt
dump 3 deny-regex.txt
dump adlist adlists.txt

git -C "$repo" diff --stat -- lists || true
