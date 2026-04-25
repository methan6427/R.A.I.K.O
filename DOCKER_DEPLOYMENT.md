# Docker Deployment Guide for R.A.I.K.O

This guide covers deploying R.A.I.K.O using Docker and Docker Compose for quick, reproducible deployments.

## Prerequisites

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **4GB RAM** minimum for the container
- **500MB disk space** minimum (for base image + Piper TTS model)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/raiko.git
cd raiko
```

### 2. Configure Environment

```bash
# Copy the example configuration
cp .env.example .env

# Edit with your deployment settings (strongly recommended for production)
# Generate secure passwords:
# POSTGRES_PASSWORD=$(openssl rand -base64 32)
# RAIKO_AUTH_TOKEN=$(openssl rand -base64 32)
nano .env
```

### 3. Start the Stack

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f backend

# Check service health
docker-compose ps
```

The backend API will be available at: `http://localhost:8080`

### 4. Configure Mobile App

In the R.A.I.K.O mobile app settings:

- **HTTP URL**: `http://your-server-ip:8080`
- **WebSocket URL**: `ws://your-server-ip:8080`
- **Auth Token**: (value from RAIKO_AUTH_TOKEN in .env)

## Services

### PostgreSQL Database

- **Container**: `raiko-db`
- **Port**: 5432 (internal), 5432 (exposed)
- **Volume**: `postgres_data` (persistent data)
- **Healthcheck**: Built-in, waits 10s between checks

Database is automatically initialized with schema migrations on first startup.

### R.A.I.K.O Backend

- **Container**: `raiko-backend`
- **Port**: 8080
- **Includes**:
  - Node.js runtime (Alpine Linux)
  - Piper TTS engine with en_US-ryan-high voice
  - Database migrations runner
  - Health check endpoint

**Startup sequence**:
1. Waits for PostgreSQL to be healthy
2. Runs database migrations
3. Starts API server on port 8080
4. Health checks every 30 seconds

## Configuration

### Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `POSTGRES_DB` | `raiko` | Database name |
| `POSTGRES_USER` | `raiko` | Database user |
| `POSTGRES_PASSWORD` | `raiko_secure_password` | Database password (change!) |
| `RAIKO_AUTH_TOKEN` | `change-me-in-production` | API authentication token (change!) |
| `RAIKO_PORT` | `8080` | API server port |
| `RAIKO_DATABASE_SSL_MODE` | `disable` | SSL mode: disable/allow/prefer/require |

### Volumes

**Persistent Volumes**:
- `postgres_data`: PostgreSQL data directory
- `piper_voices`: Downloaded TTS voice models

**Mounted Volumes**:
- `./logs`: Application logs (optional)

## Production Deployment

### Recommended Setup

```yaml
┌─────────────────────────────────────────┐
│         Reverse Proxy (Nginx/Traefik)   │
│  - HTTPS/TLS Termination                │
│  - Load Balancing (if scaled)           │
│  - Rate Limiting & DDoS Protection      │
└──────────────────┬──────────────────────┘
                   │
                   ↓
┌──────────────────────────────────────────┐
│       Docker Host (this deployment)      │
│  ┌────────────────────────────────────┐  │
│  │    R.A.I.K.O Backend               │  │
│  │    - Node.js + Piper TTS           │  │
│  │    - Port 8080 (internal only)     │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │    PostgreSQL Database              │  │
│  │    - Port 5432 (internal only)     │  │
│  │    - Persistent data                │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

### Security Checklist

- [ ] Change `POSTGRES_PASSWORD` to a strong random value
- [ ] Change `RAIKO_AUTH_TOKEN` to a strong random value
- [ ] Use a reverse proxy (Nginx, Caddy, Traefik) for HTTPS
- [ ] Set `RAIKO_DATABASE_SSL_MODE=require` for remote databases
- [ ] Keep Docker images updated: `docker-compose pull`
- [ ] Use network isolation: don't expose ports directly
- [ ] Regular database backups (see below)
- [ ] Monitor logs for errors: `docker-compose logs backend`
- [ ] Use strong credentials for all services

### Database Backups

```bash
# Backup database
docker-compose exec postgres pg_dump -U raiko raiko > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
cat backup.sql | docker-compose exec -T postgres psql -U raiko

