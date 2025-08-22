#!/bin/bash

# Git setup and publish script for auth-service

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[GIT]${NC} $1"
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  init <repo-url>  - Initialize git repo and set remote"
    echo "  commit <message> - Add all files and commit with message"
    echo "  push             - Push to GitHub repository"
    echo "  setup <repo-url> - Complete setup: init + commit + push"
    echo ""
    echo "Examples:"
    echo "  $0 setup https://github.com/username/pokedex-auth-service.git"
    echo "  $0 commit 'Initial auth service implementation'"
    echo "  $0 push"
    echo ""
}

# Initialize git repository
init_repo() {
    if [ -z "$1" ]; then
        print_error "Repository URL is required"
        echo "Usage: $0 init <repo-url>"
        exit 1
    fi
    
    REPO_URL="$1"
    
    print_status "Initializing Git repository..."
    
    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        git init
        print_success "Git repository initialized"
    else
        print_warning "Git repository already exists"
    fi
    
    # Add remote origin
    if git remote get-url origin &>/dev/null; then
        print_warning "Remote 'origin' already exists, updating..."
        git remote set-url origin "$REPO_URL"
    else
        git remote add origin "$REPO_URL"
    fi
    
    print_success "Remote origin set to: $REPO_URL"
}

# Commit changes
commit_changes() {
    COMMIT_MESSAGE="$1"
    
    if [ -z "$COMMIT_MESSAGE" ]; then
        COMMIT_MESSAGE="Initial auth service implementation"
    fi
    
    print_status "Committing changes..."
    
    # Add all files
    git add .
    
    # Check if there are changes to commit
    if git diff --staged --quiet; then
        print_warning "No changes to commit"
        return 0
    fi
    
    # Commit changes
    git commit -m "$COMMIT_MESSAGE"
    print_success "Changes committed: $COMMIT_MESSAGE"
}

# Push to GitHub
push_to_github() {
    print_status "Pushing to GitHub..."
    
    # Check if remote exists
    if ! git remote get-url origin &>/dev/null; then
        print_error "No remote 'origin' configured. Run 'init' first."
        exit 1
    fi
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current)
    
    # Push to GitHub
    if git push -u origin "$CURRENT_BRANCH"; then
        print_success "Successfully pushed to GitHub!"
        
        # Show repository URL
        REPO_URL=$(git remote get-url origin)
        print_status "Repository URL: $REPO_URL"
    else
        print_error "Failed to push to GitHub"
        print_warning "Make sure:"
        print_warning "1. Repository exists on GitHub"
        print_warning "2. You have push permissions"
        print_warning "3. GitHub credentials are configured"
        exit 1
    fi
}

# Complete setup
complete_setup() {
    if [ -z "$1" ]; then
        print_error "Repository URL is required"
        echo "Usage: $0 setup <repo-url>"
        exit 1
    fi
    
    REPO_URL="$1"
    
    print_status "Starting complete Git setup..."
    
    # Initialize repository
    init_repo "$REPO_URL"
    
    # Commit all files
    commit_changes "Initial auth service implementation

Features:
- JWT authentication with RS256 signing
- User registration and login
- MySQL database with Prisma ORM
- Docker containerization
- Comprehensive bash scripts for development
- Security hardening (helmet, CORS, rate limiting)
- Input validation and error handling
- Token validation middleware for other services
- Postman collection for testing
- Monitoring and health check scripts"
    
    # Push to GitHub
    push_to_github
    
    print_success "🎉 Auth service successfully published to GitHub!"
}

# Main script logic
case "$1" in
    init)
        init_repo "$2"
        ;;
    commit)
        commit_changes "$2"
        ;;
    push)
        push_to_github
        ;;
    setup)
        complete_setup "$2"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
