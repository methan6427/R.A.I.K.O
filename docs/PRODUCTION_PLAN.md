# R.A.I.K.O - Production Deployment Plan

**Created**: 2026-04-18
**Status**: Planning - to be executed next session

---

## Overview

Move R.A.I.K.O from development (localhost + emulator) to a production-ready state where:
- The mobile app runs on a real Android phone (APK)
- The Windows agent runs as a background service on any PC
- The backend runs persistently (local server or cloud)

---

## Phase 1: Backend Production Readiness

### 1.1 Database
- [ ] Ensure PostgreSQL is running with a proper password (not `raiko123`)
- [ ] Run migrations: `npm run migrate --workspace @raiko/backend`
- [ ] Enable `RAIKO_RUN_MIGRATIONS=true` for auto-migrate on startup

### 1.2 Auth Token
- [ ] Generate a strong token (replace `raiko-dev`)
- [ ] Update `.env` on backend, agent, and mobile app defaults

### 1.3 Backend Hosting Options

**Option A: Run on your home PC (simplest)**
- Keep the backend on this machine (192.168.1.103)
- Use `pm2` or a Windows Service to keep it running 24/7
- Works on LAN only; needs port forwarding or tunnel for remote access

**Option B: Cloud VPS (recommended for internet access)**
- Deploy to a small VPS (DigitalOcean $6/mo, Hetzner $4/mo, etc.)
- Run PostgreSQL + backend on the same box
- Use a domain + HTTPS (Let's Encrypt / Caddy reverse proxy)
- Both mobile and agent connect over the internet

**Option C: Docker Compose**
- Containerize backend + PostgreSQL
- Single `docker compose up` on any machine
- Easy to move between machines

### 1.4 Production Hardening
- [ ] Add HTTPS/WSS (TLS) - either via Caddy reverse proxy or Fastify TLS plugin
- [ ] Add rate limiting to REST endpoints
- [ ] Add request logging with correlation IDs
- [ ] Set `NODE_ENV=production`
- [ ] Add health check endpoint monitoring

---

## Phase 2: Mobile App Release (APK)

### 2.1 Pre-Build Fixes
- [ ] Replace hardcoded `deviceId: 'mobile-android-01'` with unique per-device ID (use `device_info_plus` package)
- [ ] Replace hardcoded `platform: 'android'` with runtime detection
- [ ] Persist backend URL/token to `shared_preferences` so user doesn't re-enter on every launch
- [ ] Update default URLs from `10.0.2.2` (emulator-only) to either:
  - Empty (force user to configure on first launch)
  - Or your production backend URL if known

### 2.2 App Configuration Screen
- [ ] Add a first-launch onboarding flow: enter backend URL + token
- [ ] Add QR code scanning to import connection config (nice to have)
- [ ] Show clear error if backend is unreachable

### 2.3 Build APK
```bash
cd apps/mobile
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 2.4 Install
- Transfer APK to phone via USB/share
- Or use `flutter install -d <device>` with phone connected

### 2.5 Play Store (future)
- [ ] Create signing keystore
- [ ] Configure `android/app/build.gradle` with signing config
- [ ] `flutter build appbundle --release` for AAB upload
- [ ] Create Play Console listing

---

## Phase 3: Windows Agent as a Service

### 3.1 Standalone Agent Package
- [ ] The `tools/standalone-agent.mjs` already works as a single file
- [ ] Create a `config.json` next to it for easy editing (instead of env vars)
- [ ] Bundle with `pkg` or `nexe` into a single `.exe` (no Node.js install needed)

### 3.2 Run as Windows Service
**Option A: NSSM (Non-Sucking Service Manager)**
```
nssm install RaikoAgent "C:\path\to\node.exe" "C:\path\to\standalone-agent.mjs"
nssm set RaikoAgent AppEnvironmentExtra RAIKO_BACKEND_WS_URL=ws://192.168.1.103:8080/ws
nssm set RaikoAgent AppEnvironmentExtra+ RAIKO_AUTH_TOKEN=your-token
nssm start RaikoAgent
```

**Option B: node-windows package**
- Wraps any Node script as a proper Windows Service
- Auto-restart on crash, event log integration

**Option C: Task Scheduler**
- Simplest: run on login, restart on failure
- Less robust than a service but zero setup

### 3.3 Agent Installer (future)
- [ ] Create an Inno Setup or NSIS installer
- [ ] Bundles Node.js runtime + agent script + config UI
- [ ] Installs as Windows Service automatically
- [ ] Tray icon showing connection status

---

## Phase 4: Network / Internet Access

### 4.1 LAN-Only (current)
- Works now: backend on 192.168.1.103, agent on 192.168.1.109
- Mobile connects on same Wi-Fi network

### 4.2 Internet Access Options

**Option A: Cloudflare Tunnel (easiest, free)**
- Install `cloudflared` on the backend machine
- `cloudflared tunnel --url http://localhost:8080`
- Get a public URL like `https://raiko.your-domain.com`
- Supports WebSocket out of the box
- No port forwarding needed

**Option B: Tailscale / ZeroTier (mesh VPN)**
- Install on all devices (backend PC, agent PC, phone)
- Each device gets a stable IP on a private network
- Works across any network, no config changes
- Free for personal use

**Option C: Port Forward + Dynamic DNS**
- Forward port 8080 on your router
- Use a dynamic DNS service (No-IP, DuckDNS)
- Add TLS via Let's Encrypt

**Option D: Cloud VPS (cleanest)**
- Deploy backend to a VPS with a domain
- All devices connect to the public URL
- Most reliable, works from anywhere

---

## Phase 5: Polish & Remaining Features

### 5.1 Must-Have Before "v1.0"
- [ ] Loading indicators during connection/command dispatch
- [ ] Snackbar notifications for command results
- [ ] Connection error recovery UX (retry button, clear error state)
- [ ] Settings persistence (shared_preferences)

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

### 5.3 Security Hardening
- [ ] Replace static token with JWT or device-pairing flow
- [ ] Add per-device permissions (which commands each device can send)
- [ ] Encrypt WebSocket payloads (or rely on WSS/TLS)
- [ ] Add audit logging for all commands executed

---

## Recommended Execution Order

| Step | What | Effort |
|------|------|--------|
| 1 | Fix hardcoded device ID + persist settings | 30 min |
| 2 | Build release APK, install on real phone | 15 min |
| 3 | Set up backend with pm2 on this PC | 15 min |
| 4 | Deploy standalone agent on laptop as service | 15 min |
| 5 | Test full flow: phone -> backend -> laptop lock | 10 min |
| 6 | Set up Cloudflare Tunnel for internet access | 20 min |
| 7 | Add loading states + error snackbars to mobile | 45 min |
| 8 | Bundle agent as .exe with pkg | 30 min |
| 9 | Voice assistant integration | 2-3 hrs |
| 10 | Security hardening (JWT, pairing) | 3-4 hrs |

---

## Quick Start (Next Session)

When tokens reset, we should:
1. Start PostgreSQL + backend on this machine
2. Send `standalone-agent.mjs` to the laptop
3. Run agent on laptop pointing to `ws://192.168.1.103:8080/ws`
4. Connect mobile app and send a `lock` command
5. Verify the laptop locks
6. Then build the release APK for your real phone
