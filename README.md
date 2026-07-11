# Pocket Dev Team 📱

A mobile interface for AI coding agents - your development team in your pocket. Built with SwiftUI for iOS and Node.js for the backend.

## Overview

Pocket Dev Team brings the "trio pattern" from AMS Trio to mobile, giving you access to three specialized AI agents:

- **📚 Lila (Librarian)** - Codebase explorer and documentation expert
- **💻 Cody (Coder)** - Implementation specialist and code writer  
- **🔍 Quinn (QA)** - Quality assurance and testing expert

Each agent has a distinct personality and specialized tools, working together to help you understand, build, and test your code.

## Features

### iOS App
- Tab-based interface with one tab per agent
- Real-time SSE streaming for live responses
- Tool use indicators (e.g., "Reading file...", "Running tests...")
- Connect/disconnect flow with server configuration
- Settings view for server URL and authentication
- Persistent conversation history

### Backend
- Express server with REST API + SSE streaming
- Claude Agent SDK integration (Anthropic API)
- Session persistence with file-based storage
- Token-based authentication
- Agent personas defined in markdown files

## Project Structure

```
pocket-dev-team/
├── backend/
│   ├── src/
│   │   ├── index.js              # Express server entry point
│   │   ├── routes/
│   │   │   └── agents.js         # Agent API endpoints
│   │   ├── services/
│   │   │   ├── agentService.js   # Claude SDK integration
│   │   │   ├── personaLoader.js  # Load agent personas
│   │   │   └── sessionStore.js   # Session persistence
│   │   └── middleware/
│   │       └── auth.js           # Token authentication
│   ├── personas/
│   │   ├── lila.md               # Librarian persona
│   │   ├── cody.md               # Coder persona
│   │   └── quinn.md              # QA persona
│   ├── package.json
│   └── .env.example
│
└── ios/
    └── PocketDevTeam/
        ├── PocketDevTeam.xcodeproj
        └── PocketDevTeam/
            ├── PocketDevTeamApp.swift
            ├── Models/
            │   ├── Agent.swift
            │   ├── Message.swift
            │   └── SSEEvent.swift
            ├── Services/
            │   ├── APIConfiguration.swift
            │   ├── AgentService.swift
            │   └── SSEService.swift
            ├── ViewModels/
            │   ├── AgentViewModel.swift
            │   └── AppViewModel.swift
            ├── Views/
            │   ├── ContentView.swift
            │   ├── ConnectionView.swift
            │   ├── MainTabView.swift
            │   ├── AgentChatView.swift
            │   ├── MessageBubble.swift
            │   ├── MessageInputView.swift
            │   └── SettingsView.swift
            └── Extensions/
                └── Color+Hex.swift
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/agents` | GET | List all agents |
| `/api/agents/:id/history` | GET | Get conversation history |
| `/api/agents/:id/message` | POST | Send message (SSE stream) |
| `/api/agents/:id/clear` | POST | Clear session |

## Getting Started

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

4. Configure your environment variables:
   ```
   ANTHROPIC_API_KEY=your_anthropic_api_key
   PORT=3000
   AUTH_TOKEN=your_secure_token
   ```

5. Start the server:
   ```bash
   npm start
   ```

   Or for development with auto-reload:
   ```bash
   npm run dev
   ```

### iOS App Setup

1. Open the Xcode project:
   ```bash
   cd ios/PocketDevTeam
   open PocketDevTeam.xcodeproj
   ```

2. Select your target device/simulator

3. Build and run (⌘R)

4. Configure the server URL in Settings:
   - Tap the gear icon
   - Enter your backend server URL
   - Enter your auth token
   - Test the connection

## Authentication

The backend uses Bearer token authentication. Include the token in your requests:

```
Authorization: Bearer your_token_here
```

Set the `AUTH_TOKEN` environment variable on the server. If not set, authentication is disabled (development mode).

## Agent Personas

Each agent has a distinct personality and toolset defined in markdown files in `backend/personas/`:

### Lila (Librarian) 📚
- **Tools**: `read_file`, `list_directory`, `search_code`
- **Specialty**: Code exploration, documentation, architecture analysis

### Cody (Coder) 💻
- **Tools**: `read_file`, `write_file`, `list_directory`, `run_command`, `search_code`
- **Specialty**: Implementation, refactoring, bug fixing

### Quinn (QA) 🔍
- **Tools**: All tools including `run_tests`
- **Specialty**: Testing, quality assurance, debugging

## SSE Event Types

The streaming API sends these event types:

| Type | Description |
|------|-------------|
| `text` | Text content from the agent |
| `tool_start` | Agent started using a tool |
| `tool_end` | Agent finished using a tool |
| `done` | Response complete |
| `error` | Error occurred |

## Requirements

### Backend
- Node.js 20+
- Anthropic API key

### iOS App
- iOS 17.0+
- Xcode 15.0+

## License

MIT

## Contributing

Contributions welcome! Please read the contributing guidelines first.
