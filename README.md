# alexa

MCP server for Alexa alarms and reminders. Lets Claude (or any MCP client)
list, create, toggle, and delete alarms/reminders on Echo devices — the same
data the Alexa app shows under Alarms & Timers.

Uses [alexa-remote2](https://github.com/Apollon77/alexa-remote2), which talks
to the same unofficial API the Alexa app uses. Amazon has no public alarms
API, so auth is a captured session cookie that auto-refreshes (~every 4 days).

## Setup

```bash
npm install
node login.js   # prints a URL — open it, sign in to Amazon once
```

The cookie lands in `data/cookie.json` (gitignored — never commit it).
Set `ALEXA_PROXY_IP` if the machine's LAN/Tailscale IP differs from the
default so your phone can reach the login page.

Register with Claude Code:

```bash
claude mcp add --scope user alexa -- node /path/to/alexa/server.js
```

## Tools

| tool | what it does |
|---|---|
| `alexa_status` | auth check + device list |
| `alexa_login` | starts the login proxy for re-auth |
| `alexa_devices` | list Echo devices |
| `alexa_list_alarms` | alarms, reminders, timers across all devices |
| `alexa_set_alarm` | create an alarm or reminder ("4:00 pm", tomorrow, label) |
| `alexa_toggle_alarm` | flip an alarm ON/OFF |
| `alexa_delete_alarm` | remove it entirely |

Alarms still ring on the Echo they were created on — this is the remote
control, same as the app.
