#!/usr/bin/env bash
# Generates TimeControl.xcodeproj from project.yml, then opens it in Xcode.
# Run this on your Mac after cloning.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "XcodeGen not found. Installing via Homebrew…"
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Install it from https://brew.sh then re-run." >&2
    exit 1
  fi
  brew install xcodegen
fi

echo "Generating Xcode project…"
xcodegen generate

echo "Opening TimeControl.xcodeproj…"
open TimeControl.xcodeproj

cat <<'NOTE'

Next steps in Xcode:
  1. Select each target > Signing & Capabilities > pick your Team.
  2. Make the bundle identifiers unique (Product > every target). See README.
  3. Plug in your iPhone, select it as the run destination, and press Run (Cmd+R).

NOTE
