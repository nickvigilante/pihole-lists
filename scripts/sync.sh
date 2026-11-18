#!/usr/bin/env bash
# Reconcile a live Pi-hole's deny rules with the files in lists/.
#
# Usage: scripts/sync.sh [--apply [--prune]]
#
#   (no flags)  dry run: print what would change, change nothing
#   --apply     add rules that are in the files but missing from Pi-hole
#   --prune     with --apply, also delete rules that are in Pi-hole but not in the files
#
# Adlists are only reported, never changed.
# Add or remove them in the web UI, then run `pihole -g`.
# Allow rules, groups, and clients are never touched.
set -euo pipefail

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

apply=0
prune=0
for arg in "$@"; do
  case $arg in
    --apply) apply=1 ;;
    --prune) prune=1 ;;
    -h | --help)
      sed -n '2,12p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
  esac
done
if ((prune && !apply)); then
  echo "--prune only makes sense with --apply" >&2
  exit 2
fi

count() { if [[ -z $1 ]]; then echo 0; else printf '%s\n' "$1" | wc -l; fi; }

# sync_kind LABEL TYPE FILE SUBCOMMAND
# SUBCOMMAND is the pihole CLI verb: "deny" for exact domains, "--regex" for patterns.
sync_kind() {
  local label=$1 type=$2 file=$3 sub=$4
  local current target to_add to_del
  current=$(live "$type") || {
    echo "could not read $label from Pi-hole" >&2
    exit 1
  }
  target=$(wanted "$file")
  to_add=$(LC_ALL=C comm -13 <(printf '%s\n' "$current") <(printf '%s\n' "$target") | grep -v '^$' || true)
  to_del=$(LC_ALL=C comm -23 <(printf '%s\n' "$current") <(printf '%s\n' "$target") | grep -v '^$' || true)

  echo "== $label: $(count "$target") in file, $(count "$current") in Pi-hole"
  [[ -n $to_add ]] && printf '%s\n' "$to_add" | sed 's/^/  + /'
  [[ -n $to_del ]] && printf '%s\n' "$to_del" | sed 's/^/  - /'
  [[ -z $to_add && -z $to_del ]] && echo "  in sync"

  if ((apply)) && [[ -n $to_add ]]; then
    printf '%s\n' "$to_add" | tr '\n' '\0' | "${exec_cmd[@]}" xargs -0 pihole "$sub"
  fi
  if ((apply && prune)) && [[ -n $to_del ]]; then
    printf '%s\n' "$to_del" | tr '\n' '\0' | "${exec_cmd[@]}" xargs -0 pihole "$sub" -d
  fi
  return 0
}

sync_kind "deny (exact)" 1 deny-exact.txt deny
sync_kind "deny (regex)" 3 deny-regex.txt --regex

# Adlists are report-only.
current=$(live adlist) || {
  echo "could not read adlists from Pi-hole" >&2
  exit 1
}
target=$(wanted adlists.txt)
echo "== adlists: $(count "$target") in file, $(count "$current") in Pi-hole (report only)"
extra=$(LC_ALL=C comm -3 <(printf '%s\n' "$current") <(printf '%s\n' "$target") | grep -v '^$' || true)
if [[ -n $extra ]]; then
  echo "$extra" | sed -e 's/^\t/  + (file only) /' -e 's/^\([^ ]\)/  - (Pi-hole only) \1/'
else
  echo "  in sync"
fi

if ((apply)); then
  echo "applied"
else
  echo "dry run, nothing changed (use --apply)"
fi
