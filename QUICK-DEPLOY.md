# Quick Deployment Guide

Fast deployment guide for Pokedex Auth Service on Mikr.us VPS.

## Prerequisites

- Mikr.us VPS with Ubuntu/Debian
- GitHub repository secrets configured:
  - `DOCKERHUB_USERNAME`
  - `DOCKERHUB_TOKEN`

## One-Time Setup (First Deployment)

### 1. Prepare VPS

```bash
# SSH into your VPS
ssh your-username@srv36.mikr.us

# Download and run setup script
curl -O https://raw.githubusercontent.com/Mateusz-G541/pokedex-auth-service/main/setup-mikrus.sh
chmod +x setup-mikrus.sh
./setup-mikrus.sh

# If Docker was just installed, log out and back in
exit
ssh your-username@srv36.mikr.us
```

### 2. Clone and Configure

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/Mateusz-G541/pokedex-auth-service.git
cd pokedex-auth-service

# Configure environment
cp .env.production.example .env.production
nano .env.production
```

**Required changes in `.env.production`**:
- `MYSQL_ROOT_PASSWORD` - Set strong password
- `MYSQL_PASSWORD` - Set strong password
- `DATABASE_URL` - Update with your password
- `CORS_ORIGIN` - Add your frontend domains

### 3. Deploy

```bash
# Make deploy script executable
chmod +x deploy.sh

# Run first deployment
./deploy.sh deploy
```

### 4. Verify

```bash
# Check health
curl http://localhost:4000/health

# Should return:
# {"status":"ok","timestamp":"...","uptime":...,"database":"connected"}
```

## Updating (Subsequent Deployments)

```bash
# SSH into VPS
ssh your-username@srv36.mikr.us

# Navigate to project
cd /opt/pokedex-auth-service

# Deploy updates
./deploy.sh deploy
```

## Common Commands

```bash
# Check status
./deploy.sh status

# View logs
./deploy.sh logs

# Restart service
./deploy.sh restart

# Stop service
./deploy.sh stop

# Health check
./deploy.sh health
```

## Quick Troubleshooting

### Service won't start
```bash
# Check logs
./deploy.sh logs

# Check Docker
sudo systemctl status docker

# Restart everything
./deploy.sh stop
./deploy.sh deploy
```

### Database issues
```bash
# Check MySQL
docker exec pokedex-mysql mysqladmin ping -h localhost -u root -p

# View MySQL logs
docker logs pokedex-mysql
```

### Port conflicts
```bash
# Check what's using port 4000
sudo lsof -i :4000

# Check what's using port 3306
sudo lsof -i :3306
```

## Architecture

```
GitHub → GitHub Actions → Docker Hub → VPS
                ↓
         Build & Test
                ↓
         Push Image (quavaghar2/pokedex-auth-service:latest)
                ↓
         VPS pulls and deploys
```

## Ports

- **4000**: Auth Service API
- **3306**: MySQL Database

## File Locations

- **Project**: `/opt/pokedex-auth-service`
- **Environment**: `/opt/pokedex-auth-service/.env.production`
- **RSA Keys**: `/opt/pokedex-auth-service/keys/`
- **Logs**: `docker logs pokedex-auth-service`

## Important Notes

1. **RSA Keys**: Auto-generated on first deployment - backup these files!
2. **Database**: Persistent storage via Docker volumes
3. **Auto-start**: Service starts automatically on server reboot
4. **Updates**: Always test in staging before production
5. **Backups**: Regularly backup database and RSA keys

## Full Documentation

For detailed information, see [DEPLOYMENT.md](./DEPLOYMENT.md)
