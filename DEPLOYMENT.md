# Pokedex Auth Service - Deployment Guide

This guide explains how to deploy the Pokedex Auth Service to your Mikr.us VPS using Docker and Docker Hub registry, following the same pattern as the Pokemon API Service.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Deployment Process](#deployment-process)
- [Configuration](#configuration)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Troubleshooting](#troubleshooting)

## Architecture Overview

The deployment uses:
- **Docker Hub Registry**: Pre-built images pushed via GitHub Actions
- **Docker Compose**: Multi-container orchestration (auth service + MySQL)
- **Automated Deployment**: Pull latest images and restart services
- **Health Checks**: Automatic service health monitoring
- **Systemd Integration**: Auto-start on server reboot

### Service Components

1. **Auth Service Container** (`pokedex-auth-service`)
   - Port: 4000
   - Image: `quavaghar2/pokedex-auth-service:latest`
   - Dependencies: MySQL database

2. **MySQL Database Container** (`pokedex-mysql`)
   - Port: 3306
   - Image: `mysql:8.0`
   - Persistent storage via Docker volumes

## Prerequisites

### On Your Development Machine

1. **GitHub Repository Secrets**
   
   Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):
   
   ```
   DOCKERHUB_USERNAME=quavaghar2
   DOCKERHUB_TOKEN=<your-docker-hub-access-token>
   ```

   To create a Docker Hub access token:
   - Go to https://hub.docker.com/settings/security
   - Click "New Access Token"
   - Give it a name (e.g., "GitHub Actions")
   - Copy the token and add it to GitHub secrets

### On Your Mikr.us VPS

- Ubuntu/Debian-based Linux
- Root or sudo access
- Minimum 1GB RAM (2GB recommended)
- 10GB free disk space

## Initial Setup

### Step 1: Prepare Your VPS

SSH into your Mikr.us VPS:

```bash
ssh your-username@srv36.mikr.us
```

### Step 2: Run Setup Script

Download and run the setup script:

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Mateusz-G541/pokedex-auth-service/main/setup-mikrus.sh

# Make it executable
chmod +x setup-mikrus.sh

# Run the setup
./setup-mikrus.sh
```

This script will:
- Install Docker and Docker Compose
- Create project directory at `/opt/pokedex-auth-service`
- Configure firewall rules
- Set up systemd service for auto-start
- Configure Nginx reverse proxy (if installed)

**Note**: If Docker was just installed, log out and back in for group permissions to take effect:

```bash
exit
ssh your-username@srv36.mikr.us
```

### Step 3: Clone Repository

```bash
cd /opt
sudo git clone https://github.com/Mateusz-G541/pokedex-auth-service.git
cd pokedex-auth-service
```

### Step 4: Configure Environment

Create production environment file:

```bash
cp .env.production.example .env.production
nano .env.production
```

Update the following values:

```env
# Database Configuration
DATABASE_URL=mysql://auth_user:YOUR_STRONG_PASSWORD@mysql:3306/auth_db
MYSQL_ROOT_PASSWORD=YOUR_STRONG_ROOT_PASSWORD
MYSQL_DATABASE=auth_db
MYSQL_USER=auth_user
MYSQL_PASSWORD=YOUR_STRONG_PASSWORD

# Server Configuration
PORT=4000
NODE_ENV=production
HOST=0.0.0.0

# JWT Configuration (keys will be auto-generated)
JWT_PRIVATE_KEY_PATH=./keys/private.pem
JWT_PUBLIC_KEY_PATH=./keys/public.pem
JWT_EXPIRES_IN=24h

# Security Configuration
BCRYPT_ROUNDS=12
CORS_ORIGIN=http://srv36.mikr.us:20275,http://srv36.mikr.us:3000,https://your-frontend-domain.com
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Docker Hub Credentials (optional, for private images)
DOCKERHUB_USERNAME=quavaghar2
DOCKERHUB_TOKEN=your-docker-hub-token
```

**Important Security Notes**:
- Use strong, unique passwords for MySQL
- Update `CORS_ORIGIN` with your actual frontend domains
- Keep `.env.production` file secure (it's gitignored)

## Deployment Process

### First Deployment

Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh deploy
```

The script will:
1. Check dependencies (Docker, Docker Compose)
2. Pull latest code from GitHub
3. Set up environment (copy .env if needed)
4. Generate RSA keys for JWT signing
5. Login to Docker Hub (if credentials provided)
6. Pull latest Docker images
7. Start services with Docker Compose
8. Perform health checks
9. Clean up old Docker images

### Subsequent Deployments

To deploy updates:

```bash
cd /opt/pokedex-auth-service
./deploy.sh deploy
```

This will:
- Pull latest code changes
- Pull latest Docker images
- Restart services
- Verify health

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | MySQL connection string | Required |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | Required |
| `MYSQL_DATABASE` | Database name | `auth_db` |
| `MYSQL_USER` | Database user | `auth_user` |
| `MYSQL_PASSWORD` | Database password | Required |
| `PORT` | Service port | `4000` |
| `NODE_ENV` | Environment | `production` |
| `JWT_EXPIRES_IN` | JWT token expiration | `24h` |
| `BCRYPT_ROUNDS` | Password hashing rounds | `12` |
| `CORS_ORIGIN` | Allowed CORS origins | Required |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window | `900000` (15 min) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `100` |

### RSA Keys

RSA keys for JWT signing are automatically generated on first deployment:

```bash
# Keys are stored in:
/opt/pokedex-auth-service/keys/private.pem  # Private key (4096-bit)
/opt/pokedex-auth-service/keys/public.pem   # Public key
```

**Backup these keys!** If lost, all existing JWT tokens will become invalid.

### Docker Compose Configuration

The `docker-compose.prod.yml` file defines:

- **Service dependencies**: Auth service waits for MySQL to be healthy
- **Health checks**: Automatic monitoring of service health
- **Resource limits**: Memory and CPU constraints
- **Logging**: JSON file driver with rotation
- **Networks**: Isolated bridge network for services
- **Volumes**: Persistent storage for MySQL data and auth data

## Monitoring and Maintenance

### Check Service Status

```bash
cd /opt/pokedex-auth-service
./deploy.sh status
```

### View Logs

```bash
# Follow logs in real-time
./deploy.sh logs

# View last 50 lines
docker compose -f docker-compose.prod.yml logs --tail=50

# View specific service logs
docker compose -f docker-compose.prod.yml logs auth-service
docker compose -f docker-compose.prod.yml logs mysql
```

### Restart Service

```bash
./deploy.sh restart
```

### Stop Service

```bash
./deploy.sh stop
```

### Health Check

```bash
# Manual health check
./deploy.sh health

# Or directly
curl http://localhost:4000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "uptime": 123.456,
  "database": "connected"
}
```

### Database Backup

```bash
# Backup database
docker exec pokedex-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} auth_db > backup-$(date +%Y%m%d).sql

# Restore database
docker exec -i pokedex-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} auth_db < backup-20240101.sql
```

### System Service Management

The service is managed by systemd and starts automatically on boot:

```bash
# Check systemd service status
sudo systemctl status pokedex-auth.service

# Start service
sudo systemctl start pokedex-auth.service

# Stop service
sudo systemctl stop pokedex-auth.service

# Restart service
sudo systemctl restart pokedex-auth.service

# Disable auto-start
sudo systemctl disable pokedex-auth.service

# Enable auto-start
sudo systemctl enable pokedex-auth.service
```

## Troubleshooting

### Service Won't Start

1. **Check Docker status**:
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

2. **Check logs**:
   ```bash
   ./deploy.sh logs
   ```

3. **Verify environment variables**:
   ```bash
   cat .env.production
   ```

4. **Check MySQL connection**:
   ```bash
   docker exec -it pokedex-mysql mysql -u auth_user -p
   ```

### Health Check Fails

1. **Check if containers are running**:
   ```bash
   docker ps
   ```

2. **Check MySQL health**:
   ```bash
   docker exec pokedex-mysql mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD}
   ```

3. **Check auth service logs**:
   ```bash
   docker logs pokedex-auth-service
   ```

4. **Verify database migrations**:
   ```bash
   docker exec pokedex-auth-service npx prisma migrate status
   ```

### Port Already in Use

If port 4000 or 3306 is already in use:

1. **Find process using the port**:
   ```bash
   sudo lsof -i :4000
   sudo lsof -i :3306
   ```

2. **Stop conflicting service or change port** in `.env.production`

### Docker Hub Pull Fails

1. **Check Docker Hub credentials**:
   ```bash
   docker login -u quavaghar2
   ```

2. **Verify image exists**:
   ```bash
   docker pull quavaghar2/pokedex-auth-service:latest
   ```

3. **Check GitHub Actions** for build failures

### Database Connection Issues

1. **Verify MySQL is running**:
   ```bash
   docker ps | grep mysql
   ```

2. **Check database credentials** in `.env.production`

3. **Test connection**:
   ```bash
   docker exec -it pokedex-mysql mysql -u auth_user -p${MYSQL_PASSWORD} auth_db
   ```

4. **Reset database** (⚠️ destroys all data):
   ```bash
   docker compose -f docker-compose.prod.yml down -v
   docker compose -f docker-compose.prod.yml up -d
   ```

### RSA Keys Missing

If JWT signing fails:

```bash
# Regenerate keys
cd /opt/pokedex-auth-service
mkdir -p keys
openssl genrsa -out keys/private.pem 4096
openssl rsa -in keys/private.pem -pubout -out keys/public.pem
chmod 600 keys/private.pem
chmod 644 keys/public.pem

# Restart service
./deploy.sh restart
```

### Out of Disk Space

1. **Check disk usage**:
   ```bash
   df -h
   ```

2. **Clean up Docker resources**:
   ```bash
   docker system prune -a
   docker volume prune
   ```

3. **Remove old logs**:
   ```bash
   sudo journalctl --vacuum-time=7d
   ```

## CI/CD Pipeline

### GitHub Actions Workflow

The `.github/workflows/docker-build-push.yml` workflow:

1. **Triggers on**:
   - Push to `main` or `master` branch
   - Pull requests
   - Manual workflow dispatch

2. **Build process**:
   - Runs tests with MySQL service
   - Generates Prisma client
   - Builds TypeScript
   - Creates Docker image for multiple platforms (amd64, arm64)
   - Pushes to Docker Hub

3. **Testing**:
   - Runs API tests before building
   - Tests Docker image after building
   - Verifies health endpoint

### Deployment Flow

```
Code Push → GitHub Actions → Build & Test → Push to Docker Hub → VPS pulls image → Service restart
```

## Security Best Practices

1. **Use strong passwords** for MySQL and admin accounts
2. **Keep RSA keys secure** and backed up
3. **Configure CORS** properly for your frontend domains
4. **Enable rate limiting** to prevent abuse
5. **Use HTTPS** in production (configure SSL with Let's Encrypt)
6. **Regular updates**: Keep Docker images and system packages updated
7. **Monitor logs** for suspicious activity
8. **Backup database** regularly

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Prisma Documentation](https://www.prisma.io/docs/)
- [Express.js Documentation](https://expressjs.com/)

## Support

For issues or questions:
- Check the [API Documentation](./API-DOCUMENTATION.md)
- Review [GitHub Issues](https://github.com/Mateusz-G541/pokedex-auth-service/issues)
- Check deployment logs: `./deploy.sh logs`
