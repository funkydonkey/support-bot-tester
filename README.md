# Support Bot Tester 🤖🧪

Готовый репозиторий, чтобы **Gemini CLI** через **Playwright MCP** сам тестировал
саппорт-бота в Jira Service Desk по сценариям из Excel-таблицы.

Идея: вы клонируете репо → один раз ставите зависимости → запускаете `gemini` →
говорите «прогони тесты». Дальше агент сам открывает браузер, шлёт боту сообщения
из таблицы, читает ответы, сравнивает с ожидаемым и собирает Excel-отчёт.

Тестовая беседа (sandbox):
`https://deliveryhero.atlassian.net/servicedesk/customer/portal/46/conversation?isTestConversation=true`
— флаг `isTestConversation=true` означает, что это безопасная тестовая беседа.

---

## Что внутри

```
support-bot-tester/
├── GEMINI.md                  ← инструкции для агента (его "скилл" тестировщика)
├── .gemini/settings.json      ← MCP-сервер Playwright (браузер) для Gemini CLI
├── config.json                ← URL тестовой беседы и пути к файлам
├── scenarios/
│   └── test-scenarios.xlsx     ← ВАШИ тест-кейсы (редактируете в Excel)
├── scripts/
│   ├── setup.sh                       ← установка зависимостей (one-time)
│   ├── generate_scenarios_template.py ← создать/пересоздать шаблон Excel
│   ├── scenarios_to_json.py           ← Excel → scenarios.json (читает агент)
│   └── report.py                      ← results.json → Excel-отчёт
├── prompts/run-tests.md       ← готовый промпт для запуска
├── reports/                   ← сюда падают отчёты и скриншоты
├── requirements.txt           ← Python-зависимости (openpyxl)
└── package.json               ← Node-зависимости (@playwright/mcp)
```

---

## Требования

- **Node.js 18+** и **npm** (для Playwright MCP).
- **Python 3.9+** и **pip** (для работы с Excel).
- **Gemini CLI** — установлен и авторизован:
  ```bash
  npm install -g @google/gemini-cli
  gemini   # один раз: пройдите вход / задайте API-ключ
  ```

---

## Установка (один раз)

```bash
git clone <URL-этого-репозитория>
cd support-bot-tester

# поставит openpyxl, @playwright/mcp, браузер Chrome и создаст шаблон Excel
bash scripts/setup.sh
```

> Если в корпоративной сети `npx playwright install chrome` заблокирован, скрипт
> попробует `chromium`. Можно также указать уже установленный браузер — см.
> «Тонкая настройка» ниже.

---

## Как пользоваться

### 1. Опишите тест-кейсы в Excel
Откройте `scenarios/test-scenarios.xlsx` (лист **Scenarios**). Одна строка — один
сценарий. Колонки:

| Колонка | Что писать |
|---|---|
| **ID** | уникальный, напр. `TC-001` |
| **Scenario** | короткое название |
| **Category** | группа (Greeting / Orders / Refund / Escalation …) |
| **Priority** | High / Medium / Low |
| **Preconditions** | что должно быть верно перед тестом |
| **User Messages** | сообщение(я) боту. Для диалога из нескольких реплик — каждая реплика с новой строки в ячейке (Alt+Enter) **или** через ` \|\| ` |
| **Expected Result** | ожидаемое поведение бота словами (агент сравнивает по смыслу, не дословно) |
| **Notes** | заметки |

В шаблоне уже есть 10 примеров — замените их своими.

### 2. Запустите агента
```bash
gemini
```
И напишите (или вставьте из `prompts/run-tests.md`):

> Протестируй саппорт-бота в Jira Service Desk по инструкции из GEMINI.md.

`GEMINI.md` подхватывается автоматически, поэтому агент знает весь сценарий работы.

### 3. Войдите через SSO (один раз)
При первом запуске откроется окно Chrome. Если потребуется корпоративный вход —
**агент остановится и попросит вас залогиниться вручную** в этом окне. После входа
напишите в чат «готово». Сессия сохраняется в `.pw-profile/`, поэтому в следующие
разы вход обычно не нужен.

### 4. Получите отчёт
По окончании агент:
- запишет `reports/results.json`,
- сгенерирует `reports/report-<дата-время>.xlsx` (цветной статус PASS/FAIL/BLOCKED,
  ожидаемое vs фактическое, полный диалог, ссылки на скриншоты),
- и выдаст краткое резюме в чат.

---

## Как это работает

1. `scenarios_to_json.py` читает Excel → `scenarios/scenarios.json`.
2. Gemini CLI поднимает **Playwright MCP** (`@playwright/mcp`) — это даёт агенту
   инструменты `browser_navigate`, `browser_snapshot`, `browser_type`,
   `browser_click` и т.д.
3. По `GEMINI.md` агент открывает тестовую беседу, для каждого сценария шлёт реплики,
   ждёт ответ бота, оценивает PASS/FAIL/BLOCKED, при провале делает скриншот.
4. `report.py` превращает результаты в Excel-отчёт.

Браузер запускается с **постоянным профилем** (`.pw-profile/`), поэтому корпоративный
SSO-вход переживает перезапуски. Логин всегда делаете вы вручную — агент **не**
вводит и не хранит учётные данные.

---

## Тонкая настройка

Файл `.gemini/settings.json`, аргументы Playwright MCP:

- `--browser=chrome` → можно `msedge`, `firefox`, `webkit`.
- по умолчанию **headed** (видимое окно). Для фоновых прогонов после первого входа
  добавьте `--headless`.
- `--user-data-dir=./.pw-profile` → постоянный профиль с вашей сессией.
- `--executable-path=/путь/к/браузеру` → если нужен конкретный корпоративный браузер.
- `--isolated` → запуск без сохранения профиля (тогда логин каждый раз заново).

URL тестовой беседы меняется в `config.json` (`target_url`).

Пересоздать шаблон Excel (перезапишет ваши данные!):
```bash
python3 scripts/generate_scenarios_template.py --force
```

---

## Безопасность

- Сообщения шлются **только** в беседу с `isTestConversation=true` — не в реальные тикеты.
- `.pw-profile/` (ваша SSO-сессия) и `reports/` исключены из git через `.gitignore`.
  **Не коммитьте профиль браузера.**
- `trust: true` в `.gemini/settings.json` разрешает агенту управлять браузером без
  подтверждения на каждое действие. Если хотите контролировать каждый шаг — уберите
  это поле.
