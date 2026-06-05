#!/usr/bin/env bash
# monitor_ram.sh - RAM watchdog for skill-optimizer rerun.
# Polls every 5s. Auto-kills run_loop + claude -p processes if RAM available drops below threshold.
# Log peak RAM to /tmp/skill-optimizer-ram-<timestamp>.log.
#
# Usage:
#   bash _scripts/monitor_ram.sh &
#   MONITOR_PID=$!
#   # ... run optimizer ...
#   kill $MONITOR_PID 2>/dev/null
#
# Why: prevent recurrence of 2026-05-16 reboot loop where 6 parallel run_loop spawned
# 20+ Opus subprocesses, drove RAM <1%, triggered earlyoom cascade.
# See Engineering/AI-Memory/failures/2026-05-16-211800_*.md for context.

set -uo pipefail

KILL_THRESHOLD_MB=${KILL_THRESHOLD_MB:-2000}
INTERVAL=${INTERVAL:-5}
LOGFILE=${LOGFILE:-/tmp/skill-optimizer-ram-$(date +%Y%m%d_%H%M%S).log}
PEAK_USED=0

echo "RAM watchdog started. Threshold=${KILL_THRESHOLD_MB}MB Interval=${INTERVAL}s Log=$LOGFILE" >&2
echo "timestamp,avail_mb,used_mb,swap_used_mb,claude_procs,run_loop_procs" > "$LOGFILE"

trap 'echo "Monitor stopping. Peak RAM used: ${PEAK_USED}MB. Log: $LOGFILE" >&2; exit 0' INT TERM

while true; do
  AVAIL=$(free -m | awk '/^Mem:/{print $7}')
  USED=$(free -m  | awk '/^Mem:/{print $3}')
  SWAP=$(free -m  | awk '/^Swap:/{print $3}')
  CLAUDE_N=$(pgrep -f 'claude -p' | wc -l)
  LOOP_N=$(pgrep -f 'run_loop' | wc -l)
  TS=$(date '+%H:%M:%S')

  [ "$USED" -gt "$PEAK_USED" ] && PEAK_USED=$USED

  echo "$TS,$AVAIL,$USED,$SWAP,$CLAUDE_N,$LOOP_N" >> "$LOGFILE"

  if [ "$AVAIL" -lt "$KILL_THRESHOLD_MB" ]; then
    echo "$(date) CRITICAL: only ${AVAIL}MB available (threshold ${KILL_THRESHOLD_MB}MB). Killing run_loop + claude -p." | tee -a "$LOGFILE" >&2
    pkill -f 'run_loop' 2>/dev/null
    sleep 1
    pkill -f 'claude -p' 2>/dev/null
    echo "$(date) Killed. Peak RAM used was ${PEAK_USED}MB." | tee -a "$LOGFILE" >&2
    exit 1
  fi

  sleep "$INTERVAL"
done
