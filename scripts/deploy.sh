#!/bin/bash
set -e

# Script: deploy.sh
# Description: Deploy homelab services

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() {
	echo -e "${GREEN}✓ $1${NC}"
}

warn() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

echo "=== Homelab Deployment ==="
echo ""

# Check if .env exists
if [ ! -f "compose/.env" ]; then
	echo "Error: compose/.env not found!"
	echo ""
	echo "Create it from the example:"
	echo "  cp compose/.env.example compose/.env"
	echo "  chmod 600 compose/.env"
	echo "  # Then edit compose/.env with your secrets"
	exit 1
fi

success "Environment file found"

# Stop existing containers if they exist
echo ""
echo "Stopping existing containers (if any)..."
docker compose --env-file compose/.env -f compose/compose.yml down 2>/dev/null || true

# Pull latest images
echo ""
echo "Pulling latest images..."
docker compose --env-file compose/.env -f compose/compose.yml pull

# Start services
echo ""
echo "Starting services..."
docker compose --env-file compose/.env -f compose/compose.yml up -d

success "Services deployed successfully"
echo ""

# Show status
echo "Container status:"
docker compose --env-file compose/.env -f compose/compose.yml ps
echo ""

# Run healthcheck
if [ -x "scripts/healthcheck.sh" ]; then
	echo "Running healthcheck..."
	sleep 5  # Give services time to start
	scripts/healthcheck.sh
else
	warn "healthcheck.sh not found or not executable"
fi

echo ""
success "Deployment complete!"
echo ""
echo "Access your services at:"
echo "  Landing page:  http://localhost/"
echo "  Vaultwarden:  http://localhost/vault"
echo "  Syncthing:    http://localhost/sync"
echo "  Filebrowser:  http://localhost/files"
echo "  Uptime Kuma:  http://localhost/status"
