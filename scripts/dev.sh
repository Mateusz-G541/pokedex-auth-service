#!/bin/bash

# Development environment setup and start script

set -e

echo "🔧 Starting Auth Service in Development Mode..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if .env exists
if [ ! -f ".env" ]; then
    print_warning "No .env file found, creating from template..."
    cp .env.example .env
    print_success "Created .env file from template"
fi

# Check if keys exist
if [ ! -f "keys/private.pem" ] || [ ! -f "keys/public.pem" ]; then
    print_status "Generating RSA keys..."
    ./scripts/generate-keys.sh
fi

# Start MySQL in background if not running
if ! docker ps | grep -q mysql; then
    print_status "Starting MySQL database..."
    docker-compose up mysql -d
    
    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    sleep 10
    
    # Run migrations
    print_status "Running database migrations..."
    npx prisma migrate dev --name init
fi

# Generate Prisma client
print_status "Generating Prisma client..."
npx prisma generate

# Start development server
print_success "Starting development server on http://localhost:4000"
npm run dev
