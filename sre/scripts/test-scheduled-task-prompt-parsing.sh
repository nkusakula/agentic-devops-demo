#!/bin/bash
# =============================================================================
# test-scheduled-task-prompt-parsing.sh — Regression test for the agentPrompt
# extraction logic in post-provision.sh.
#
# Guards against the truncation bug where a sed range ended at the first
# blank line inside "agentPrompt: |", causing multi-paragraph prompts (with
# numbered steps separated by blank lines) to be cut down to their intro
# line only.
#
# Usage: bash scripts/test-scheduled-task-prompt-parsing.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

FAILURES=0

extract_agent_prompt() {
  local yaml_file="$1"
  local content
  content=$(cat "$yaml_file")
  echo "$content" | awk '
    /^  agentPrompt: \|/ { capture=1; next }
    capture && /^  [A-Za-z_]+:/ { capture=0 }
    capture { print }
  ' | sed 's/^    //'
}

assert_contains() {
  local yaml_file="$1" needle="$2" prompt
  prompt=$(extract_agent_prompt "$yaml_file")
  if ! grep -qF -- "$needle" <<<"$prompt"; then
    echo "   ❌ ${yaml_file}: expected prompt to contain: ${needle}"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "🧪 Testing scheduled-task agentPrompt extraction..."

# config-drift.yaml must retain all six numbered steps, not just the intro.
CONFIG_DRIFT_YAML="${PROJECT_DIR}/sre-config/tasks/config-drift.yaml"
assert_contains "$CONFIG_DRIFT_YAML" "1. Resolve the backend and frontend Container Apps"
assert_contains "$CONFIG_DRIFT_YAML" "2. Verify backend environment variables match expected values"
assert_contains "$CONFIG_DRIFT_YAML" "3. Verify container resource limits"
assert_contains "$CONFIG_DRIFT_YAML" "4. Verify deployment revision and image consistency"
assert_contains "$CONFIG_DRIFT_YAML" "5. Query Container App WRITE activity for the previous 7 days"
assert_contains "$CONFIG_DRIFT_YAML" "6. If drift is detected, use the incident-handler subagent"

# Every other task YAML must also retain content past its first blank line.
# Assumption: as of this writing, every task prompt in sre-config/tasks/
# uses numbered steps (this is the format documented in SRE-AGENT-SETUP.md).
# If a future task prompt uses a different structure (e.g. free-form prose
# with no numbered list), update this check accordingly.
for f in "${PROJECT_DIR}"/sre-config/tasks/*.yaml; do
  [ "$f" = "$CONFIG_DRIFT_YAML" ] && continue
  prompt_lines=$(extract_agent_prompt "$f" | grep -c '^[0-9]\+\.' || true)
  if [ "$prompt_lines" -lt 2 ]; then
    echo "   ❌ ${f}: expected multiple numbered steps, found ${prompt_lines}"
    FAILURES=$((FAILURES + 1))
  fi
done

if [ "$FAILURES" -eq 0 ]; then
  echo "   ✅ All scheduled-task prompts parsed in full"
  exit 0
else
  echo "   ❌ ${FAILURES} check(s) failed"
  exit 1
fi
