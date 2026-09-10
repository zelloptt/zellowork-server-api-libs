#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
OUT="${TMPDIR:-/tmp}/zw-swift-live-$$"
SWIFT_DIR="$(cd "$(dirname "$0")" && pwd)"

swiftc \
  -import-objc-header "$SWIFT_DIR/bridging.h" \
  -o "$OUT" \
  "$ROOT/swift/ZelloAPI.swift" \
  "$SWIFT_DIR/main.swift"

exec "$OUT"
