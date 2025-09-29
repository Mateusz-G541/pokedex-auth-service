#!/bin/bash

# Setup script for Mikrus VPS deployment
# Run this on your Mikrus VPS to prepare the environment

set -e

echo "========================================="
echo "Pokedex Auth Service - Mikrus VPS Setup"
echo "========================================="

# Update system
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed. Please log out and back in for group changes to take effect."
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Create deployment user if not exists
if ! id "deploy" &>/dev/null; then
    echo "Creating deploy user..."
    sudo useradd -m -s /bin/bash deploy
    sudo usermod -aG docker deploy
fi

# Create directory structure
echo "Creating directory structure..."
sudo mkdir -p /home/deploy/pokedex-auth-service
sudo mkdir -p /home/deploy/backups/auth-service
sudo chown -R deploy:deploy /home/deploy

# Setup firewall rules
echo "Configuring firewall..."
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 4000/tcp  # Auth Service
sudo ufw allow 3306/tcp  # MySQL (only if needed externally)
sudo ufw --force enable

# Create systemd service for auto-start
echo "Creating systemd service..."
sudo tee /etc/systemd/system/pokedex-auth.service > /dev/null << 'EOF'
[Unit]
Description=Pokedex Auth Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=deploy
WorkingDirectory=/home/deploy/pokedex-auth-service
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pokedex-auth.service

# Create nginx configuration (if nginx is installed)
if command -v nginx &> /dev/null; then
    echo "Creating nginx configuration..."
    sudo tee /etc/nginx/sites-available/auth.pokedex > /dev/null << 'EOF'
server {
    listen 80;
    server_name auth.srv36.mikr.us;

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
    }
}
EOF
    sudo ln -sf /etc/nginx/sites-available/auth.pokedex /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
fi

echo ""
echo "========================================="
echo "Setup completed!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Switch to deploy user: sudo su - deploy"
echo "2. Clone your repository to /home/deploy/pokedex-auth-service"
echo "3. Copy and configure .env.production file"
echo "4. Generate RSA keys in the keys/ directory"
echo "5. Run: docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "To deploy updates, use the deploy.sh script"
