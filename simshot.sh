#!/usr/bin/env bash
#
# simshot.sh
#
# Boots an iOS Simulator device and captures reference screenshots of the
# Home Screen and the Settings app, then reports which apps the runtime
# actually ships with.
#
# Useful for documentation writers, accessibility auditors, localisation
# testers and anyone who needs to know what a given iOS runtime looks like
# without owning every device.
#
# Usage:
#   ./simshot.sh ["Device Type Name"] ["Runtime Name"] [output_dir]
#
# Defaults:
#   Device Type : iPhone 18 Pro
#   Runtime     : iOS 27.0
#   Output      : ./out
#
set -euo pipefail

DEVICE_TYPE="${1:-iPhone 18 Pro}"
RUNTIME_NAME="${2:-iOS 27.0}"
OUT="${3:-out}"

mkdir -p "$OUT"

echo "==================== toolchain ===================="
xcodebuild -version
echo

echo "==================== runtimes installed ===================="
xcrun simctl list runtimes
xcrun simctl list runtimes > "$OUT/runtimes.txt"
echo

echo "==================== iPhone device types installed ===================="
xcrun simctl list devicetypes | grep -i iphone || true
xcrun simctl list devicetypes > "$OUT/devicetypes.txt"
echo

# ---- resolve the identifiers we need -------------------------------------

DT_ID=$(
  xcrun simctl list devicetypes --json \
  | python3 -c '
import json,sys
want = sys.argv[1]
data = json.load(sys.stdin)["devicetypes"]
match = [d for d in data if d["name"] == want]
if not match:
    sys.stderr.write("Device type not found: %s\n" % want)
    sys.stderr.write("Available iPhone types:\n")
    for d in data:
        if "iPhone" in d["name"]:
            sys.stderr.write("  %s\n" % d["name"])
    sys.exit(2)
print(match[0]["identifier"])
' "$DEVICE_TYPE"
)

RT_ID=$(
  xcrun simctl list runtimes --json \
  | python3 -c '
import json,sys
want = sys.argv[1]
data = json.load(sys.stdin)["runtimes"]
match = [r for r in data if r["name"] == want and r.get("isAvailable")]
if not match:
    sys.stderr.write("Runtime not found or unavailable: %s\n" % want)
    sys.stderr.write("Available runtimes:\n")
    for r in data:
        sys.stderr.write("  %s (available: %s)\n" % (r["name"], r.get("isAvailable")))
    sys.exit(2)
print(match[0]["identifier"])
' "$RUNTIME_NAME"
)

echo "Device type : $DEVICE_TYPE"
echo "            = $DT_ID"
echo "Runtime     : $RUNTIME_NAME"
echo "            = $RT_ID"
echo

# ---- create, boot, and always clean up -----------------------------------

UDID=$(xcrun simctl create "simshot-temp" "$DT_ID" "$RT_ID")
echo "Created simulator: $UDID"

cleanup() {
  echo "Cleaning up simulator $UDID"
  xcrun simctl shutdown "$UDID" >/dev/null 2>&1 || true
  xcrun simctl delete   "$UDID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Booting..."
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b
echo "Booted. Letting SpringBoard settle."
sleep 15

# ---- capture -------------------------------------------------------------

echo "==================== Home Screen ===================="
xcrun simctl io "$UDID" screenshot "$OUT/home-screen.png"
echo "Saved $OUT/home-screen.png"

echo "==================== second Home Screen page ===================="
# Many runtimes put the rest of the built-in apps on a second page or in
# App Library. This is a best effort; it is not an error if it looks the same.
xcrun simctl io "$UDID" screenshot "$OUT/home-screen-2.png" || true

echo "==================== Settings ===================="
xcrun simctl launch "$UDID" com.apple.Preferences
sleep 10
xcrun simctl io "$UDID" screenshot "$OUT/settings.png"
echo "Saved $OUT/settings.png"

# ---- the most useful output: what is actually installed ------------------

echo "==================== apps installed on this runtime ===================="
xcrun simctl listapps "$UDID" > "$OUT/installed-apps-raw.txt" 2>&1 || true

python3 - "$OUT/installed-apps-raw.txt" "$OUT/installed-apps.txt" <<'PY'
import re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
ids   = re.findall(r'CFBundleIdentifier\s*=\s*"?([A-Za-z0-9._-]+)"?\s*;', raw)
names = re.findall(r'CFBundleDisplayName\s*=\s*"?([^";]+)"?\s*;', raw)
out = sorted(set(ids))
with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write("Bundle identifiers found on this runtime (%d):\n\n" % len(out))
    for i in out:
        f.write("  %s\n" % i)
    f.write("\nDisplay names seen (%d):\n\n" % len(set(names)))
    for n in sorted(set(names)):
        f.write("  %s\n" % n.strip())
print(open(sys.argv[2], encoding="utf-8").read())
PY

echo "==================== files produced ===================="
ls -l "$OUT"
