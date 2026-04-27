# syntax=docker/dockerfile:1
# Multi-stage Dockerfile for the R.A.I.K.O backend.
# Targets Coolify and any generic Docker host with a reverse proxy in front.

FROM node:22-slim AS base
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
    RAIKO_RUN_MIGRATIONS=true \
    PIPER_HOME=/app/piper \
    RAIKO_PIPER_PATH=/app/piper/piper \
    RAIKO_VOICES_DIR=/app/piper/voices

# Required at deploy-time (set in Coolify env tab or docker-compose):
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
# curl: Coolify/Docker healthcheck. wget: Piper download.
# Debian-slim has glibc natively, so Piper + ONNX Runtime run without compat shims.
RUN npm ci --omit=dev \
 && apt-get update \
 && apt-get install -y --no-install-recommends curl wget unzip python3 ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Install Piper TTS with en_US-ryan-high voice model.
# Pinned to a real, immutable release tag — tag 2024.1.1 was never published and breaks builds.
ARG PIPER_RELEASE=2023.11.14-2
ARG PIPER_VOICE_BASE=https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high
RUN set -eux; \
    mkdir -p /app/piper/voices; \
    cd /app/piper; \
    wget --no-verbose -O piper.tar.gz "https://github.com/rhasspy/piper/releases/download/${PIPER_RELEASE}/piper_linux_x86_64.tar.gz"; \
    test -s piper.tar.gz; \
    # --strip-components=1 drops the leading "piper/" dir so the binary lands at /app/piper/piper
    tar xzf piper.tar.gz --strip-components=1; \
    rm piper.tar.gz; \
    test -f /app/piper/piper; \
    chmod +x /app/piper/piper; \
    /app/piper/piper --help >/dev/null 2>&1 || (echo "piper failed to execute" && ls -la /app/piper && exit 1); \
    cd voices; \
    wget --no-verbose -O en_US-ryan-high.onnx       "${PIPER_VOICE_BASE}/en_US-ryan-high.onnx"; \
    wget --no-verbose -O en_US-ryan-high.onnx.json  "${PIPER_VOICE_BASE}/en_US-ryan-high.onnx.json"; \
    test -s en_US-ryan-high.onnx; \
    test -s en_US-ryan-high.onnx.json

EXPOSE 8080

# Longer start period to accommodate Supabase SSL handshake + migrations.
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://127.0.0.1:8080/health || exit 1

WORKDIR /app/apps/backend
CMD ["node", "dist/index.js"]
