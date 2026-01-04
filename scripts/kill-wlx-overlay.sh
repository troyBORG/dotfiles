#!/usr/bin/env bash
set -uo pipefail

PROCESS="wlx-overlay-s"
CMD="wlx-overlay-s --replace"

echo "Checking for running $PROCESS..."

# pgrep returns 1 if no processes found, which is fine
pids=$(pgrep -u "${USER:-$(id -un)}" "$PROCESS" 2>/dev/null || true)

if [ -n "$pids" ]; then
  echo "Found $PROCESS PID(s): $pids"
  echo "Stopping..."
  kill $pids 2>/dev/null || true
  sleep 1
fi

still_running=$(pgrep -u "${USER:-$(id -un)}" "$PROCESS" 2>/dev/null || true)
if [ -n "$still_running" ]; then
  echo "Force stopping remaining PID(s): $still_running"
  kill -9 $still_running 2>/dev/null || true
  sleep 1
fi

echo "Starting $PROCESS..."
exec $CMD
