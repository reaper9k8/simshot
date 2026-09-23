#!/usr/bin/env python3
"""Resolve a simulator device type or runtime name to its identifier.

Reads `xcrun simctl list ... --json` on standard input.

    xcrun simctl list devicetypes --json | resolve.py devicetype "iPhone 18 Pro"
    xcrun simctl list runtimes    --json | resolve.py runtime    "iOS 27.0"

Exits 2 and prints what is available when the name is not found, so a CI run
fails with a useful message instead of an empty variable.
"""
import json
import sys


def main() -> int:
    if len(sys.argv) != 3:
        sys.stderr.write("usage: resolve.py devicetype|runtime <name>\n")
        return 2

    kind, want = sys.argv[1], sys.argv[2]
    data = json.load(sys.stdin)

    if kind == "devicetype":
        items = data["devicetypes"]
    elif kind == "runtime":
        items = [r for r in data["runtimes"] if r.get("isAvailable")]
    else:
        sys.stderr.write("unknown kind: %s\n" % kind)
        return 2

    match = [i for i in items if i.get("name") == want]
    if not match:
        sys.stderr.write("Not found: %s\nAvailable:\n" % want)
        for i in items:
            sys.stderr.write("  %s\n" % i.get("name"))
        return 2

    print(match[0]["identifier"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
