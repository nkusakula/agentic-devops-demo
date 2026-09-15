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

# shellcheck source=lib/extract_agent_prompt.sh
source "$SCRIPT_DIR/lib/extract_agent_prompt.sh"

FAILURES=0

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

# Every task YAML must retain its full agentPrompt block, not just the
# intro line before the first blank line. This check is format-agnostic
# and independent of extract_agent_prompt's key-termination regex: it
# counts every raw line from "agentPrompt: |" to end-of-file (the field
# is always last in these task YAMLs) using a simple marker-based tail,
# then asserts the extractor returns the same number of lines. This
# directly detects the historical truncation bug regardless of whether
# a prompt uses numbered steps.
for f in "${PROJECT_DIR}"/sre-config/tasks/*.yaml; do
  raw_lines=$(awk '/^  agentPrompt: \|/ { found=1; next } found { print }' "$f" | wc -l)
  extracted_lines=$(extract_agent_prompt "$f" | wc -l)
  if [ "$extracted_lines" -ne "$raw_lines" ]; then
    echo "   ❌ ${f}: extracted ${extracted_lines} line(s), expected ${raw_lines} (possible truncation)"
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
