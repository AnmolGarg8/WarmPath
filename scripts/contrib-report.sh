#!/usr/bin/env bash
set -euo pipefail

echo "================================================================="
echo "               WarmPath Contributor Activity Report               "
echo "================================================================="
echo ""

echo "--- 1. Commits by Author ---"
git shortlog -sn --all
echo ""

echo "--- 2. Lines Added and Removed by Author ---"
git log --numstat --pretty="%an <%ae>" | awk '
NF==3 {
  plus[$0] += $1;
  minus[$0] += $2;
}
END {
  printf "%-35s %-12s %-12s\n", "Author", "Lines Added", "Lines Removed"
  printf "%-35s %-12s %-12s\n", "-----------------------------------", "------------", "------------"
  for (author in plus) {
    if (author != "") {
      printf "%-35s +%-11d -%-11d\n", author, plus[author], minus[author]
    }
  }
}'
echo ""

echo "--- 3. Files Touched per Top-Level Folder by Author ---"
git log --name-only --pretty="AUTHOR:%an" | awk '
/^AUTHOR:/ {
  author = substr($0, 8);
  next;
}
NF > 0 {
  split($0, parts, "/");
  folder = parts[1];
  count[author, folder]++;
}
END {
  printf "%-30s %-20s %-10s\n", "Author", "Folder", "Touches"
  printf "%-30s %-20s %-10s\n", "------------------------------", "--------------------", "----------"
  for (key in count) {
    split(key, arr, SUBSEP);
    printf "%-30s %-20s %-10d\n", arr[1], arr[2], count[key];
  }
}'
echo ""
echo "================================================================="
echo "Report complete."