# Automated daily backups (cron)
0 2 * * * cd /path/to/raiko && docker-compose exec -T postgres pg_dump -U raiko raiko > /backups/raiko_$(date +\%Y\%m\%d).sql
```

### Scaling & High Availability

Currently configured for single-node deployment. For HA:

1. **Run multiple backend instances** behind load balancer
2. **Use RDS or managed PostgreSQL** for database
3. **Enable database replication** for failover
4. **Use S3 or similar** for persistent volume backup
5. **Monitor with Prometheus/Grafana** for metrics

## Troubleshooting

### Backend won't start

```bash
# Check logs
docker-compose logs backend

# Common issues:
# - Database connection failed: Check POSTGRES_PASSWORD, database is healthy
# - Port already in use: Change RAIKO_PORT or stop other services
# - Out of memory: Increase Docker memory limit
```

### Database connection errors

```bash
# Verify database is running and healthy
docker-compose ps postgres

# Check database connectivity
docker-compose exec backend psql -h postgres -U raiko -d raiko -c "SELECT 1"

# View database logs
docker-compose logs postgres
```

### TTS not working

```bash
# Verify Piper is installed in container
docker-compose exec backend ls -la /app/piper/

# Check voice models are present
docker-compose exec backend ls -la /app/piper/voices/

# Test Piper TTS manually
docker-compose exec backend /app/piper/piper --help
```

### Performance issues

```bash
# Monitor resource usage
docker stats

# Check container logs for errors
docker-compose logs --tail=100 backend

# Increase Docker memory limit if needed
# Edit docker-compose.yml and add to backend service:
# deploy:
#   resources:
#     limits:
#       memory: 2G
```

## Updating

### Update R.A.I.K.O

```bash
# Pull latest code
git pull

# Rebuild containers
docker-compose build

# Restart services
docker-compose up -d
```

### Update Docker images

```bash
# Pull latest base images
docker-compose pull

# Rebuild with new base images
docker-compose build --no-cache

# Restart
docker-compose up -d
```

## Monitoring

### Health Checks

Backend includes automatic health check:

```bash
# Manual health check
curl http://localhost:8080/health

# Response:
# {"status": "ok", "timestamp": "2024-01-15T10:30:45Z"}
```

### Logs

```bash
# View recent logs
docker-compose logs -f backend

# View specific service logs
docker-compose logs postgres

# View logs from last hour
docker-compose logs --since 1h backend

# Follow logs in real-time
docker-compose logs -f
```

### Database Metrics

```bash
# Connect to PostgreSQL directly
docker-compose exec postgres psql -U raiko -d raiko

# Check database size
SELECT pg_size_pretty(pg_database_size('raiko'));

# Check active connections
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## Cleanup

```bash
# Stop services
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v

# Remove images
docker-compose down --rmi all

# Remove unused Docker resources
docker system prune -a
```

## Next Steps

- **Configure Reverse Proxy**: Set up Nginx or Traefik in front
- **Enable HTTPS**: Use Let's Encrypt for free SSL certificates
- **Monitor**: Set up Prometheus/Grafana for metrics
- **Backup**: Configure automated database backups
- **Scale**: Add more backend instances behind load balancer
- **Integrate Agents**: Connect Windows agents via the WebSocket
- **Deploy Mobile App**: Build and deploy iOS/Android apps

## Support

For issues and questions:

1. Check logs: `docker-compose logs -f backend`
2. Review this guide for common issues
3. Open GitHub issues with logs and configuration
4. Check health endpoint: `curl http://localhost:8080/health`

---

**Deployment Date**: (recorded in your Docker container logs)
**Version**: Check with `curl http://localhost:8080/api/overview`
