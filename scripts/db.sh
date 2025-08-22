#!/bin/bash

# Database management script for auth-service

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DB]${NC} $1"
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
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Start MySQL and run initial setup"
    echo "  migrate   - Run database migrations"
    echo "  reset     - Reset database (WARNING: destroys all data)"
    echo "  seed      - Seed database with test data"
    echo "  backup    - Create database backup"
    echo "  restore   - Restore database from backup"
    echo "  status    - Show database status"
    echo "  logs      - Show MySQL logs"
    echo ""
}

# Check if MySQL container is running
check_mysql() {
    if ! docker ps | grep -q mysql; then
        print_status "Starting MySQL container..."
        docker-compose up mysql -d
        sleep 10
    fi
}

# Setup database
setup_db() {
    print_status "Setting up database..."
    check_mysql
    
    print_status "Generating Prisma client..."
    npx prisma generate
    
    print_status "Running migrations..."
    npx prisma migrate dev --name init
    
    print_success "Database setup completed"
}

# Run migrations
migrate_db() {
    print_status "Running database migrations..."
    check_mysql
    
    if docker ps | grep -q auth-service; then
        docker-compose exec auth-service npx prisma migrate deploy
    else
        npx prisma migrate dev
    fi
    
    print_success "Migrations completed"
}

# Reset database
reset_db() {
    print_warning "This will destroy all data in the database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Resetting database..."
        
        docker-compose down
        docker volume rm pokedex-auth-service_mysql_data 2>/dev/null || true
        docker-compose up mysql -d
        sleep 15
        
        npx prisma migrate dev --name init
        print_success "Database reset completed"
    else
        print_status "Reset cancelled"
    fi
}

# Seed database
seed_db() {
    print_status "Seeding database with test data..."
    check_mysql
    
    # Create a simple seed script inline
    cat > /tmp/seed.sql << EOF
USE auth_db;
INSERT IGNORE INTO users (email, password, createdAt, updatedAt) VALUES 
('admin@pokedex.com', '\$2b\$12\$LQv3c1yqBw2uuCD6Gq5kOe7Iq8VdMHQF4Hm5rJ8sK9lL0mN1oP2qR', NOW(), NOW()),
('user@pokedex.com', '\$2b\$12\$LQv3c1yqBw2uuCD6Gq5kOe7Iq8VdMHQF4Hm5rJ8sK9lL0mN1oP2qR', NOW(), NOW());
EOF

    docker-compose exec -T mysql mysql -u auth_user -pauth_password auth_db < /tmp/seed.sql
    rm /tmp/seed.sql
    
    print_success "Database seeded with test users"
    print_status "Test credentials:"
    echo "  - admin@pokedex.com / AdminPass123!"
    echo "  - user@pokedex.com / UserPass123!"
}

# Backup database
backup_db() {
    print_status "Creating database backup..."
    check_mysql
    
    BACKUP_FILE="backup/auth_db_$(date +%Y%m%d_%H%M%S).sql"
    mkdir -p backup
    
    docker-compose exec mysql mysqldump -u auth_user -pauth_password auth_db > "$BACKUP_FILE"
    
    print_success "Backup created: $BACKUP_FILE"
}

# Restore database
restore_db() {
    if [ -z "$2" ]; then
        print_error "Please specify backup file to restore"
        echo "Usage: $0 restore <backup_file>"
        exit 1
    fi
    
    BACKUP_FILE="$2"
    if [ ! -f "$BACKUP_FILE" ]; then
        print_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi
    
    print_warning "This will overwrite the current database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restoring database from $BACKUP_FILE..."
        check_mysql
        
        docker-compose exec -T mysql mysql -u auth_user -pauth_password auth_db < "$BACKUP_FILE"
        print_success "Database restored"
    else
        print_status "Restore cancelled"
    fi
}

# Show database status
show_status() {
    print_status "Database Status:"
    
    if docker ps | grep -q mysql; then
        echo "  MySQL Container: ✅ Running"
        
        # Check connection
        if docker-compose exec mysql mysqladmin -u auth_user -pauth_password ping &>/dev/null; then
            echo "  Database Connection: ✅ Connected"
            
            # Show table info
            USER_COUNT=$(docker-compose exec mysql mysql -u auth_user -pauth_password auth_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
            echo "  Users Table: $USER_COUNT users"
        else
            echo "  Database Connection: ❌ Failed"
        fi
    else
        echo "  MySQL Container: ❌ Not running"
    fi
}

# Show MySQL logs
show_logs() {
    print_status "MySQL Logs:"
    docker-compose logs mysql
}

# Main script logic
case "$1" in
    setup)
        setup_db
        ;;
    migrate)
        migrate_db
        ;;
    reset)
        reset_db
        ;;
    seed)
        seed_db
        ;;
    backup)
        backup_db
        ;;
    restore)
        restore_db "$@"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
