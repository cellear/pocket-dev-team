# Pocket Dev Team

Your AI dev team in your pocket. Chat with Lila (specs), Cody (code), and Quinn (QA) — from anywhere.

## What is this?

Pocket Dev Team is a mobile interface for the [trio pattern](https://github.com/cellear/ams-trio): three AI agents with distinct roles working together on your codebase.

| Agent | Role | Specialty |
|-------|------|-----------|
| **Lila** | Librarian | Specs, docs, requirements |
| **Cody** | Coder | Implementation, builds, commits |
| **Quinn** | QA/Tester | Verification, bug finding, quality |

Each agent runs its own Claude session with filesystem access to your project. You direct them through conversation — no need to read or write code yourself.

## Architecture

```
┌─────────────────┐                    ┌──────────────────────────────────────┐
│   iOS App       │     HTTPS/SSE      │  Backend (Drupal Forge / Docker)     │
│                 │ ◄────────────────► │                                      │
│  - Lila tab     │                    │  - Node.js + Claude Agent SDK        │
│  - Cody tab     │                    │  - REST API + SSE streaming          │
│  - Quinn tab    │                    │  - Filesystem access to /workspace   │
└─────────────────┘                    └──────────────────────────────────────┘
```

## Quick Start

### Backend

```bash
cd backend
npm install
npm start
```

Server runs at `http://localhost:3000`.

**Requirements:**
- Node.js 18+
- Claude Code CLI installed and authenticated (or `ANTHROPIC_API_KEY` env var)

### iOS App

Open `ios/PocketDevTeam` in Xcode:
1. Open the folder as a Swift package or create a new Xcode project and add the sources
2. Build and run on simulator or device
3. Enter your backend URL (e.g., `http://localhost:3000` or your Drupal Forge URL)

## Configuration

### Backend (`backend/config.json`)

```json
{
  "projectRoot": "../workspace",  // Directory agents work in
  "port": 3000,
  "permissionMode": "acceptEdits",
  "agents": [
    { "id": "lila", "name": "Lila", "role": "Librarian", "model": "claude-sonnet-4-5-20250514" },
    { "id": "cody", "name": "Cody", "role": "Coder", "model": "claude-sonnet-4-5-20250514" },
    { "id": "quinn", "name": "Quinn", "role": "QA / Tester", "model": "claude-sonnet-4-5-20250514" }
  ],
  "auth": {
    "enabled": true,
    "tokens": ["your-secret-token"]
  }
}
```

### Personas

Edit `backend/personas/*.md` to customize each agent's behavior and communication style.

## API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/agents` | GET | List available agents |
| `/api/agents/:id/history` | GET | Get conversation history |
| `/api/agents/:id/message` | POST | Send message (returns SSE stream) |
| `/api/agents/:id/status` | GET | Get agent status |
| `/api/agents/:id/clear` | POST | Clear conversation |
| `/api/workspace` | GET | Get workspace info |

### SSE Events

```javascript
{ "type": "text", "text": "..." }           // Streamed response text
{ "type": "tool_start", "tool": "read_file", "args": {...} }
{ "type": "tool_end", "tool": "read_file" }
{ "type": "status", "status": "idle" }
{ "type": "error", "message": "..." }
{ "type": "done" }
```

## Deploying to Drupal Forge

1. Create a new site on [Drupal Forge](https://drupalforge.org) (any Docker template works)
2. Clone this repo into the workspace
3. Run `cd backend && npm install && npm start`
4. Connect your iOS app to the Drupal Forge URL

## Roadmap

- [ ] Push notifications when agents complete or need input
- [ ] Voice input
- [ ] Multiple workspace support
- [ ] Agent customization in-app
- [ ] App Store release

## Related Projects

- [AMS Trio](https://github.com/cellear/ams-trio) — Browser-based trio interface
- [Three Man Team](https://github.com/cellear/three-man-team) — The trio pattern for CLI/editor use
- [Drupal Forge](https://drupalforge.org) — Cloud dev environments

## License

MIT
