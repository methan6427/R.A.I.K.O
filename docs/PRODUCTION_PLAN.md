# R.A.I.K.O - Production Deployment Plan

**Created**: 2026-04-18
**Last updated**: 2026-04-19
**Status**: Mobile + agent + container ready. Awaiting Coolify deploy.

---

## Overview

Move R.A.I.K.O from development (localhost + emulator) to a production-ready state where:
- The mobile app runs on a real Android phone (APK) — **DONE**
- The Windows agent runs as a single `.exe` on any PC — **DONE**
- The backend runs persistently on a Coolify-managed server with a Cloudflare-pointed domain — **READY TO DEPLOY**

---

## Phase 1: Backend Production Readiness

### 1.1 Database
- [x] PostgreSQL local instance verified
- [x] `RAIKO_RUN_MIGRATIONS=true` set in Dockerfile by default
- [ ] On deploy: Coolify-managed Postgres resource (internal connection string, no SSL)

### 1.2 Auth Token
- [x] Backend reads `RAIKO_AUTH_TOKEN` from env
- [x] Agent and mobile both honour the token
- [ ] On deploy: generate strong token (`openssl rand -hex 32`) and set in Coolify env

### 1.3 Backend Hosting — chosen path: Coolify

Containerized deploy on a friend's Coolify server, fronted by a Cloudflare-managed
domain. Coolify handles Docker build, Let's Encrypt, and reverse-proxy.

Artefacts already in repo:
- `Dockerfile` — multi-stage Alpine Node 22, builds `@raiko/shared-types` + `@raiko/backend`, runs migrations on start, healthcheck on `/health`
- `.dockerignore` — excludes Flutter apps, docs, agent bundle output
- `ecosystem.config.cjs` — pm2 config for the alternative "run on home PC" path

Discarded:
- ~~Cloudflare Tunnel from home PC~~ (Coolify path is cleaner once domain is in hand)
- ~~Generic VPS + manual Caddy~~ (Coolify gives the same outcome with a UI)

### 1.4 Production Hardening
- [x] HTTPS/WSS via Coolify's Let's Encrypt (no manual TLS plumbing)
- [x] `NODE_ENV=production` baked into Dockerfile
- [x] `/health` endpoint with no auth, used by Coolify healthcheck
- [ ] Rate limiting on REST endpoints (deferred — low risk while token-gated)
- [ ] Audit log of executed commands (Phase 5)

---

## Phase 2: Mobile App Release (APK) — DONE

- [x] Per-device persistent UUID via `raiko_identity.dart` (uses `device_info_plus` + `shared_preferences`)
- [x] Runtime platform detection
- [x] Backend URL/token persisted in `shared_preferences` (`raiko_settings_store.dart`)
- [x] `Connecting…` loading state on Connect button
- [x] Snackbar notifications for connection errors and command results
- [x] Release APK built (`apps/mobile/build/app/outputs/flutter-apk/app-release.apk`)

For production: rebuild APK with `--dart-define`s pointing at the Coolify URL:
```bash
flutter build apk --release \
  --dart-define=RAIKO_BASE_HTTP_URL=https://raiko.<your-domain> \
  --dart-define=RAIKO_WEBSOCKET_URL=wss://raiko.<your-domain>/ws \
  --dart-define=RAIKO_AUTH_TOKEN=<token>
```
Or install the existing APK and edit URLs/token in the Settings tab.

Deferred:
- [ ] First-launch onboarding wizard
- [ ] QR-code config import
- [ ] Play Store signing + AAB upload

---

## Phase 3: Windows Agent Distribution — DONE

- [x] `tools/standalone-agent.mjs` reads config.json beside the binary
- [x] Bundled to a single `tools/dist/raiko-agent.exe` (~43 MB) via `esbuild` + `@yao-pkg/pkg`
- [x] `tools/config.example.json` ships with `wss://` placeholder
- [x] Dry-run flag works for safe smoke tests

To run on any Windows PC:
1. Copy `raiko-agent.exe` and `config.json` to a folder
2. Edit `config.json` — set `backendWsUrl` and `authToken`
3. Double-click the exe (or wrap with NSSM for service-mode persistence)

Deferred:
- [ ] NSSM/Task Scheduler one-shot installer
- [ ] Tray icon
- [ ] Inno Setup installer that bundles config UI

---

## Phase 4: Network / Internet Access — Coolify + Cloudflare

### 4.1 Cloudflare DNS setup
1. Cloudflare dashboard → DNS → Add record
   - Type `A` · Name `raiko` · Value `<friend's server public IP>`
   - Proxy: **DNS only (gray cloud)** for the first deploy. Orange-cloud proxying works
     for WebSockets but is an extra surface to debug.

