#!/bin/bash

# Monitoring script for auth-service

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[MONITOR]${NC} $1"
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
    echo "  status    - Show service status"
    echo "  health    - Check service health"
    echo "  logs      - Show service logs"
    echo "  metrics   - Show service metrics"
    echo "  watch     - Watch service in real-time"
    echo "  restart   - Restart services"
    echo "  stop      - Stop services"
    echo "  start     - Start services"
    echo ""
}

# Check service status
check_status() {
    print_status "Service Status Check"
    echo "===================="
    
    # Docker containers
    echo "Docker Containers:"
    docker-compose ps
    echo ""
    
    # Service health
    if curl -f http://localhost:4000/health &>/dev/null; then
        print_success "Auth Service: ✅ Healthy"
    else
        print_error "Auth Service: ❌ Unhealthy"
    fi
    
    # Database connection
    if docker-compose exec mysql mysqladmin -u auth_user -pauth_password ping &>/dev/null; then
        print_success "MySQL Database: ✅ Connected"
    else
        print_error "MySQL Database: ❌ Connection failed"
    fi
    
    # Port availability
    if netstat -tuln | grep -q ":4000 "; then
        print_success "Port 4000: ✅ In use"
    else
        print_warning "Port 4000: ⚠️  Not in use"
    fi
    
    if netstat -tuln | grep -q ":3307 "; then
        print_success "Port 3307 (MySQL): ✅ In use"
    else
        print_warning "Port 3307 (MySQL): ⚠️  Not in use"
    fi
}

# Health check with detailed response
health_check() {
    print_status "Detailed Health Check"
    echo "====================="
    
    # Auth service health
    HEALTH_RESPONSE=$(curl -s http://localhost:4000/health 2>/dev/null || echo "ERROR")
    
    if [ "$HEALTH_RESPONSE" != "ERROR" ]; then
        echo "Auth Service Response:"
        echo "$HEALTH_RESPONSE" | jq . 2>/dev/null || echo "$HEALTH_RESPONSE"
        echo ""
    else
        print_error "Auth service is not responding"
    fi
    
    # Test endpoints
    print_status "Testing endpoints..."
    
    # Public key endpoint
    if curl -f http://localhost:4000/auth/public-key &>/dev/null; then
        print_success "Public key endpoint: ✅ Working"
    else
        print_error "Public key endpoint: ❌ Failed"
    fi
    
    # Database user count
    USER_COUNT=$(docker-compose exec mysql mysql -u auth_user -pauth_password auth_db -se "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "ERROR")
    if [ "$USER_COUNT" != "ERROR" ]; then
        print_success "Database: ✅ $USER_COUNT users registered"
    else
        print_error "Database: ❌ Query failed"
    fi
}

# Show logs
show_logs() {
    echo "Recent Auth Service Logs:"
    echo "========================"
    docker-compose logs --tail=50 auth-service
    echo ""
    echo "Recent MySQL Logs:"
    echo "=================="
    docker-compose logs --tail=20 mysql
}

# Show metrics
show_metrics() {
    print_status "Service Metrics"
    echo "==============="
    
    # Container resource usage
    echo "Container Resource Usage:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $(docker-compose ps -q)
    echo ""
    
    # Disk usage
    echo "Disk Usage:"
    docker system df
    echo ""
    
    # Network connections
    echo "Active Connections:"
    netstat -tuln | grep -E ":(4000|3307) "
}

# Watch services in real-time
watch_services() {
    print_status "Watching services in real-time (Press Ctrl+C to stop)"
    
    while true; do
        clear
        echo "=== Auth Service Monitor - $(date) ==="
        echo ""
        
        # Quick status
        if curl -f http://localhost:4000/health &>/dev/null; then
            print_success "Auth Service: HEALTHY"
        else
            print_error "Auth Service: UNHEALTHY"
        fi
        
        # Container status
        echo ""
        echo "Containers:"
        docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}"
        
        # Recent logs
        echo ""
        echo "Recent Logs:"
        docker-compose logs --tail=5 auth-service 2>/dev/null | tail -5
        
        sleep 5
    done
}

# Restart services
restart_services() {
    print_status "Restarting services..."
    docker-compose restart
    sleep 10
    
    if curl -f http://localhost:4000/health &>/dev/null; then
        print_success "Services restarted successfully"
    else
        print_error "Services may not have started correctly"
    fi
}

# Stop services
stop_services() {
    print_status "Stopping services..."
    docker-compose down
    print_success "Services stopped"
}

# Start services
start_services() {
    print_status "Starting services..."
    docker-compose up -d
    sleep 15
    
    if curl -f http://localhost:4000/health &>/dev/null; then
        print_success "Services started successfully"
    else
        print_warning "Services may still be starting up"
    fi
}

# Main script logic
case "$1" in
    status)
        check_status
        ;;
    health)
        health_check
        ;;
    logs)
        show_logs
        ;;
    metrics)
        show_metrics
        ;;
    watch)
        watch_services
        ;;
    restart)
        restart_services
        ;;
    stop)
        stop_services
        ;;
    start)
        start_services
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
