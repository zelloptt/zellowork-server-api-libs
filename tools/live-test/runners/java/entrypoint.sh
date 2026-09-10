#!/bin/bash
set -euo pipefail
OUT=/tmp/zw-java-live
mkdir -p "$OUT"
javac -cp /opt/json.jar -d "$OUT" \
  /workspace/java/ResultCompletionHandler.java \
  /workspace/java/ZelloAPI.java \
  /runner/LiveTestMain.java
exec java -cp "$OUT:/opt/json.jar" LiveTestMain
