#!/usr/bin/env bash
#
# extract-screenshots.sh <path/to/Result.xcresult> <output_dir>
#
# Pulls the screenshots out of an xcresult bundle and renames them from the
# names the tests gave them, so a file arrives as
#
#   FIG-05-02b-appearance.png
#
# rather than an opaque identifier.
#
# Two extraction routes are tried, because the xcresulttool interface changed
# in Xcode 16 and this has to keep working either way. The raw bundle is
# uploaded by CI regardless, so nothing is lost if both fail.
#
# Deliberately not `set -e`: a failed route must fall through to the next one.
set -uo pipefail

XCRESULT="${1:?usage: extract-screenshots.sh <path.xcresult> <output_dir>}"
OUT="${2:-screenshots}"

mkdir -p "$OUT"
RAW="$OUT/_raw"
rm -rf "$RAW"
mkdir -p "$RAW"

echo "=============== extracting from $XCRESULT ==============="

ROUTE=""

# ---- Route 1: the exporter added in Xcode 16 -----------------------------
echo "Route 1: xcresulttool export attachments"
if xcrun xcresulttool export attachments \
      --path "$XCRESULT" \
      --output-path "$RAW" 2>"$OUT/route1-error.txt"; then
  if [ -f "$RAW/manifest.json" ]; then
    ROUTE="export-attachments"
    echo "Route 1 succeeded."
  else
    echo "Route 1 ran but produced no manifest.json."
  fi
else
  echo "Route 1 failed:"
  sed 's/^/    /' "$OUT/route1-error.txt"
fi

# ---- Route 2: the legacy graph API ---------------------------------------
if [ -z "$ROUTE" ]; then
  echo "Route 2: xcresulttool get --legacy"
  if xcrun xcresulttool get --legacy --format json \
        --path "$XCRESULT" > "$OUT/_legacy-root.json" 2>"$OUT/route2-error.txt"; then
    ROUTE="legacy"
    echo "Route 2 produced a root object. Walking it."
  else
    echo "Route 2 failed:"
    sed 's/^/    /' "$OUT/route2-error.txt"
  fi
fi

if [ -z "$ROUTE" ]; then
  echo "Both extraction routes failed. The raw .xcresult is still uploaded."
  exit 0
fi

# ---- Rename into readable filenames --------------------------------------
python3 - "$RAW" "$OUT" "$ROUTE" "$XCRESULT" <<'PY'
import json, os, re, shutil, subprocess, sys

raw, out, route, xcresult = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

pairs = []   # (source_path, human_name)

def walk(node):
    """Collect every {exportedFileName, suggestedHumanReadableName} pair,
    wherever the manifest happens to nest them."""
    if isinstance(node, dict):
        exported = node.get("exportedFileName")
        human = node.get("suggestedHumanReadableName") or node.get("name")
        if exported:
            pairs.append((os.path.join(raw, exported), human or exported))
        for value in node.values():
            walk(value)
    elif isinstance(node, list):
        for item in node:
            walk(item)

if route == "export-attachments":
    with open(os.path.join(raw, "manifest.json")) as handle:
        walk(json.load(handle))
else:
    # Legacy route: fall back to whatever files landed in the raw directory.
    for name in sorted(os.listdir(raw)):
        pairs.append((os.path.join(raw, name), name))

def safe(name):
    """Turn an attachment's human readable name into a filename.

    The exporter hands back names shaped like

        SHOT__FIG-05-02b-appearance_0_9EA90FA6-....png

    so the marker prefix, the attachment index and the UUID all have to come
    off, and the extension has to come off before a new one is appended.
    Leaving any of that in produced `...png.png` names on the second run.
    """
    name = re.sub(r"^SHOT__", "", name)
    # Strip the extension, then the index and UUID, then any extension the
    # first pass left buried behind them. Text attachments carry the extension
    # inside their own name, so a single pass is not enough.
    for _ in range(2):
        name = re.sub(r"\.(png|jpg|jpeg|heic|txt|json)$", "", name, flags=re.I)
        name = re.sub(r"_\d+_[0-9A-Fa-f]{8}-[0-9A-Fa-f-]{27,}$", "", name)
    name = re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip("-")
    return name or "unnamed"

kept, skipped, missing = [], 0, 0
for source, human in pairs:
    if not os.path.isfile(source):
        missing += 1
        continue
    # Keep only the captures the tests named. XCTest adds its own automatic
    # screenshots and those would drown the real ones.
    is_text = human.startswith("rows-") or ".txt" in human.lower()
    if not human.startswith("SHOT__") and not is_text:
        skipped += 1
        continue

    base = safe(human)
    extension = ".txt" if is_text else (os.path.splitext(source)[1] or ".png")

    target = os.path.join(out, base + extension)
    counter = 2
    while os.path.exists(target):
        target = os.path.join(out, "%s-%d%s" % (base, counter, extension))
        counter += 1

    shutil.copy2(source, target)
    kept.append(target)

print("")
print("kept %d file(s), skipped %d automatic attachment(s), %d listed but absent"
      % (len(kept), skipped, missing))
print("")

# ---- Report the real pixel size of every PNG -----------------------------
report = []
for path in sorted(kept):
    if not path.lower().endswith(".png"):
        continue
    try:
        info = subprocess.run(
            ["sips", "-g", "pixelWidth", "-g", "pixelHeight", path],
            capture_output=True, text=True, check=True).stdout
        width = re.search(r"pixelWidth:\s*(\d+)", info)
        height = re.search(r"pixelHeight:\s*(\d+)", info)
        size = "%sx%s" % (width.group(1), height.group(1)) if width and height else "unknown"
    except Exception as error:                      # noqa: BLE001
        size = "could not read (%s)" % error
    line = "%-8s  %s" % (size, os.path.basename(path))
    report.append(line)
    print(line)

with open(os.path.join(out, "capture-sizes.txt"), "w") as handle:
    handle.write("Pixel dimensions of every extracted screenshot.\n")
    handle.write("The iPhone 18 Pro native size is 1206x2622.\n\n")
    handle.write("\n".join(report) + "\n")
PY

rm -rf "$RAW"
echo ""
echo "=============== files in $OUT ==============="
ls -l "$OUT"
