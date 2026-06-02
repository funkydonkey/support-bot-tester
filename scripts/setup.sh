#!/usr/bin/env bash
# One-time setup for the support-bot-tester harness.
# Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> 1/4 Python deps (openpyxl)"
if command -v pip3 >/dev/null 2>&1; then
  pip3 install -r requirements.txt
else
  python3 -m pip install -r requirements.txt
fi

echo "==> 2/4 Node deps (@playwright/mcp)"
npm install

echo "==> 3/4 Playwright Chrome browser"
# Installs the Chrome build Playwright drives. Use 'chromium' if 'chrome' is blocked.
npx playwright install chrome || npx playwright install chromium

echo "==> 4/4 Scenario template"
python3 scripts/generate_scenarios_template.py || true

echo
echo "Setup complete."
echo "Next:"
echo "  1) Edit scenarios/test-scenarios.xlsx with your test cases."
echo "  2) Run:  gemini"
echo "  3) Tell it:  \"запусти тесты саппорт-бота по сценариям\""
