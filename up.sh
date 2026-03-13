#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  up.sh — Levanta el stack HPG OpenSearch
#  Uso: ./scripts/up.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail

OPENSEARCH_URL="http://localhost:9200"
MAX_RETRIES=30
RETRY_INTERVAL=5

log()  { echo "[HPG]  $*"; }
ok()   { echo "[HPG] ✅ $*"; }
fail() { echo "[HPG] ❌ $*" >&2; exit 1; }

# ── 1. Verificar prerequisitos ────────────────────────────────
log "Verificando prerequisitos..."

command -v docker >/dev/null 2>&1  || fail "Docker no está instalado."
command -v curl   >/dev/null 2>&1  || fail "curl no está instalado."

# vm.max_map_count (Linux)
if [[ "$(uname)" == "Linux" ]]; then
  CURRENT_MAP=$(cat /proc/sys/vm/max_map_count)
  if [[ "$CURRENT_MAP" -lt 262144 ]]; then
    log "Configurando vm.max_map_count=262144 (requiere sudo)..."
    sudo sysctl -w vm.max_map_count=262144 || fail "No se pudo configurar vm.max_map_count."
  fi
fi

# ── 2. Levantar contenedores ──────────────────────────────────
log "Levantando contenedores..."
docker compose -f docker/docker-compose.yml up -d

# ── 3. Esperar que OpenSearch esté listo ──────────────────────
log "Esperando que OpenSearch responda en $OPENSEARCH_URL ..."

for i in $(seq 1 "$MAX_RETRIES"); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$OPENSEARCH_URL/_cluster/health" || true)
  if [[ "$STATUS" == "200" ]]; then
    ok "OpenSearch está listo (intento $i)."
    break
  fi
  log "Intento $i/$MAX_RETRIES — esperando $RETRY_INTERVAL segundos..."
  sleep "$RETRY_INTERVAL"
  if [[ "$i" -eq "$MAX_RETRIES" ]]; then
    fail "OpenSearch no respondió después de $MAX_RETRIES intentos."
  fi
done

# ── 4. Mostrar estado final ───────────────────────────────────
echo ""
ok "Stack levantado correctamente."
echo ""
echo "  OpenSearch:  $OPENSEARCH_URL"
echo "  Dashboards:  http://localhost:5601"
echo ""
echo "  Próximo paso: ./scripts/init_indices.sh"
