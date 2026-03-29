# R.A.I.K.O

R.A.I.K.O, the Remote Artificial Intelligence Kernel Operator, is a monorepo for a remote Windows control platform. The repository contains the mobile and desktop Flutter clients, a Fastify backend, a Windows agent, and the shared packages they depend on.

## Repository Layout

```text
apps/
  mobile/          Flutter mobile client
  desktop/         Flutter Windows client
  backend/         Fastify + WebSocket control backend
  agent-windows/   Windows Node agent

packages/
  raiko_ui/        Shared Flutter widgets
  shared_theme/    Shared Flutter tokens and theme
  shared_types/    Shared TypeScript contracts

docs/
  ARCHITECTURE.md
  CODEX_PROMPTS.md
  SRS.md
  WORK_DONE.md
```

## Stack

- Flutter for the mobile and desktop apps
- Node.js + TypeScript for backend and agent services
- Fastify for the HTTP API
- WebSocket for realtime device and command events
- PostgreSQL schema definitions for production persistence planning

## Current Product Direction

- Shared futuristic design system across Flutter apps
- Realtime device registration and state broadcasting
- Windows command dispatch via the backend and agent
- Mobile navigation for home, devices, activity, and settings
- Desktop navigation with a sidebar control surface
- Documentation that tracks prompt-by-prompt implementation progress

## Workspace Commands

Install JS dependencies:

```bash
npm install
```

Build the Node workspaces:

```bash
npm run build
```

Run the backend in watch mode:

```bash
npm run dev:backend
```

Run backend migrations before starting staged or production environments:

```bash
npm run migrate --workspace @raiko/backend
```

Run the Windows agent in watch mode:

```bash
npm run dev:agent
```

Flutter apps and packages are managed inside their own directories with the standard `flutter pub get`, `flutter analyze`, and `flutter test` workflows.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [SRS](docs/SRS.md)
- [Prompt Checklist](docs/CODEX_PROMPTS.md)
- [Work Log](docs/WORK_DONE.md)

## Environment Files

- `apps/backend/.env.example`
- `apps/agent-windows/.env.example`
