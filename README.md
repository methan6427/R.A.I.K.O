# R.A.I.K.O

Remote Artificial Intelligence Kernel Operator is a monorepo for a remote control platform spanning Flutter clients, a Fastify backend, and a Windows agent.

## Monorepo Layout

```text
raiko/
  apps/
    mobile/
    desktop/
    backend/
    agent-windows/
  packages/
    raiko_ui/
    shared_theme/
    shared_types/
  docs/
```

## Stack

- Frontend: Flutter
- Backend: Node.js, TypeScript, Fastify, WebSocket
- Agent: Node.js, TypeScript, WebSocket
- Database: PostgreSQL schema definition

## Initial Scope

- Shared dark futuristic Flutter design system
- Mobile and Windows desktop dashboards
- Backend WebSocket gateway
- Device and agent registration
- Command dispatch pipeline
- Windows agent command reception and logging

## Commands

```bash
npm install
npm run build
```

```bash
npm run dev --workspace @raiko/backend
```

```bash
npm run dev --workspace @raiko/agent-windows
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [SRS](docs/SRS.md)
- [Codex Prompts](docs/CODEX_PROMPTS.md)
