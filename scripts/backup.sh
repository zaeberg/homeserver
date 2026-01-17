#!/bin/bash
set -e

# Script: backup.sh
# Description: Backup homelab data using Restic
# Usage: ./scripts/backup.sh [local|cloud]

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

log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /srv/data/backup/backup.log
}

# Determine which repository to use
BACKUP_TYPE="${1:-}"

if [ -n "$BACKUP_TYPE" ]; then
	# New behavior: explicit type specified
	case "$BACKUP_TYPE" in
		local)
			REPO_TYPE="Local"
			RESTIC_REPO="$RESTIC_REPO_LOCAL"
			;;
		cloud)
			REPO_TYPE="Cloud"
			RESTIC_REPO="$RESTIC_REPO_CLOUD"
			;;
		*)
			error "Invalid backup type: $BACKUP_TYPE. Use 'local' or 'cloud'"
			exit 1
			;;
	esac

	# Check if repository is configured
	if [ -z "$RESTIC_REPO" ]; then
		error "RESTIC_REPO_${BACKUP_TYPE^^} is not set in compose/.env"
		error "Edit compose/.env and set RESTIC_REPO_${BACKUP_TYPE^^}"
		exit 1
	fi
else
	# Legacy behavior: use RESTIC_REPO for backward compatibility
	if [ -z "$RESTIC_REPO" ]; then
		error "RESTIC_REPO not set in compose/.env"
		error "Set RESTIC_REPO_LOCAL or RESTIC_REPO_CLOUD in compose/.env"
		exit 1
	fi
	REPO_TYPE="Default"
fi

echo "=== Homelab Backup (${REPO_TYPE}) ==="
echo "Repository: $RESTIC_REPO"
echo ""

# Check required variables
if [ -z "$RESTIC_PASSWORD" ]; then
	error "RESTIC_PASSWORD not set in compose/.env"
	exit 1
fi

# Create backup directory if it doesn't exist
sudo mkdir -p /srv/data/backup
sudo chown $USER:$USER /srv/data/backup

log "Starting ${REPO_TYPE,,} backup to: $RESTIC_REPO"

# Set default retention policy if not specified
RETENTION="${RESTIC_RETENTION:---keep-daily 7 --keep-weekly 4 --keep-monthly 6}"

# Backup targets (default: vaultwarden data + homelab-server config)
BACKUP_TARGETS="${BACKUP_TARGETS:-/srv/data/vaultwarden /srv/homelab/homelab-server}"

# Log backup targets
log "Backup targets: $BACKUP_TARGETS"

# Perform backup
log "Running restic backup..."
echo ""
if restic backup $BACKUP_TARGETS \
	--exclude-file=.gitignore \
	--exclude=".env" \
	--exclude="*.log" \
	--exclude="data/" \
	--exclude="backups/" \
	2>&1 | tee -a /srv/data/backup/backup.log; then
	log "Backup completed successfully"
	success "Backup completed successfully"
else
	log "Backup failed"
	error "Backup failed"
	exit 1
fi

# Prune old backups
echo ""
log "Running restic forget --prune with retention: $RETENTION"
echo ""
if restic forget --prune $RETENTION 2>&1 | tee -a /srv/data/backup/backup.log; then
	log "Prune completed successfully"
	success "Old snapshots pruned successfully"
else
	log "Prune failed"
	warn "Prune failed (but backup was successful)"
fi

# Show repository stats
echo ""
log "Repository statistics:"
restic stats 2>&1 | tee -a /srv/data/backup/backup.log

echo ""
log "Backup process finished"
success "Backup complete!"
