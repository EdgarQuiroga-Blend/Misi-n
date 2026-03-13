#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  down.sh — Detiene los contenedores HPG OpenSearch
#  Los datos (volúmenes) se conservan.
#  Uso: ./scripts/down.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

log()  { echo "[HPG]  $*"; }
ok()   { echo "[HPG] ✅ $*"; }

log "Deteniendo contenedores..."
docker compose -f docker/docker-compose.yml down

ok "Contenedores detenidos. Los datos se conservan."
echo ""
echo "  Para levantar de nuevo: ./scripts/up.sh"
echo "  Para eliminar todo:     ./scripts/clean.sh"
