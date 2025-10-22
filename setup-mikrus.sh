#!/bin/bash

# Pokedex Auth Service - Mikr.us Setup Script
# Run this script on your Mikr.us VPS to prepare the environment

set -e

echo "🚀 Setting up Pokedex Auth Service on Mikr.us..."

# Update system
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "📥 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed. Please log out and back in for group changes to take effect."
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "📥 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

echo "✅ Docker version: $(docker --version)"
if command -v docker-compose &> /dev/null; then
    echo "✅ Docker Compose version: $(docker-compose --version)"
elif docker compose version &> /dev/null; then
    echo "✅ Docker Compose version: $(docker compose version)"
fi

# Create project directory
echo "📁 Creating project directory..."
sudo mkdir -p /opt/pokedex-auth-service
sudo chown -R $USER:$USER /opt/pokedex-auth-service

# Setup firewall rules (if ufw is available)
if command -v ufw &> /dev/null; then
    echo "🔒 Configuring firewall..."
    sudo ufw allow 22/tcp    # SSH
    sudo ufw allow 4000/tcp  # Auth Service
    sudo ufw allow 3306/tcp  # MySQL (only if needed externally)
    sudo ufw --force enable
    echo "✅ Firewall configured"
else
    echo "⚠️  UFW not available, skipping firewall configuration"
fi

# Create systemd service for auto-start
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/pokedex-auth.service > /dev/null << 'EOF'
[Unit]
Description=Pokedex Auth Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=/opt/pokedex-auth-service
ExecStart=/usr/bin/docker compose -f docker-compose.prod.yml up -d
ExecStop=/usr/bin/docker compose -f docker-compose.prod.yml down
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pokedex-auth.service
echo "✅ Systemd service created and enabled"

# Create nginx configuration (if nginx is installed)
if command -v nginx &> /dev/null; then
    echo "🌐 Creating nginx configuration..."
    sudo tee /etc/nginx/sites-available/auth.pokedex > /dev/null << 'EOF'
server {
    listen 80;
    server_name auth.srv36.mikr.us;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    location / {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    sudo ln -sf /etc/nginx/sites-available/auth.pokedex /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    echo "✅ Nginx configured"
else
    echo "⚠️  Nginx not installed, skipping nginx configuration"
fi

echo ""
echo "🎉 ========================================="
echo "   Setup completed!"
echo "   ========================================="
echo ""
echo "📝 Next steps:"
echo "   1. Clone repository: cd /opt && git clone https://github.com/Mateusz-G541/pokedex-auth-service.git"
echo "   2. Navigate to project: cd /opt/pokedex-auth-service"
echo "   3. Copy environment file: cp .env.production.example .env.production"
echo "   4. Edit .env.production with your database credentials and settings"
echo "   5. Run deployment script: ./deploy.sh deploy"
echo ""
echo "🔗 Test your API:"
echo "   Health check: curl http://localhost:4000/health"
echo ""
echo "📋 Useful commands:"
echo "   ./deploy.sh deploy  - Deploy/update the service"
echo "   ./deploy.sh status  - Check service status"
echo "   ./deploy.sh logs    - View service logs"
echo "   ./deploy.sh restart - Restart service"
echo "   ./deploy.sh stop    - Stop service"
echo ""
echo "🔒 Security reminder:"
echo "   - Update .env.production with strong passwords"
echo "   - RSA keys will be auto-generated on first deployment"
echo "   - Configure CORS_ORIGIN for your frontend domains"
