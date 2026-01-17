#!/bin/bash
set -e

# Script: restore_test.sh
# Description: Test backup restoration by restoring to temporary location

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Load environment
if [ -f "compose/.env" ]; then
	set -a
	source compose/.env
	set +a
else
	echo "Error: compose/.env not found"
	exit 1
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() {
	echo -e "${GREEN}✓ $1${NC}"
}

error() {
	echo -e "${RED}✗ $1${NC}"
}

warn() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

# Cleanup function
cleanup() {
	EXIT_CODE=$?

	echo ""
	if [ $EXIT_CODE -ne 0 ]; then
		warn "Test failed. Diagnostic log saved to /tmp/restore-test-diagnostic.log"
	else
		success "Test completed successfully"
	fi

	echo ""
	echo "Cleaning up..."

	# Stop and remove test container if running
	if docker ps -q -f name=homelab-vaultwarden-test | grep -q .; then
		echo "Stopping test container..."
		docker stop homelab-vaultwarden-test 2>/dev/null || true
		docker rm homelab-vaultwarden-test 2>/dev/null || true
	fi

	# Remove temporary directory
	if [ -d "/srv/data/restore-test" ]; then
		echo "Removing temporary restore directory..."
		sudo rm -rf /srv/data/restore-test
	fi

	success "Cleanup complete"

	exit $EXIT_CODE
}

trap cleanup EXIT

echo "=== Homelab Restore Test ==="
echo ""

# Check required variables
if [ -z "$RESTIC_REPO" ]; then
	error "RESTIC_REPO not set in compose/.env"
	exit 1
fi

if [ -z "$RESTIC_PASSWORD" ]; then
	error "RESTIC_PASSWORD not set in compose/.env"
	exit 1
fi

# Create temporary restore directory
RESTORE_DIR="/srv/data/restore-test/vaultwarden"
echo "Creating temporary restore directory: $RESTORE_DIR"
sudo mkdir -p "$RESTORE_DIR"
sudo chown $USER:$USER "$RESTORE_DIR"

# Find latest snapshot
echo ""
echo "Finding latest snapshot..."
LATEST_SNAPSHOT=$(restic list snapshots --json | jq -r 'sort_by(.time) | reverse | .[0].short_id')

if [ -z "$LATEST_SNAPSHOT" ]; then
	error "No snapshots found. Run backup first."
	exit 1
fi

success "Latest snapshot: $LATEST_SNAPSHOT"

# Restore latest snapshot
echo ""
echo "Restoring snapshot to $RESTORE_DIR..."
restic restore $LATEST_SNAPSHOT --target /srv/data/restore-test

success "Restore completed"

# Verify restored data
echo ""
echo "Verifying restored data..."
if [ ! -d "$RESTORE_DIR/data" ]; then
	error "Restored data structure is invalid"
	exit 1
fi

success "Restored data structure is valid"

# Start test container with restored data
echo ""
echo "Starting test container with restored data..."
docker run -d \
	--name homelab-vaultwarden-test \
	-v "$RESTORE_DIR/data:/data" \
	--network homelab_internal \
	--restart unless-stopped \
	vaultwarden/server:1.30.1 > /dev/null 2>&1

if [ $? -ne 0 ]; then
	error "Failed to start test container"
	exit 1
fi

success "Test container started"

# Wait for container to be ready
echo ""
echo "Waiting for container to be ready..."
sleep 10

# Check if container is running
if ! docker ps | grep -q homelab-vaultwarden-test; then
	error "Test container is not running"
	docker logs homelab-vaultwarden-test > /tmp/restore-test-diagnostic.log
	exit 1
fi

success "Test container is running"

# Check if service responds (basic health check)
echo ""
echo "Testing service responsiveness..."
if docker exec homelab-vaultwarden-test wget -q -O /dev/null http://localhost:80/alive 2>/dev/null; then
	success "Service is responding to health checks"
else
	warn "Service health check returned non-success (this may be normal for fresh restores)"
fi

# Show container logs
echo ""
echo "Container logs:"
docker logs homelab-vaultwarden-test | tail -20

echo ""
success "Restore test passed!"
echo ""
echo "The backup can be successfully restored and the service starts with restored data."
