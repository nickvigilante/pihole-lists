# shellcheck shell=bash
# Shared helpers for sync.sh and export.sh. Source this file; do not run it.
#
# PIHOLE_EXEC is the command prefix that reaches the Pi-hole container with stdin attached.
# The default targets the homelab deployment.

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
lists=${LISTS_DIR:-$repo/lists}
read -r -a exec_cmd <<<"${PIHOLE_EXEC:-kubectl -n networking exec -i deploy/pihole --}"
db=/etc/pihole/gravity.db

# Domainlist types in gravity.db: 0 allow exact, 1 deny exact, 2 allow regex, 3 deny regex.
sql_for() {
  case $1 in
    adlist) echo 'select address from adlist;' ;;
    1 | 3) echo "select domain from domainlist where type=$1;" ;;
    *)
      echo "unsupported type: $1" >&2
      return 2
      ;;
  esac
}

# Print one live value per line, sorted. Fails loudly if the pod cannot be reached.
live() {
  local sql out
  sql=$(sql_for "$1")
  out=$(printf '%s\n' "$sql" | "${exec_cmd[@]}" pihole-FTL sqlite3 "$db") || return 1
  [[ -n $out ]] && printf '%s\n' "$out" | LC_ALL=C sort -u
  return 0
}

# Print the values in a list file, sorted, skipping blank lines.
wanted() {
  { grep -v '^[[:space:]]*$' "$lists/$1" || true; } | LC_ALL=C sort -u
}
