#!/usr/bin/env bash
# Print an xcodebuild -destination for the newest available iPhone simulator,
# e.g. "platform=iOS Simulator,id=<UDID>". Exits non-zero if none is found.
# Set IOS_DESTINATION to skip detection and use your own destination.
set -euo pipefail

if [ -n "${IOS_DESTINATION:-}" ]; then
  printf '%s\n' "$IOS_DESTINATION"
  exit 0
fi

xcrun simctl list devices available -j | python3 -c '
import json, re, sys

devices = json.load(sys.stdin).get("devices", {})

def version(runtime):
    # com.apple.CoreSimulator.SimRuntime.iOS-26-1 -> (26, 1)
    match = re.search(r"\.iOS-([\d-]+)$", runtime)
    return tuple(int(part) for part in match.group(1).split("-")) if match else None

candidates = [
    (version(runtime), device["name"], device["udid"])
    for runtime, runtime_devices in devices.items()
    if version(runtime) is not None
    for device in runtime_devices
    if device.get("isAvailable", True) and device.get("name", "").startswith("iPhone")
]
if not candidates:
    sys.exit("No available iPhone simulator found (see: xcrun simctl list devices available)")

_, name, udid = max(candidates)
print(f"Using {name}", file=sys.stderr)
print(f"platform=iOS Simulator,id={udid}")
'
