#!/bin/bash

# Check HTTP availability of homelab services

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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

# HTTP check function
check_http() {
	local url="$1"
	local name="$2"

	if command -v curl > /dev/null 2>&1; then
		status=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 5)
		if [ "$status" -ge 200 ] && [ "$status" -lt 400 ]; then
			success "$name is accessible ($status)"
			return 0
		else
			error "$name returned HTTP $status"
			return 1
		fi
	elif command -v wget > /dev/null 2>&1; then
		if wget -q --spider --timeout=5 "$url" 2>/dev/null; then
			success "$name is accessible"
			return 0
		else
			error "$name is not accessible"
			return 1
		fi
	else
		warn "Neither curl nor wget found. Skipping HTTP checks."
		return 2
	fi
}

echo "=== Homelab Healthcheck ==="
echo ""

# Check if we have curl or wget
if ! command -v curl > /dev/null 2>&1 && ! command -v wget > /dev/null 2>&1; then
	error "Neither curl nor wget found. Please install one of them."
	exit 2
fi

BASE_URL="${BASE_URL:-http://localhost}"

# Track failures
FAILURES=0

# Check each endpoint
echo "Checking endpoints at $BASE_URL..."
echo ""

check_http "$BASE_URL/" "Landing page" || FAILURES=$((FAILURES + 1))
check_http "$BASE_URL/vault/" "Vaultwarden" || FAILURES=$((FAILURES + 1))
check_http "$BASE_URL/sync/" "Syncthing" || FAILURES=$((FAILURES + 1))
check_http "$BASE_URL/files/" "Filebrowser" || FAILURES=$((FAILURES + 1))
check_http "$BASE_URL/status/" "Uptime Kuma" || FAILURES=$((FAILURES + 1))

echo ""
echo "========================================="

if [ $FAILURES -eq 0 ]; then
	success "All services are healthy!"
	exit 0
else
	error "$FAILURES service(s) failed healthcheck"
	exit 1
fi
