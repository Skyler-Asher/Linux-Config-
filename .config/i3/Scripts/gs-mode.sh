#!/usr/bin/env bash
#
# gs-mode.sh
# Lightweight controller for gammastep modes so i3 can call them.
#
# Usage:
#   gs-mode.sh normal         # Reset / Normal mode (gammastep -x)
#   gs-mode.sh minor          # Minor blue light (5700K)
#   gs-mode.sh normal_blue    # Normal blue light (5350K)
#   gs-mode.sh presleep       # Pre-sleep wind-down (3200K)
#   gs-mode.sh set <KELVIN>   # Set arbitrary kelvin, e.g. set 4000
#   gs-mode.sh status         # Show which command we ran last (best-effort)
#   gs-mode.sh help           # Show this usage
#
# Notes:
# - The script tries to be idempotent: it kills any running 'gammastep' processes
#   before applying a new -O temperature so you get a single active instance.
# - It assumes `gammastep` is installed and available in PATH.
# - If you're on Wayland and gammastep can't connect to the display, gammastep
#   itself will print an error — this script won't hide those errors.
#

set -euo pipefail

SCRIPTNAME="$(basename "$0")"
GS_CMD="$(command -v gammastep || true)"

# Ensure gammastep exists
check_gammastep() {
  # Exit with explicit message if gammastep is not present.
  if [[ -z "$GS_CMD" ]]; then
    echo "ERROR: gammastep not found in PATH. Install it or adjust PATH." >&2
    exit 2
  fi
}

# Kill any running gammastep instances (clean start).
# This prevents multiple conflicting processes.
kill_existing_gammastep() {
  # We try pkill gently; ignore errors if nothing was running.
  if command -v pkill >/dev/null 2>&1; then
    pkill -f gammastep 2>/dev/null || true
    # wait a tiny bit for processes to die
    sleep 0.06
  else
    # fallback: try to kill by pid listing
    for pid in $(ps aux | grep '[g]ammastep' | awk '{print $2}'); do
      kill "$pid" 2>/dev/null || true
    done
  fi
}

# Reset to normal (disable gammastep adjustments).
# Uses gammastep -x as requested.
set_normal() {
  # Comment: Reset display color temperature to default using -x.
  check_gammastep
  kill_existing_gammastep
  # Run reset command (does not start persistent daemon).
  "$GS_CMD" -x
  echo "Set: NORMAL (gammastep -x)"
}

# Set a specific kelvin value using gammastep -O <K>
# This starts gammastep with the requested color temperature.
set_kelvin() {
  # $1 = kelvin integer
  local kelvin="$1"
  check_gammastep
  kill_existing_gammastep
  # Start gammastep in background to maintain the temperature.
  # Redirect stdout/stderr so i3 or cron doesn't get spammed.
  nohup "$GS_CMD" -O "$kelvin" >/dev/null 2>&1 &
  disown
  echo "Set: ${kelvin}K (gammastep -O $kelvin)"
}

# Minor Blue Light mode (5700K)
set_minor_blue() {
  # Comment: Slightly cooler (more blue) than normal_blue.
  set_kelvin 5700
}

# Normal Blue Light mode (5350K)
set_normal_blue() {
  # Comment: Default 'normal' warm/cool balance requested.
  set_kelvin 5350
}

# Pre-sleep wind-down (3200K)
set_presleep() {
  # Comment: Evening wind-down temperature; run at or before 20:00 IST as desired.
  set_kelvin 3200
}

# Simple status helper: report last applied mode (best-effort).
# We can't reliably read gammastep's last args, so we track by checking current processes.
status() {
  if pgrep -f gammastep >/dev/null 2>&1; then
    # We don't have the original args; report that gammastep is running.
    echo "gammastep is running (process present). To find exact setting, check process table or /var/log."
    ps -ef | grep '[g]ammastep' | sed -n '1,5p'
  else
    echo "gammastep not running. Display likely in NORMAL (reset) state."
  fi
}

# Help text
usage() {
 # sed -n '1,120p' "$0" | sed -n '1,120p' | awk 'NR>1 && NR<200{print}'
 #
 echo  " # Usage:
#   gs-mode.sh normal         # Reset / Normal mode (gammastep -x)
#   gs-mode.sh minor          # Minor blue light (5700K)
#   gs-mode.sh normal_blue    # Normal blue light (5350K)
#   gs-mode.sh presleep       # Pre-sleep wind-down (3200K)
#   gs-mode.sh set <KELVIN>   # Set arbitrary kelvin, e.g. set 4000
#   gs-mode.sh status         # Show which command we ran last (best-effort)
#   gs-mode.sh help           # Show this usage
#" 
}

# Main dispatcher
main() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    normal)
      set_normal
      ;;
    minor)
      set_minor_blue
      ;;
    normal_blue)
      set_normal_blue
      ;;
    presleep)
      set_presleep
      ;;
    set)
      if [[ $# -ne 2 ]]; then
        echo "ERROR: 'set' requires a kelvin value, e.g. set 4000" >&2
        exit 2
      fi
      # basic validation: number only
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "ERROR: kelvin must be a number." >&2
        exit 2
      fi
      set_kelvin "$2"
      ;;
    status)
      status
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "ERROR: unknown command: $1" >&2
      echo "Run: $SCRIPTNAME help"
      exit 2
      ;;
  esac
}

# Run main with all args
main "$@"

