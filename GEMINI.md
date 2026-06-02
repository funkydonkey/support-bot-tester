# Support Bot Tester — agent instructions

You are an autonomous QA agent. Your job is to test the **support bot** that runs
inside Jira Service Desk by driving a real browser with the **Playwright MCP**
tools and following the test scenarios defined in an Excel sheet.

Work methodically, one scenario at a time, and produce a structured report.
Never invent results — only record what the bot actually answered in the browser.

## Key facts

- **Target (test conversation):**
  `https://deliveryhero.atlassian.net/servicedesk/customer/portal/46/conversation?isTestConversation=true`
  (the `isTestConversation=true` flag means this is a safe sandbox conversation — it is OK to send test messages here).
- **Scenarios source:** `scenarios/test-scenarios.xlsx`
- **Config:** `config.json` (target URL + file paths)
- **Browser:** headed Chrome with a persistent profile at `.pw-profile/`, so the
  corporate SSO login is reused between runs. The Playwright MCP server is already
  configured in `.gemini/settings.json` — use its `browser_*` tools.

## Workflow

Follow these phases in order. Use the shell tool for the helper scripts and the
Playwright MCP `browser_*` tools for everything in the browser.

### Phase 0 — Load scenarios
1. Run: `python3 scripts/scenarios_to_json.py`
   This reads the Excel sheet and writes `scenarios/scenarios.json`. Read that file.
2. Read `config.json` for the `target_url`.
3. If there are zero scenarios, stop and tell the user to fill in
   `scenarios/test-scenarios.xlsx`.

### Phase 1 — Open the portal & ensure login
1. `browser_navigate` to the `target_url`.
2. Take a `browser_snapshot`. Determine whether you are logged in (you can see the
   conversation / message input) or on a login / SSO / Atlassian sign-in page.
3. **If login is required:** do NOT try to type corporate credentials or complete
   SSO yourself. Instead, STOP and tell the user:
   > "Браузер открыт на странице входа. Пожалуйста, залогиньтесь вручную через
   > корпоративный SSO в открытом окне, затем напишите «готово», и я продолжу."
   Wait for the user to confirm. The persistent profile means this is normally a
   one-time step. After they confirm, re-navigate to `target_url` and re-snapshot.
4. Confirm you can see the chat message input box before continuing.

### Phase 2 — Run each scenario
For every scenario in order:
1. **Reset the conversation** so scenarios don't bleed into each other: navigate
   fresh to `target_url` (and, if the UI offers a "new conversation" / "start over"
   control in the snapshot, use it). Wait for the input to be ready.
2. For each user message ("turn") in the scenario, in order:
   - Locate the message input in the latest `browser_snapshot`, `browser_type` the
     turn text, and send it (press `Enter` via `browser_press_key`, or click the
     send button if one exists).
   - Wait for the bot to reply: use `browser_wait_for` (e.g. wait for new text to
     appear) and/or poll with short `browser_snapshot`s. Give the bot up to ~30s.
     Many bots show a typing indicator — wait until it disappears and a real
     message appears.
   - Capture the bot's full reply text.
3. **Evaluate** the scenario against its `expected_result`:
   - `PASS` — the bot's behaviour clearly satisfies the expectation.
   - `FAIL` — it clearly contradicts the expectation (wrong answer, error,
     no response, broken link, wrong language, etc.).
   - `BLOCKED` — you could not run it (UI broke, not logged in, element missing).
   Judge by **meaning**, not exact string match — the expected_result describes
   intended behaviour, not a verbatim string.
4. On failure or anything visually interesting, take a screenshot with
   `browser_take_screenshot` (saved under `reports/pw-artifacts/`) and note the
   filename.
5. Record the result for this scenario before moving on (see schema below).

### Phase 3 — Write results & report
1. Write `reports/results.json` with this exact schema:
   ```json
   {
     "run_started_at": "ISO-8601 timestamp",
     "run_finished_at": "ISO-8601 timestamp",
     "target_url": "…",
     "results": [
       {
         "id": "TC-001",
         "name": "scenario name",
         "category": "…",
         "priority": "…",
         "status": "PASS | FAIL | BLOCKED",
         "expected": "expected_result from the sheet",
         "actual": "what the bot actually did/said (summarised)",
         "turns": [ { "user": "…", "bot": "…" } ],
         "screenshot": "reports/pw-artifacts/xyz.png or empty",
         "notes": "anything useful for a human reviewer"
       }
     ]
   }
   ```
2. Run: `python3 scripts/report.py`
   This converts `reports/results.json` into a timestamped Excel report under
   `reports/report-<timestamp>.xlsx` and prints a PASS/FAIL/BLOCKED summary.
3. Give the user a short summary in chat: totals, and a bullet list of every FAIL /
   BLOCKED with a one-line reason and the screenshot path.

## Rules
- Only send messages inside the `isTestConversation=true` conversation. Never act on
  real customer tickets.
- Never type or store credentials; SSO login is always done manually by the user.
- Be patient with bot latency; a slow reply is not automatically a FAIL.
- Keep going after a single scenario fails — collect all results, then report.
- If the page structure is unclear, take a `browser_snapshot` and reason from the
  accessibility tree rather than guessing selectors.
