# R.A.I.K.O Architecture

## Overview

R.A.I.K.O uses a hub-and-spoke architecture:

- Mobile app connects to backend over WebSocket
- Desktop app connects to backend over WebSocket
- Windows agent connects to backend over WebSocket
- Backend coordinates registration, activity tracking, and command routing

## Components

### `apps/mobile`

Flutter Android-first client with the shared R.A.I.K.O design system.

### `apps/desktop`

Flutter Windows client using the same shared components and theme as mobile.

### `apps/backend`

Fastify HTTP server with a raw WebSocket gateway and feature modules:

- `auth`
- `devices`
- `commands`
- `activity`
- `automation`

### `apps/agent-windows`

TypeScript Node process intended to evolve into a Windows background service. It maintains a persistent backend WebSocket session and executes command handlers.

### `packages/raiko_ui`

Reusable Flutter widgets:

- `RaikoCard`
- `RaikoButton`
- `RaikoHeader`
- `RaikoDeviceTile`
- `RaikoVoiceOrb`
- `RaikoStatusBadge`

### `packages/shared_theme`

Shared Flutter color tokens and app-wide Material theme configuration.

### `packages/shared_types`

Shared TypeScript enums and payload contracts for backend and agent communication.

## Message Flow

1. Agent sends `agent.register`
2. Client sends `device.register`
3. Client sends `command.send`
4. Backend forwards `command.dispatch`
5. Agent replies with `command.result`
6. Backend logs activity and broadcasts updates

## PostgreSQL

The repository includes schema-only SQL for:

- users
- devices
- agents
- command_logs
- automation_rules
- activity_logs