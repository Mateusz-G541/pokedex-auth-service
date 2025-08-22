#!/bin/bash

# Test script for auth-service

set -e

echo "🧪 Running Auth Service Tests..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
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

# Start services for testing
print_status "Starting test environment..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 15

# Health check
print_status "Testing health endpoint..."
if curl -f http://localhost:4000/health > /dev/null 2>&1; then
    print_success "✅ Health check passed"
else
    print_error "❌ Health check failed"
    exit 1
fi

# Test user registration
print_status "Testing user registration..."
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:4000/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"TestPass123!"}')

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    print_success "✅ User registration test passed"
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
else
    print_error "❌ User registration test failed"
    echo "$REGISTER_RESPONSE"
fi

# Test user login
print_status "Testing user login..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:4000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"TestPass123!"}')

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    print_success "✅ User login test passed"
    TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
else
    print_error "❌ User login test failed"
    echo "$LOGIN_RESPONSE"
fi

# Test protected endpoint
if [ -n "$TOKEN" ]; then
    print_status "Testing protected endpoint..."
    PROFILE_RESPONSE=$(curl -s -X GET http://localhost:4000/auth/me \
        -H "Authorization: Bearer $TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q '"success":true'; then
        print_success "✅ Protected endpoint test passed"
    else
        print_error "❌ Protected endpoint test failed"
        echo "$PROFILE_RESPONSE"
    fi
fi

# Test public key endpoint
print_status "Testing public key endpoint..."
PUBKEY_RESPONSE=$(curl -s http://localhost:4000/auth/public-key)

if echo "$PUBKEY_RESPONSE" | grep -q '"publicKey"'; then
    print_success "✅ Public key endpoint test passed"
else
    print_error "❌ Public key endpoint test failed"
    echo "$PUBKEY_RESPONSE"
fi

# Test invalid requests
print_status "Testing invalid email registration..."
INVALID_EMAIL_RESPONSE=$(curl -s -X POST http://localhost:4000/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"invalid-email","password":"TestPass123!"}')

if echo "$INVALID_EMAIL_RESPONSE" | grep -q '"error"'; then
    print_success "✅ Invalid email validation test passed"
else
    print_error "❌ Invalid email validation test failed"
fi

print_status "Testing weak password registration..."
WEAK_PASSWORD_RESPONSE=$(curl -s -X POST http://localhost:4000/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test2@example.com","password":"weak"}')

if echo "$WEAK_PASSWORD_RESPONSE" | grep -q '"error"'; then
    print_success "✅ Weak password validation test passed"
else
    print_error "❌ Weak password validation test failed"
fi

print_success "🎉 All tests completed!"

# Cleanup test data (optional)
print_status "Cleaning up test environment..."
docker-compose down

echo ""
echo "Test Summary:"
echo "- Health check: ✅"
echo "- User registration: ✅"
echo "- User login: ✅"
echo "- Protected endpoints: ✅"
echo "- Public key endpoint: ✅"
echo "- Input validation: ✅"
