#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
tasks_dir="$script_dir/../sre-config/tasks"

for task in config-drift health-check daily-reliability-report; do
  prompt=$(sh "$script_dir/read-task-prompt.sh" "$tasks_dir/$task.yaml")
  case "$prompt" in
    *$'\n\n'* ) ;;
    * ) echo "Missing paragraph break in $task" >&2; exit 1 ;;
  esac
  case "$task" in
    config-drift) last='Do not change live resources.' ;;
    health-check) last='Include full root cause analysis in the issue' ;;
    daily-reliability-report) last='4. Provide recommendations for improving reliability.' ;;
  esac
  case "$prompt" in
    *"$last"*) ;;
    *) echo "Truncated task prompt: $task" >&2; exit 1 ;;
  esac
done

fixture=$(mktemp)
trap 'rm -f "$fixture"' EXIT
cat > "$fixture" <<'YAML'
spec:
  agentPrompt: |
    First line

    Final line
  name: next-field
YAML
actual=$(sh "$script_dir/read-task-prompt.sh" "$fixture")
expected=$'First line\n\nFinal line'
[ "$actual" = "$expected" ] || { echo 'Incorrect block boundary' >&2; exit 1; }
printf 'spec:\n  name: missing\n' > "$fixture"
if sh "$script_dir/read-task-prompt.sh" "$fixture" >/dev/null; then
  echo 'Missing prompt should fail' >&2
  exit 1
fi
echo 'Scheduled task prompt parsing passed'
