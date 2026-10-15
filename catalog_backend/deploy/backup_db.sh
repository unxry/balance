#!/usr/bin/env bash
set -euo pipefail

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${1:-$backend_dir/.env.production}"
backup_dir="${2:-$backend_dir/backups}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_file="$backup_dir/balance_catalog_$timestamp.dump"

mkdir -p "$backup_dir"
docker compose --env-file "$env_file" -f "$backend_dir/docker-compose.prod.yml" \
  exec -T postgres pg_dump -U balance -d balance_catalog --format=custom > "$backup_file"
test -s "$backup_file"
echo "$backup_file"
