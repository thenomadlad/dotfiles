#!/usr/bin/env bash
# Prints a structured summary of local git activity for one repo over a date range,
# covering ALL local branches (not just the checked-out one) so WIP/unmerged work
# is visible to whoever is drafting the blog post from this output.
#
# Usage: gather_activity.sh <repo_path> <since> [until]
#   <since>/<until> are anything `git log --since/--until` accepts, e.g. "2026-08-24", "1 week ago".
set -euo pipefail

REPO="$1"
SINCE="$2"
UNTIL="${3:-now}"

cd "$REPO"

echo "## Repo: $(basename "$REPO")"
echo "Path: $REPO"
echo

echo "### Commits, all branches ($SINCE .. $UNTIL)"
# Sort oldest-first by date. Note: plain `sort -k2,2` (no -u) — commits are
# already unique by hash, and `sort -u` combined with `-k` dedupes by the SORT
# KEY, not the whole line, which silently drops every commit but one per day.
git log --all --since="$SINCE" --until="$UNTIL" --date=short \
  --pretty=format:'%h  %ad  %an  %s' | sort -k2,2
echo
echo

echo "### Branches with a commit in range"
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r branch; do
  last=$(git log -1 --since="$SINCE" --until="$UNTIL" --format='%ad' --date=short "$branch" -- 2>/dev/null || true)
  if [ -n "$last" ]; then
    echo "- $branch (last commit in range: $last)"
  fi
done
echo

echo "### Diffstat across commits in range (reachable from any branch)"
git log --all --since="$SINCE" --until="$UNTIL" --pretty=tformat: --numstat |
  awk '{add+=$1; del+=$2} END {if (NR==0) print "no changes"; else print "+" add, "-" del, "lines across", NR, "file touches"}'
