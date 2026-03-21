#!/usr/bin/env bash
set -euo pipefail

# conductor-status.sh — List all sessions with status, reap dead ones
# Usage: conductor-status.sh

CONDUCTOR_DIR="$HOME/.conductor"
MANIFEST="$CONDUCTOR_DIR/manifest.jsonl"

if [[ ! -f "$MANIFEST" ]]; then
  echo "No sessions found (manifest doesn't exist)"
  exit 0
fi

# Build current state: for each slug, find the latest event
declare -A SLUGS STATUS DESCS CWDS TMUX_NAMES SESSION_IDS LAST_TS

while IFS= read -r line; do
  slug=$(echo "$line" | jq -r '.slug // empty')
  event=$(echo "$line" | jq -r '.event // empty')
  [[ -z "$slug" || -z "$event" ]] && continue

  SLUGS[$slug]=1
  LAST_TS[$slug]=$(echo "$line" | jq -r '.ts // empty')

  case "$event" in
    spawn)
      STATUS[$slug]="running"
      DESCS[$slug]=$(echo "$line" | jq -r '.desc // ""')
      CWDS[$slug]=$(echo "$line" | jq -r '.cwd // ""')
      TMUX_NAMES[$slug]=$(echo "$line" | jq -r '.tmux // ""')
      SESSION_IDS[$slug]=$(echo "$line" | jq -r '.claude_session_id // ""')
      ;;
    resume)
      STATUS[$slug]="running"
      ;;
    suspend)
      STATUS[$slug]="suspended"
      ;;
    route)
      # Don't change status, just update last activity
      ;;
  esac
done < "$MANIFEST"

# Check actual tmux state and reap dead sessions
TS=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
for slug in "${!SLUGS[@]}"; do
  if [[ "${STATUS[$slug]:-}" == "running" ]]; then
    tmux_name="${TMUX_NAMES[$slug]:-conductor-${slug}}"
    if ! tmux has-session -t "$tmux_name" 2>/dev/null; then
      STATUS[$slug]="suspended"
      echo "{\"event\":\"suspend\",\"slug\":\"${slug}\",\"reason\":\"tmux_dead\",\"ts\":\"${TS}\"}" >> "$MANIFEST"
    fi
  fi
done

# Output formatted table
printf "%-20s %-12s %-40s %s\n" "SESSION" "STATUS" "DESCRIPTION" "LAST ACTIVITY"
printf "%-20s %-12s %-40s %s\n" "-------" "------" "-----------" "-------------"

for slug in $(echo "${!SLUGS[@]}" | tr ' ' '\n' | sort); do
  status="${STATUS[$slug]:-unknown}"
  desc="${DESCS[$slug]:-}"
  last="${LAST_TS[$slug]:-}"
  # Truncate desc if too long
  if [[ ${#desc} -gt 38 ]]; then
    desc="${desc:0:35}..."
  fi
  printf "%-20s %-12s %-40s %s\n" "$slug" "$status" "$desc" "$last"
done
