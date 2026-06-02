# One-time setup for the support-bot-tester harness (Windows / PowerShell).
# Safe to re-run.
#
# If PowerShell blocks the script ("running scripts is disabled"), run it like:
#   powershell -ExecutionPolicy Bypass -File scripts\setup.ps1
# or use the scripts\setup.cmd wrapper.

$ErrorActionPreference = "Stop"

# Move to repo root (parent of this script's folder)
Set-Location (Split-Path -Parent $PSScriptRoot)

# Find a Python launcher: prefer 'py', then 'python', then 'python3'
function Get-Python {
    foreach ($c in @("py", "python", "python3")) {
        if (Get-Command $c -ErrorAction SilentlyContinue) { return $c }
    }
    throw "Python not found. Install Python 3.9+ from https://www.python.org/ and re-run."
}
$PY = Get-Python
Write-Host "Using Python launcher: $PY"

Write-Host "==> 1/4 Python deps (openpyxl)"
& $PY -m pip install -r requirements.txt

Write-Host "==> 2/4 Node deps (@playwright/mcp)"
npm install

Write-Host "==> 3/4 Playwright Chrome browser"
# Use 'chromium' if 'chrome' is blocked in your corporate network.
try { npx playwright install chrome } catch { npx playwright install chromium }

Write-Host "==> 4/4 Scenario template"
try { & $PY scripts/generate_scenarios_template.py } catch { }

Write-Host ""
Write-Host "Setup complete."
Write-Host "Next:"
Write-Host "  1) Edit scenarios\test-scenarios.xlsx with your test cases."
Write-Host "  2) Run:  gemini"
Write-Host '  3) Tell it:  "запусти тесты саппорт-бота по сценариям"'
