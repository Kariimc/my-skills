#!/bin/bash
# Optional upgrade: install Playwright (Python) for higher-quality full-page screenshots.
# The harvester works WITHOUT this (headless Chromium CLI + stdlib). Run once on a
# surface with open web. Reuses the already-present Chromium — do NOT run
# `playwright install` (PLAYWRIGHT_BROWSERS_PATH is already set on this box).
set -e
echo "Installing Playwright (Python)..."
python3 -m pip install --user playwright
echo
echo "Done. The harvester auto-detects Playwright and uses it for screenshots."
echo "Chromium is already at: ${PLAYWRIGHT_CHROMIUM:-/opt/pw-browsers/chromium}"
echo "If your Chromium is elsewhere, set PLAYWRIGHT_CHROMIUM=/path/to/chromium"
