# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for the R.A.I.K.O backend.
# Targets Coolify and any generic Docker host with a reverse proxy in front.

FROM node:22-alpine AS base
WORKDIR /app

# ─── deps ─────────────────────────────────────────────────────────────────
# Install workspace dev + prod deps to build TypeScript.
FROM base AS deps
COPY package.json package-lock.json ./
COPY packages/shared_types/package.json ./packages/shared_types/
COPY apps/backend/package.json ./apps/backend/
COPY apps/agent-windows/package.json ./apps/agent-windows/
RUN npm ci

# ─── build ────────────────────────────────────────────────────────────────
FROM deps AS build
COPY tsconfig.base.json ./
COPY packages/shared_types ./packages/shared_types
COPY apps/backend ./apps/backend
RUN npm run build --workspace @raiko/shared-types \
 && npm run build --workspace @raiko/backend

# ─── runtime ──────────────────────────────────────────────────────────────
FROM base AS runtime
ENV NODE_ENV=production \
    RAIKO_HOST=0.0.0.0 \
    RAIKO_PORT=8080 \
    RAIKO_RUN_MIGRATIONS=true

# Required at deploy-time (set in Coolify env tab):
#   RAIKO_DATABASE_URL=postgres://user:pass@host:5432/raiko
#   RAIKO_AUTH_TOKEN=<strong random string>
# Optional:
#   RAIKO_DATABASE_SSL_MODE=require   (set when DB is over public internet)

COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/packages/shared_types/package.json ./packages/shared_types/
COPY --from=build /app/packages/shared_types/dist ./packages/shared_types/dist
COPY --from=build /app/apps/backend/package.json ./apps/backend/
COPY --from=build /app/apps/backend/dist ./apps/backend/dist
COPY --from=build /app/apps/backend/migrations ./apps/backend/migrations
COPY --from=build /app/apps/agent-windows/package.json ./apps/agent-windows/

# Production-only install. Workspace symlinks resolve shared_types/dist.
RUN npm ci --omit=dev

EXPOSE 8080

# Coolify and Docker can probe /health (no auth required).
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:8080/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

WORKDIR /app/apps/backend
CMD ["node", "dist/index.js"]
