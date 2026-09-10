#!/bin/bash
set -euo pipefail
dotnet restore /smoke/Smoke.csproj
exec dotnet run --project /smoke/Smoke.csproj -c Release --no-restore
