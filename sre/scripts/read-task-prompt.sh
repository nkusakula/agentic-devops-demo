#!/bin/sh
# Read the literal agentPrompt block from a ScheduledTask YAML file.
set -eu
[ "$#" -eq 1 ] || exit 2

awk '
  /^  agentPrompt: \|[[:space:]]*$/ { in_prompt = 1; found = 1; next }
  in_prompt && /^  [[:alpha:]_][[:alnum:]_]*:/ { exit }
  in_prompt {
    if (/^    /) sub(/^    /, "")
    else if (/^[[:space:]]*$/) $0 = ""
    else exit 2
    print
  }
  END { if (!found) exit 1 }
' "$1"
