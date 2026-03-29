# Prompt 1 — Finish backend core

    Continue the R.A.I.K.O monorepo.

Focus only on the backend in apps/backend.

Implement a production-ready Fastify + TypeScript backend with these modules:
- auth
- devices
- commands
- activity

Requirements:
- strict TypeScript
- modular feature-based architecture
- Zod or equivalent schema validation
- WebSocket support
- device registration endpoint
- command dispatch endpoint
- command result handling
- activity history endpoint
- health endpoint
- environment-based config
- structured logging
- clean error handling

Add PostgreSQL-ready persistence layer and schema definitions for:
- users
- devices
- commands
- command_results
- activity_logs

Do not build voice or automation yet.
Return:
1. folder structure
2. backend code
3. route list
4. env example
5. notes on how to run it


# Prompt 2 — Add dry-run mode to Windows agent

Continue the R.A.I.K.O monorepo.

Focus only on apps/agent-windows.

Add a safe dry-run mode to the Windows agent.

Requirements:
- environment variable to enable DRY_RUN=true
- when dry-run is enabled, do not execute shutdown/restart/sleep/lock
- instead simulate execution and return successful command.result
- include clear result payload indicating dry-run
- preserve current websocket behavior, heartbeat, and reconnect logic
- add unit tests for command handlers
- add integration-style tests for websocket command dispatch and result flow

Do not change unrelated UI code.
Return:
1. updated files
2. tests
3. run commands

# Prompt 3 — Build real data-driven app pages

Continue the R.A.I.K.O monorepo.

Focus on Flutter apps only:
- apps/mobile
- apps/desktop

Use the existing shared theme and raiko_ui packages.

Implement real app screens, not just dashboard placeholders:
- login screen
- devices screen
- device detail screen
- activity screen
- settings screen

Requirements:
- same visual identity on mobile and desktop
- shared components wherever possible
- responsive layouts
- loading state
- empty state
- error state
- offline state
- wire screens to backend repository/service layer with mock data first, then easy swap to real API

Do not redesign the established visual direction.
Return:
1. updated screen structure
2. navigation setup
3. service/repository layer
4. screen screenshots summary in text

# Prompt 4 — Add integration between backend and apps

Continue the R.A.I.K.O monorepo.

Connect Flutter apps to the backend.

Requirements:
- create API client layer
- create websocket client layer
- fetch devices from backend
- fetch activity history from backend
- send commands from UI to backend
- receive command results and update UI state
- maintain same UX on mobile and desktop
- show optimistic loading and command status badges

Do not implement voice yet.
Return complete code changes and notes for local testing.

# Prompt 5 — Add CI and repo production basics

Continue the R.A.I.K.O monorepo.

Set up production-ready repository basics.

Requirements:
- create .gitignore for Flutter + Node + Windows artifacts
- add root README improvements
- add .env.example files where needed
- add pnpm workspace config if missing
- add scripts for build, test, lint
- add GitHub Actions CI workflow for:
  - backend install/build/test
  - agent install/build/test
  - Flutter analyze/test for mobile, desktop, packages
- add a release checklist markdown file in docs/

Return all created files and explain how to use CI.

# Prompt 6 — Final MVP hardening pass

Continue the R.A.I.K.O monorepo.

Do a production MVP hardening pass.

Scope:
- backend
- windows agent
- mobile app
- desktop app

Requirements:
- fix obvious TODOs
- improve error messages
- improve null safety / strict typing
- verify env handling
- verify command validation
- verify websocket reconnect safety
- ensure no dangerous command executes without validation
- ensure command history is stored
- add last-seen device status logic
- add audit-friendly activity messages

Return:
1. all code changes
2. list of resolved production risks
3. remaining non-blocking issues
