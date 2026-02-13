#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# jq filter to extract streaming text from assistant messages
stream_text='select(.type == "assistant").message.content[]? | select(.type == "text").text // empty | gsub("\n"; "\r\n") | . + "\r\n\n"'

# jq filter to extract final result
final_result='select(.type == "result").result // empty'


for ((i=1; i<=$1; i++)); do
  tmpfile=$(mktemp)
  trap "rm -f $tmpfile" EXIT
  echo "------- ITERATION $i --------"

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

  docker sandbox run claude . -- \
    --verbose \
    --print \
    --output-format stream-json \
    "@plans/prompt.md ISSUES: $issues Previous RALPH commits: $ralph_commits" \
  | grep --line-buffered '^{' \
  | tee "$tmpfile" \
  | jq --unbuffered -rj "$stream_text"

  result=$(jq -r "$final_result" "$tmpfile")

  if [[ "$result" == *"<promise>NO MORE TASKS</promise>"* ]]; then
    echo "Ralph complete after $i iterations."
    exit 0
  fi

  if [[ "$result" == *"<promise>ABORT</promise>"* ]]; then
    echo "Ralph aborted after $i iterations."
    exit 1
  fi
done