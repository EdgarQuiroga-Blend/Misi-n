#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  clean.sh — Elimina contenedores, volúmenes y red HPG
#  ⚠️  DESTRUYE todos los datos indexados.
#  Uso: ./scripts/clean.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

log()  { echo "[HPG]  $*"; }
ok()   { echo "[HPG] ✅ $*"; }
warn() { echo "[HPG] ⚠️  $*"; }

warn "Esto eliminará TODOS los datos del proyecto (volúmenes y red)."
read -r -p "¿Continuar? [s/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
  log "Operación cancelada."
  exit 0
fi

# ── 1. Bajar contenedores + eliminar volúmenes y red ─────────
log "Eliminando contenedores y volúmenes..."
docker compose -f docker/docker-compose.yml down --volumes --remove-orphans

# ── 2. Eliminar volumen con nombre explícito (por si acaso) ──
if docker volume ls -q | grep -q "hpg-opensearch-data"; then
  log "Eliminando volumen hpg-opensearch-data..."
  docker volume rm hpg-opensearch-data
fi

# ── 3. Eliminar red con nombre explícito (por si acaso) ───────
if docker network ls --format '{{.Name}}' | grep -q "hpg-network"; then
  log "Eliminando red hpg-network..."
  docker network rm hpg-network
fi

# ── 4. Verificar que no queda nada ───────────────────────────
echo ""
ok "Limpieza completa. No quedan volúmenes ni redes del proyecto."
echo ""
echo "  Verificar volúmenes: docker volume ls | grep hpg"
echo "  Verificar redes:     docker network ls | grep hpg"
