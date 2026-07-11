# Architecture

## Overview

Pocket Dev Team follows a client-server architecture where:
- The **backend** runs the AI agents with full filesystem access
- The **iOS app** provides a mobile chat interface

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              BACKEND HOST                                    │
│  (Drupal Forge container, local machine, or any Docker host)                │
│                                                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                         Agent Server (Node.js)                         │  │
│  │                                                                        │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                   │  │
│  │  │    Lila     │  │    Cody     │  │    Quinn    │                   │  │
│  │  │   Session   │  │   Session   │  │   Session   │                   │  │
│  │  │  (Opus)     │  │  (Sonnet)   │  │  (Haiku)    │                   │  │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                   │  │
│  │         │                │                │                           │  │
│  │         └────────────────┼────────────────┘                           │  │
│  │                          │                                            │  │
│  │                          ▼                                            │  │
│  │              ┌───────────────────────┐                                │  │
│  │              │   Claude Agent SDK    │                                │  │
│  │              │   - query()           │                                │  │
│  │              │   - session resume    │                                │  │
│  │              │   - tool execution    │                                │  │
│  │              └───────────────────────┘                                │  │
│  │                          │                                            │  │
│  └──────────────────────────┼────────────────────────────────────────────┘  │
│                             │                                                │
│                             ▼                                                │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                     /workspace (Project Files)                         │  │
│  │                                                                        │  │
│  │   src/          specs/          tests/          docs/                 │  │
│  │                                                                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS + SSE
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              iOS App                                          │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                           AppState                                       │ │
│  │  - currentWorkspace                                                      │ │
│  │  - agents[]                                                              │ │
│  │  - selectedAgentId                                                       │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                    │                                          │
│           ┌────────────────────────┼────────────────────────┐                │
│           ▼                        ▼                        ▼                │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐          │
│  │   Lila Tab      │    │   Cody Tab      │    │   Quinn Tab     │          │
│  │                 │    │                 │    │                 │          │
│  │  ChatView       │    │  ChatView       │    │  ChatView       │          │
│  │  - messages[]   │    │  - messages[]   │    │  - messages[]   │          │
│  │  - inputText    │    │  - inputText    │    │  - inputText    │          │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘          │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Sending a Message

```
User taps Send
     │
     ▼
ChatView.sendMessage()
     │
     ├─► Add user message to local messages[]
     │
     ▼
AppState.sendMessage(text, agentId)
     │
     ▼
AgentService.sendMessage() ──► POST /api/agents/:id/message
     │                              │
     │                              ▼
     │                         Server receives request
     │                              │
     │                              ▼
     │                         sessions.sendMessage()
     │                              │
     │                              ├─► Add to history
     │                              │
     │                              ▼
     │                         Claude SDK query()
     │                              │
     │                              │ (streaming)
     │◄─────────────────────────────┤
     │    SSE: { type: "text", text: "..." }
     │    SSE: { type: "tool_start", ... }
     │    SSE: { type: "tool_end", ... }
     │    SSE: { type: "done" }
     │
     ▼
AgentEvent parsed
     │
     ▼
ChatView.handleEvent()
     │
     ├─► Update streamingText
     ├─► Update currentToolUse
     └─► Append final message
```

## Session Persistence

Both the backend and iOS app maintain conversation state:

### Backend (`.sessions.json`)

```json
{
  "lila": {
    "sessionId": "sess_abc123",
    "status": "idle",
    "history": [
      { "role": "user", "text": "...", "timestamp": "..." },
      { "role": "assistant", "text": "...", "toolUses": [...], "timestamp": "..." }
    ]
  }
}
```

The `sessionId` is used to resume Claude SDK sessions across server restarts.

### iOS App

Messages are loaded from the server on app launch and kept in memory. Future versions may cache locally for offline viewing.

## Authentication

Simple token-based auth:

1. Generate a token (UUID) and add to `config.json`
2. iOS app stores token in Keychain
3. All requests include `Authorization: Bearer <token>`

For production, consider:
- OAuth with Drupal Forge
- JWT with refresh tokens
- API key rotation

## Push Notifications (Future)

```
Agent completes task
     │
     ▼
push.notifyAgentComplete()
     │
     ▼
APNs ──► iOS device
     │
     ▼
User taps notification
     │
     ▼
App opens to agent's chat
```

Requires:
- Apple Developer account
- APNs certificates/keys
- Device token registration
