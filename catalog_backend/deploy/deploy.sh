#!/usr/bin/env bash
set -euo pipefail

backend_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
env_file="${1:-$backend_dir/.env.production}"
compose_file="$backend_dir/docker-compose.prod.yml"

if [[ ! -f "$env_file" ]]; then
  echo "Missing $env_file. Copy .env.production.example and set CATALOG_DOMAIN and POSTGRES_PASSWORD." >&2
  exit 2
fi

docker compose --env-file "$env_file" -f "$compose_file" config --quiet
docker compose --env-file "$env_file" -f "$compose_file" build
docker compose --env-file "$env_file" -f "$compose_file" up -d
docker compose --env-file "$env_file" -f "$compose_file" ps
