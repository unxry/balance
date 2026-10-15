#!/usr/bin/env bash
set -euo pipefail

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${1:-$backend_dir/.env.production}"

docker compose --env-file "$env_file" -f "$backend_dir/docker-compose.prod.yml" \
  run --rm validate
