# shellcheck shell=bash
# =============================================================================
# extract_agent_prompt.sh — Shared helper for parsing the multi-line
# "agentPrompt: |" block out of a ScheduledTask YAML file.
#
# Sourced by both post-provision.sh (production deployment) and
# test-scheduled-task-prompt-parsing.sh (regression test) so the two never
# drift apart.
#
# Captures every line — including blank lines — until the next top-level
# "key:" field (exactly 2-space indent, per the task YAML's fixed
# structure) or end of file, so multi-paragraph prompts aren't truncated
# at the first blank line. Prompt body lines are always indented 4+
# spaces, so a bare 2-space "word:" line only ever marks a sibling key.
# The key-termination pattern additionally requires the colon be followed
# by a space, quote, or end-of-line to reduce false-positive matches on
# prompt content that merely resembles a key.
#
# INVARIANT: this only works correctly if "agentPrompt: |" is the LAST
# field in the YAML "spec:" map (as it is in every file under
# sre-config/tasks/ today) — otherwise the block would run past the end
# of the intended prompt. test-scheduled-task-prompt-parsing.sh asserts
# this invariant for every task YAML; any new caller of this helper
# should keep that check in place or add an equivalent guard.
# =============================================================================

extract_agent_prompt() {
  local yaml_file="$1"
  awk '
    /^  agentPrompt: \|/ { capture=1; next }
    capture && /^  [A-Za-z_]+:( |"|$)/ { capture=0 }
    capture { print }
  ' "$yaml_file" | sed 's/^    //'
}
