#!/usr/bin/env bash
#
# make-sim.sh
#
# Creates and boots a simulator, then prints its UDID on standard output.
# Everything else this script says goes to standard error, so the caller can
# capture the UDID cleanly:
#
#   UDID=$(./make-sim.sh "iPhone 18 Pro" "iOS 27.0" simshot-nav)
#
set -euo pipefail

DEVICE_TYPE="${1:-iPhone 18 Pro}"
RUNTIME_NAME="${2:-iOS 27.0}"
SIM_NAME="${3:-simshot-nav}"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DT_ID=$(xcrun simctl list devicetypes --json \
        | python3 "$HERE/tools/resolve.py" devicetype "$DEVICE_TYPE")
RT_ID=$(xcrun simctl list runtimes --json \
        | python3 "$HERE/tools/resolve.py" runtime "$RUNTIME_NAME")

echo "Device type : $DEVICE_TYPE = $DT_ID" >&2
echo "Runtime     : $RUNTIME_NAME = $RT_ID" >&2

# Remove a leftover of the same name from an earlier run on this machine.
xcrun simctl delete "$SIM_NAME" >/dev/null 2>&1 || true

UDID=$(xcrun simctl create "$SIM_NAME" "$DT_ID" "$RT_ID")
echo "Created     : $UDID" >&2

xcrun simctl boot "$UDID" >&2
xcrun simctl bootstatus "$UDID" -b >&2
echo "Booted. Letting SpringBoard settle." >&2
sleep 15

echo "$UDID"
