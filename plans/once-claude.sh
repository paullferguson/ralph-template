#!/bin/bash

set -e

issues=""
if command -v gh &>/dev/null; then
  for num in $(gh issue list --state open --json number -q '.[].number' 2>/dev/null); do
    data=$(gh issue view "$num" --json number,title,body 2>/dev/null)
    [ -z "$data" ] && continue
    title=$(echo "$data" | jq -r .title)
    body=$(echo "$data" | jq -r .body // "")
    issues+="--- #$num $title ---
$body

"
  done
fi

ralph_commits=$(git log --grep="RALPH" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No RALPH commits found")

claude --permission-mode acceptEdits "@plans/prompt.md ISSUES: $issues Previous RALPH commits: $ralph_commits"
