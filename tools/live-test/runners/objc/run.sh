#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
OUT="${TMPDIR:-/tmp}/zw-objc-live-$$"
OBJC_DIR="$(cd "$(dirname "$0")" && pwd)"

clang -fobjc-arc \
  -framework Foundation \
  -I "$ROOT/objective-c" \
  -o "$OUT" \
  "$ROOT/objective-c/ZelloAPI.m" \
  "$OBJC_DIR/main.m"

exec "$OUT"