### 4.2 Coolify deploy
1. New Resource → **Database** → PostgreSQL 16 → name `raiko-db`. Copy the internal
   connection string.
2. New Resource → **Application** → Public Repository → paste this repo's URL.
3. Build pack: **Dockerfile** (auto-detected from repo root).
4. Port: `8080`. Healthcheck path: `/health`.
5. Environment variables:
   ```
   RAIKO_DATABASE_URL=postgres://postgres:<pass>@raiko-db:5432/postgres
   RAIKO_DATABASE_SSL_MODE=disable
   RAIKO_AUTH_TOKEN=<openssl rand -hex 32>
   ```
6. Domains: `raiko.<your-domain>` → enable Let's Encrypt.
7. Deploy.

### 4.3 Smoke test
1. Update `config.json` next to `raiko-agent.exe` with the wss URL and token. Run.
   Expect `Connected. Registering agent...`.
2. On the phone: open the app → Settings tab → enter https/wss URLs and token →
   Connect → fire `lock` command → laptop locks.

---

## Phase 5: Polish & Remaining Features

### 5.1 Must-Have Before "v1.0" — DONE
- [x] Loading indicators during connection
- [x] Snackbar notifications for command results
- [x] Connection error recovery UX
- [x] Settings persistence

### 5.2 Wake-on-LAN (Remote Power On)
- [ ] Add `wake` command type to shared-types, backend, mobile
- [ ] Agent sends MAC address during registration
- [ ] Backend sends WoL magic packet (UDP broadcast port 9) to wake offline agents
- [ ] Works on same LAN; cross-network wake deferred (needs relay device)
- [ ] Prerequisite: enable WoL in BIOS + Windows network adapter on target PCs

### 5.3 AnyDesk Remote Desktop Integration
- [ ] Agent reads its AnyDesk ID on registration (`AnyDesk.exe --get-id`)
- [ ] Store AnyDesk ID in backend alongside agent info
- [ ] Add "Remote Control" button per agent in mobile Devices tab
- [ ] Launch AnyDesk on phone via deep link (`anydesk:<ID>`)
- [ ] Agent ensures AnyDesk is running via `open_app` before connection
- [ ] Prerequisite: enable unattended access (password) on each PC, install AnyDesk on phone

### 5.4 Nice-to-Have
- [ ] Voice assistant integration (speech-to-text for Voice Orb)
- [ ] Push notifications via Firebase Cloud Messaging
- [ ] Desktop Flutter client (apps/desktop already scaffolded)
- [ ] Command history with search/filter
- [ ] Multiple agent management (select which PC to control)

### 5.5 Security Hardening
- [ ] Replace static token with JWT or device-pairing flow
- [ ] Add per-device permissions (which commands each device can send)
- [ ] Add audit logging for all commands executed
- [ ] Rate limit REST endpoints

---

## Recommended Execution Order

| #  | What                                                       | Status   |
|----|------------------------------------------------------------|----------|
| 1  | Fix hardcoded device ID + persist settings                 | done     |
| 2  | Build release APK                                          | done     |
| 3  | pm2 ecosystem.config.cjs (home-PC fallback)                | done     |
| 4  | Bundle standalone agent as `.exe`                          | done     |
| 5  | Loading states + snackbars on mobile                       | done     |
| 6  | Containerize backend (Dockerfile + .dockerignore)          | done     |
| 7  | Cloudflare DNS A record for `raiko.<domain>`               | on-site  |
| 8  | Coolify Postgres + Application + Let's Encrypt             | on-site  |
| 9  | Rebuild APK with production --dart-defines                 | on-site  |
| 10 | Wake-on-LAN command                                        | next     |
| 11 | AnyDesk integration                                        | next     |
| 12 | Voice assistant                                            | later    |
| 13 | Security hardening (JWT, pairing, audit log, rate limit)   | later    |

---

## Quick Start (When Meeting Friend with Coolify Server)

1. `git push` so the repo is reachable from Coolify.
2. Cloudflare: create A record `raiko.<domain>` → friend's server IP.
3. Coolify: add Postgres resource → copy internal URL.
4. Coolify: add Application from the GitHub repo, Dockerfile build pack.
5. Set env: `RAIKO_DATABASE_URL`, `RAIKO_DATABASE_SSL_MODE=disable`, `RAIKO_AUTH_TOKEN`.
6. Bind custom domain `raiko.<domain>`, enable Let's Encrypt, deploy.
7. Edit `config.json` next to `raiko-agent.exe` → run.
8. Open phone app → Settings → set URLs + token → Connect → fire `lock`.
