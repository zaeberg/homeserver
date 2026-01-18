#!/bin/bash
set -e

# Script: validate.sh
# Description: Validate repository structure and security checks

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
	echo -e "${RED}✗ $1${NC}" >&2
	exit 1
}

success() {
	echo -e "${GREEN}✓ $1${NC}"
}

warn() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

# Track if any errors occurred
HAS_ERRORS=0

# Helper: check file exists
check_file() {
	if [ ! -f "$1" ]; then
		error "File not found: $1"
		HAS_ERRORS=1
		return 1
	else
		success "File exists: $1"
		return 0
	fi
}

echo "=== Homelab Repository Validation ==="
echo ""

# ==========================================
# 1. Check required files
# ==========================================
echo "Checking required files..."

check_file "compose/compose.yml"
check_file "compose/.env.example"
check_file "compose/traefik/traefik.yml"
check_file "compose/traefik/dynamic.yml"

echo ""

# ==========================================
# 2. Check Docker Compose configuration
# ==========================================
echo "Checking Docker Compose configuration..."

# Create temporary .env if it doesn't exist (for local validation)
TEMP_ENV_CREATED=false
if [ ! -f "compose/.env" ]; then
	if [ -f "compose/.env.example" ]; then
		warn "No .env found, creating temporary .env for validation"
		cp compose/.env.example compose/.env.temp
		mv compose/.env.temp compose/.env
		TEMP_ENV_CREATED=true
	fi
fi

if ! docker compose -f compose/compose.yml config > /dev/null 2>&1; then
	error "Docker Compose configuration is invalid"
	HAS_ERRORS=1
	# Remove temporary .env if it was created
	if [ "$TEMP_ENV_CREATED" = true ]; then
		rm -f compose/.env
	fi
else
	success "Docker Compose configuration is valid"
	# Remove temporary .env if it was created
	if [ "$TEMP_ENV_CREATED" = true ]; then
		rm -f compose/.env
	fi
fi

echo ""

# ==========================================
# 3. Check for 'latest' tags in images
# ==========================================
echo "Checking for 'latest' image tags..."

if grep -E "image:\s+\S+:(latest|<none>)" compose/compose.yml > /dev/null 2>&1; then
	error "Found 'latest' image tags in compose.yml. Use fixed versions only."
	HAS_ERRORS=1
else
	success "No 'latest' image tags found"
fi

echo ""

# ==========================================
# 4. Security checks
# ==========================================
echo "Running security checks..."

# 4.1 Check for .env files (except .env.example)
echo "  Checking for .env files in repository..."

ENV_FILES=$(find . -name ".env" -not -path "*/.env.example" 2>/dev/null || true)
if [ -n "$ENV_FILES" ]; then
	error "Found .env files in repository (should not be committed):"
	echo "$ENV_FILES"
	HAS_ERRORS=1
else
	success "No .env files found in repository"
fi

# 4.2 Check for secrets in compose files
echo "  Checking for hardcoded secrets in compose files..."

SECRET_PATTERNS=(
	"password="
	"api_key="
	"apikey="
	"secret="
	"token="
	"private_key="
	"SECRET\|PASSWORD\|API_KEY\|TOKEN"
)

FOUND_SECRETS=0
for pattern in "${SECRET_PATTERNS[@]}"; do
	if grep -iE "$pattern" compose/compose.yml | grep -v "CHANGE_THIS" | grep -v "# " > /dev/null 2>&1; then
		warn "Potential secret pattern found: $pattern"
		FOUND_SECRETS=1
	fi
done

if [ $FOUND_SECRETS -eq 1 ]; then
	warn "Review compose/compose.yml for potential hardcoded secrets"
else
	success "No hardcoded secrets found in compose files"
fi

# 4.3 Check for common secret file patterns
echo "  Checking for sensitive files in repository..."

SENSITIVE_FILES=(
	"*.pem"
	"*.key"
	"*.crt"
	"id_rsa"
	"id_ed25519"
	"credentials.json"
	".aws/credentials"
	".secrets"
)

FOUND_SENSITIVE=0
for pattern in "${SENSITIVE_FILES[@]}"; do
	if find . -name "$pattern" 2>/dev/null | grep -v ".git/" | grep -v "node_modules/" | read; then
		warn "Found potentially sensitive file matching: $pattern"
		FOUND_SENSITIVE=1
	fi
done

if [ $FOUND_SENSITIVE -eq 0 ]; then
	success "No sensitive files found"
fi

# 4.4 Check if .env is tracked by git
echo "  Checking if .env files are tracked by git..."

if git ls-files | grep -q "\.env$"; then
	error ".env file is tracked by git. Remove it with: git rm --cached compose/.env"
	HAS_ERRORS=1
else
	success "No .env files tracked by git"
fi

echo ""

# ==========================================
# 5. Check script permissions
# ==========================================
echo "Checking script permissions..."

SCRIPTS="scripts/deploy.sh scripts/healthcheck.sh scripts/backup.sh scripts/restore_test.sh"
for script in $SCRIPTS; do
	if [ -f "$script" ]; then
		if [ -x "$script" ]; then
			success "Script is executable: $script"
		else
			warn "Script is not executable: $script (run: chmod +x $script)"
		fi
	fi
done

echo ""
echo "========================================="

# Final result
if [ $HAS_ERRORS -eq 0 ]; then
	success "All validation checks passed!"
	exit 0
else
	error "Validation failed. Please fix the errors above."
	exit 1
fi
