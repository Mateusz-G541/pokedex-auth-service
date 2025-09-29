#!/bin/bash

# Pokedex Auth Service Deployment Script for Mikrus VPS
# This script handles deployment with zero-downtime and rollback capability

set -e

# Configuration
SERVICE_NAME="pokedex-auth-service"
DEPLOY_DIR="/home/deploy/pokedex-auth-service"
BACKUP_DIR="/home/deploy/backups/auth-service"
DOCKER_IMAGE="pokedex-auth-service:latest"
DOCKER_COMPOSE_FILE="docker-compose.prod.yml"
ENV_FILE=".env.production"
MAX_BACKUPS=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as appropriate user
check_user() {
    if [ "$EUID" -eq 0 ]; then 
        error "Please do not run as root. Use deploy user instead."
    fi
}

# Create backup of current deployment
create_backup() {
    log "Creating backup of current deployment..."
    
    if [ -d "$DEPLOY_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_NAME="backup-$(date +'%Y%m%d-%H%M%S')"
        
        # Backup current deployment
        cp -r "$DEPLOY_DIR" "$BACKUP_DIR/$BACKUP_NAME"
        
        # Backup database
        if docker ps | grep -q pokedex-mysql; then
            docker exec pokedex-mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} auth_db > "$BACKUP_DIR/$BACKUP_NAME/database.sql"
        fi
        
        log "Backup created: $BACKUP_NAME"
        
        # Clean old backups (keep only MAX_BACKUPS)
        cd "$BACKUP_DIR"
        ls -t | tail -n +$((MAX_BACKUPS + 1)) | xargs -r rm -rf
    else
        warning "No existing deployment found, skipping backup"
    fi
}

# Pull latest code
pull_code() {
    log "Pulling latest code from repository..."
    
    cd "$DEPLOY_DIR"
    git fetch origin
    git reset --hard origin/main
    
    log "Code updated successfully"
}

# Build Docker image
build_image() {
    log "Building Docker image..."
    
    cd "$DEPLOY_DIR"
    docker build -t "$DOCKER_IMAGE" .
    
    log "Docker image built successfully"
}

# Run database migrations
run_migrations() {
    log "Running database migrations..."
    
    # Wait for MySQL to be ready
    sleep 5
    
    # Run migrations inside a temporary container
    docker run --rm \
        --network pokedex-auth-service_pokedex-network \
        --env-file "$DEPLOY_DIR/$ENV_FILE" \
        "$DOCKER_IMAGE" \
        npx prisma migrate deploy
    
    log "Migrations completed successfully"
}

# Deploy service
deploy_service() {
    log "Deploying service..."
    
    cd "$DEPLOY_DIR"
    
    # Stop existing containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" down || true
    
    # Start new containers
    docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d
    
    # Wait for health check
    log "Waiting for service to be healthy..."
    sleep 10
    
    # Check health
    if curl -f http://localhost:4000/health > /dev/null 2>&1; then
        log "Service is healthy!"
    else
        error "Service health check failed!"
    fi
}

# Rollback to previous version
rollback() {
    error "Deployment failed, rolling back..."
    
    # Find latest backup
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        log "Rolling back to: $LATEST_BACKUP"
        
        # Stop current deployment
        cd "$DEPLOY_DIR"
        docker-compose -f "$DOCKER_COMPOSE_FILE" down || true
        
        # Restore backup
        rm -rf "$DEPLOY_DIR"
        cp -r "$BACKUP_DIR/$LATEST_BACKUP" "$DEPLOY_DIR"
        
        # Restore database if backup exists
        if [ -f "$BACKUP_DIR/$LATEST_BACKUP/database.sql" ]; then
            docker exec -i pokedex-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} auth_db < "$BACKUP_DIR/$LATEST_BACKUP/database.sql"
        fi
        
        # Start previous version
        cd "$DEPLOY_DIR"
        docker-compose -f "$DOCKER_COMPOSE_FILE" --env-file "$ENV_FILE" up -d
        
        log "Rollback completed"
    else
        error "No backup found for rollback!"
    fi
}

# Setup initial deployment
initial_setup() {
    log "Performing initial setup..."
    
    # Create directories
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Clone repository (replace with your actual repo)
    cd "$(dirname "$DEPLOY_DIR")"
    git clone https://github.com/yourusername/pokedex-auth-service.git "$(basename "$DEPLOY_DIR")"
    
    cd "$DEPLOY_DIR"
    
    # Generate RSA keys if not present
    if [ ! -d "keys" ]; then
        log "Generating RSA keys..."
        mkdir -p keys
        openssl genrsa -out keys/private.pem 4096
        openssl rsa -in keys/private.pem -pubout -out keys/public.pem
        chmod 600 keys/private.pem
        chmod 644 keys/public.pem
    fi
    
    # Create .env.production file if not exists
    if [ ! -f "$ENV_FILE" ]; then
        log "Creating production environment file..."
        cat > "$ENV_FILE" << EOF
# Database
DATABASE_URL=mysql://auth_user:CHANGE_ME@mysql:3306/auth_db
MYSQL_ROOT_PASSWORD=CHANGE_ME
MYSQL_DATABASE=auth_db
MYSQL_USER=auth_user
MYSQL_PASSWORD=CHANGE_ME

# Server
PORT=4000
NODE_ENV=production

# JWT
JWT_PRIVATE_KEY_PATH=./keys/private.pem
JWT_PUBLIC_KEY_PATH=./keys/public.pem
JWT_EXPIRES_IN=24h

# Security
BCRYPT_ROUNDS=12
CORS_ORIGIN=http://srv36.mikr.us:20275,http://srv36.mikr.us:3000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
EOF
        warning "Please edit $ENV_FILE and set proper values!"
        exit 0
    fi
}

# Main deployment flow
main() {
    log "Starting deployment of $SERVICE_NAME..."
    
    check_user
    
    # Check if this is initial setup
    if [ ! -d "$DEPLOY_DIR" ]; then
        initial_setup
        exit 0
    fi
    
    # Load environment variables
    source "$DEPLOY_DIR/$ENV_FILE"
    
    # Deployment steps with error handling
    {
        create_backup
        pull_code
        build_image
        deploy_service
        run_migrations
    } || {
        rollback
    }
    
    log "Deployment completed successfully!"
    
    # Show service status
    docker ps | grep pokedex
    
    # Clean up old Docker images
    docker image prune -f
}

# Run main function
main "$@"
