#!/bin/bash
set -e

# Deploy homelab services
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

# Check .env
if [ ! -f "compose/.env" ]; then
	echo "Error: compose/.env not found!"
	echo ""
	echo "Create it from the example:"
	echo "  cp compose/.env.example compose/.env"
	echo "  chmod 600 compose/.env"
	exit 1
fi

success "Environment file found"

# Stop existing containers
echo ""
echo "Stopping existing containers..."
docker compose --env-file compose/.env -f compose/compose.yml down 2>/dev/null || true

# Start services
echo ""
echo "Starting services..."
docker compose --env-file compose/.env -f compose/compose.yml up -d --pull always

success "Services deployed successfully"
echo ""

# Show status
echo "Container status:"
docker compose --env-file compose/.env -f compose/compose.yml ps
echo ""

# Run healthcheck
if [ -x "scripts/healthcheck.sh" ]; then
	echo "Running healthcheck..."
	sleep 5
	scripts/healthcheck.sh
else
	warn "healthcheck.sh not found or not executable"
fi

echo ""
success "Deployment complete!"
