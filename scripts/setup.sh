#!/bin/bash

# Auth Service Setup Script
# This script sets up the auth-service with all dependencies and configurations

set -e  # Exit on any error

echo "🚀 Setting up Pokedex Auth Service..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    print_error "Please run this script from the auth-service root directory"
    exit 1
fi

# Step 1: Install dependencies
print_status "Installing Node.js dependencies..."
if command -v npm &> /dev/null; then
    npm install
    print_success "Dependencies installed"
else
    print_error "npm not found. Please install Node.js first"
    exit 1
fi

# Step 2: Generate RSA keys
print_status "Generating RSA keys for JWT signing..."
if command -v openssl &> /dev/null; then
    ./scripts/generate-keys.sh
    print_success "RSA keys generated"
else
    print_warning "OpenSSL not found. Keys will be generated in Docker container"
fi

# Step 3: Setup environment file
print_status "Setting up environment configuration..."
if [ ! -f ".env" ]; then
    cp .env.example .env
    print_success "Environment file created from template"
    print_warning "Please review and update .env file with your configuration"
else
    print_warning ".env file already exists, skipping creation"
fi

# Step 4: Generate Prisma client
print_status "Generating Prisma client..."
npx prisma generate
print_success "Prisma client generated"

# Step 5: Build TypeScript
print_status "Building TypeScript..."
npm run build
print_success "TypeScript build completed"

print_success "🎉 Auth service setup completed!"
echo ""
echo "Next steps:"
echo "1. Review and update the .env file"
echo "2. Start the services: docker-compose up -d"
echo "3. Run database migrations: docker-compose exec auth-service npx prisma migrate deploy"
echo "4. Test the service: curl http://localhost:4000/health"
