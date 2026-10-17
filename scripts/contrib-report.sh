#!/usr/bin/env bash
# scripts/contrib-report.sh - Contribution report for hackathon jury
set -euo pipefail

echo "=========================================================="
echo " WarmPath Team Contribution Report (Unsolved Loop)"
echo "=========================================================="
echo ""

echo "--- 1. Commits by Author ---"
git shortlog -s -n --all --no-merges

echo ""
echo "--- 2. Lines Added and Removed by Author ---"
git log --no-merges --pretty="%aN" --numstat | awk '
NF==3 {
    plus[$0]+=$1
    minus[$0]+=$2
}
NF==1 {
    author=$0
}
END {
    for (a in plus) {
        printf "%-25s +%-8d -%-8d\n", a, plus[a], minus[a]
    }
}'

echo ""
echo "--- 3. Commits by Role Tag ---"
for role in "m1" "m2" "m3" "m4"; do
    count=$(git log --no-merges --grep="^.*($role" --oneline | wc -l || echo 0)
    printf "Role %-4s commits: %d\n" "$role" "$count"
done

echo ""
echo "=========================================================="
