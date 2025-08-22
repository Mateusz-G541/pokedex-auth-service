# Pokedex Auth Service Makefile
# Provides easy access to common development and deployment tasks

.PHONY: help setup dev build test deploy clean logs monitor db-setup db-migrate db-reset docker-up docker-down

# Default target
help:
	@echo "Pokedex Auth Service - Available Commands"
	@echo "========================================"
	@echo ""
	@echo "Setup & Development:"
	@echo "  setup          - Initial project setup (install deps, generate keys, build)"
	@echo "  dev            - Start development environment with hot reload"
	@echo "  dev-full       - Full development setup (MySQL + migrations + dev server)"
	@echo "  build          - Build TypeScript to JavaScript"
	@echo "  keys           - Generate RSA keys for JWT signing"
	@echo ""
	@echo "Testing & Quality:"
	@echo "  test           - Run integration tests"
	@echo "  lint           - Run ESLint"
	@echo "  lint-fix       - Run ESLint with auto-fix"
	@echo ""
	@echo "Database:"
	@echo "  db-setup       - Setup database (start MySQL + migrations)"
	@echo "  db-migrate     - Run database migrations"
	@echo "  db-reset       - Reset database (WARNING: destroys data)"
	@echo "  db-seed        - Seed database with test data"
	@echo "  db-backup      - Create database backup"
	@echo "  db-status      - Show database status"
	@echo ""
	@echo "Docker & Deployment:"
	@echo "  docker-up      - Start all services with Docker Compose"
	@echo "  docker-down    - Stop all Docker services"
	@echo "  docker-build   - Build Docker images"
	@echo "  deploy         - Deploy to production"
	@echo ""
	@echo "Monitoring & Logs:"
	@echo "  logs           - Show auth service logs"
	@echo "  logs-db        - Show MySQL logs"
	@echo "  monitor        - Show service status"
	@echo "  monitor-watch  - Watch services in real-time"
	@echo "  health         - Check service health"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean          - Clean build artifacts and Docker resources"
	@echo "  clean-all      - Deep clean (includes volumes and images)"

# Setup & Development
setup:
	@echo "🚀 Setting up auth service..."
	@bash scripts/setup.sh

dev:
	@echo "🔧 Starting development server..."
	@npm run dev

dev-full:
	@echo "🔧 Starting full development environment..."
	@bash scripts/dev.sh

build:
	@echo "🏗️  Building TypeScript..."
	@npm run build

keys:
	@echo "🔑 Generating RSA keys..."
	@bash scripts/generate-keys.sh

# Testing & Quality
test:
	@echo "🧪 Running integration tests..."
	@bash scripts/test.sh

lint:
	@echo "🔍 Running ESLint..."
	@npm run lint

lint-fix:
	@echo "🔧 Running ESLint with auto-fix..."
	@npm run lint:fix

# Database
db-setup:
	@echo "🗄️  Setting up database..."
	@bash scripts/db.sh setup

db-migrate:
	@echo "🗄️  Running database migrations..."
	@bash scripts/db.sh migrate

db-reset:
	@echo "⚠️  Resetting database..."
	@bash scripts/db.sh reset

db-seed:
	@echo "🌱 Seeding database..."
	@bash scripts/db.sh seed

db-backup:
	@echo "💾 Creating database backup..."
	@bash scripts/db.sh backup

db-status:
	@echo "📊 Checking database status..."
	@bash scripts/db.sh status

# Docker & Deployment
docker-up:
	@echo "🐳 Starting Docker services..."
	@docker-compose up -d

docker-down:
	@echo "🐳 Stopping Docker services..."
	@docker-compose down

docker-build:
	@echo "🐳 Building Docker images..."
	@docker-compose build --no-cache

deploy:
	@echo "🚀 Deploying to production..."
	@bash scripts/deploy.sh

# Monitoring & Logs
logs:
	@echo "📋 Showing auth service logs..."
	@docker-compose logs -f auth-service

logs-db:
	@echo "📋 Showing MySQL logs..."
	@docker-compose logs -f mysql

monitor:
	@echo "📊 Checking service status..."
	@bash scripts/monitor.sh status

monitor-watch:
	@echo "👀 Watching services in real-time..."
	@bash scripts/monitor.sh watch

health:
	@echo "🏥 Checking service health..."
	@bash scripts/monitor.sh health

# Cleanup
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf dist/
	@rm -rf node_modules/.cache/
	@docker system prune -f

clean-all:
	@echo "🧹 Deep cleaning..."
	@rm -rf dist/
	@rm -rf node_modules/
	@docker-compose down -v
	@docker system prune -af
	@docker volume prune -f

# Quick commands for common workflows
install:
	@echo "📦 Installing dependencies..."
	@npm install

start:
	@echo "🚀 Starting production server..."
	@npm start

restart:
	@echo "🔄 Restarting services..."
	@bash scripts/monitor.sh restart

stop:
	@echo "⏹️  Stopping services..."
	@bash scripts/monitor.sh stop

# Development workflow shortcuts
quick-start: keys docker-up db-migrate
	@echo "✅ Quick start completed! Service should be running on http://localhost:4000"

full-setup: setup docker-up db-migrate test
	@echo "✅ Full setup completed! Service is ready for development"

# Production workflow
production-deploy: build docker-build deploy
	@echo "✅ Production deployment completed!"

# Git commands
git-setup:
	@echo "📡 Setting up Git repository..."
	@read -p "Enter GitHub repository URL: " repo_url; \
	bash scripts/git-setup.sh setup $$repo_url

git-commit:
	@echo "📝 Committing changes..."
	@read -p "Enter commit message: " message; \
	bash scripts/git-setup.sh commit "$$message"

git-push:
	@echo "📤 Pushing to GitHub..."
	@bash scripts/git-setup.sh push

publish: git-setup
	@echo "✅ Repository published to GitHub!"
