#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
OUT="${TMPDIR:-/tmp}/zw-swift-live-$$"
SWIFT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zw-swift-src.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# Canonical sources target Swift 3; apply minimal patches so modern swiftc can build for the smoke runner only.
sed \
  -e 's/open static let version/public static let version/' \
  -e 's/deallocate(capacity: digestLen)/deallocate()/' \
  "$ROOT/swift/ZelloAPI.swift" > "$TMP/ZelloAPI.swift"

swiftc \
  -import-objc-header "$SWIFT_DIR/bridging.h" \
  -o "$OUT" \
  "$TMP/ZelloAPI.swift" \
  "$SWIFT_DIR/main.swift"

exec "$OUT"
