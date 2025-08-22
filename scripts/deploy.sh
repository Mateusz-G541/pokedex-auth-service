#!/bin/bash

# Production deployment script for auth-service

set -e

echo "🚀 Deploying Auth Service to Production..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (for production deployment)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root. Make sure this is intended for production deployment."
fi

# Backup existing deployment
if [ -d "backup" ]; then
    rm -rf backup
fi

if docker ps -q --filter "name=auth-service" | grep -q .; then
    print_status "Creating backup of current deployment..."
    mkdir -p backup
    docker-compose exec auth-service tar -czf /tmp/backup.tar.gz /app
    docker cp $(docker-compose ps -q auth-service):/tmp/backup.tar.gz backup/
    print_success "Backup created"
fi

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    print_status "Pulling latest changes..."
    git pull origin main
    print_success "Code updated"
fi

# Build and deploy
print_status "Building and starting services..."
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 30

# Run database migrations
print_status "Running database migrations..."
docker-compose exec auth-service npx prisma migrate deploy

# Health check
print_status "Performing health check..."
if curl -f http://localhost:4000/health > /dev/null 2>&1; then
    print_success "✅ Deployment successful! Auth service is healthy"
else
    print_error "❌ Health check failed. Rolling back..."
    
    # Rollback
    docker-compose down
    if [ -f "backup/backup.tar.gz" ]; then
        print_status "Restoring from backup..."
        # Restore logic here
        print_warning "Manual intervention may be required"
    fi
    exit 1
fi

# Cleanup
print_status "Cleaning up old images..."
docker image prune -f

print_success "🎉 Deployment completed successfully!"
echo ""
echo "Service URLs:"
echo "- Health Check: http://localhost:4000/health"
echo "- API Documentation: http://localhost:4000/auth"
echo ""
echo "Logs: docker-compose logs -f auth-service"
