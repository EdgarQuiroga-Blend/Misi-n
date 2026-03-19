#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  up.sh — Levanta el stack HPG OpenSearch completo
#  Uso: ./scripts/up.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail
OPENSEARCH_URL="http://localhost:9200"
DASHBOARDS_URL="http://localhost:5601"
MAX_RETRIES=30
RETRY_INTERVAL=5
log()  { echo "[HPG]  $*"; }
ok()   { echo "[HPG] ✅ $*"; }
fail() { echo "[HPG] ❌ $*" >&2; exit 1; }

# ── 1. Verificar prerequisitos ────────────────────────────────
log "Verificando prerequisitos..."
command -v docker >/dev/null 2>&1 || fail "Docker no está instalado."
command -v curl   >/dev/null 2>&1 || fail "curl no está instalado."

if [[ "$(uname)" == "Linux" ]]; then
  CURRENT_MAP=$(cat /proc/sys/vm/max_map_count)
  if [[ "$CURRENT_MAP" -lt 262144 ]]; then
    log "Configurando vm.max_map_count=262144..."
    sudo sysctl -w vm.max_map_count=262144 || fail "No se pudo configurar vm.max_map_count."
  fi
fi

# ── 2. Levantar contenedores ──────────────────────────────────
log "Levantando contenedores..."
docker compose -f docker/docker-compose.yml up -d

# ── 3. Esperar OpenSearch ─────────────────────────────────────
log "Esperando que OpenSearch responda..."
for i in $(seq 1 "$MAX_RETRIES"); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$OPENSEARCH_URL/_cluster/health" || true)
  if [[ "$STATUS" == "200" ]]; then ok "OpenSearch listo (intento $i)."; break; fi
  log "Intento $i/$MAX_RETRIES — esperando $RETRY_INTERVAL segundos..."
  sleep "$RETRY_INTERVAL"
  [[ "$i" -eq "$MAX_RETRIES" ]] && fail "OpenSearch no respondió."
done

# ── 4. Inicializar índices ────────────────────────────────────
log "Inicializando índices..."
bash scripts/init_indices.sh

# ── 5. Cargar datos ───────────────────────────────────────────
log "Cargando datos..."
bash scripts/load_data.sh

# ── 6. Esperar Dashboards ─────────────────────────────────────
log "Esperando que Dashboards responda..."
for i in $(seq 1 "$MAX_RETRIES"); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$DASHBOARDS_URL/api/status" || true)
  if [[ "$STATUS" == "200" ]]; then ok "Dashboards listo (intento $i)."; break; fi
  log "Intento $i/$MAX_RETRIES — esperando $RETRY_INTERVAL segundos..."
  sleep "$RETRY_INTERVAL"
  [[ "$i" -eq "$MAX_RETRIES" ]] && fail "Dashboards no respondió."
done

# ── 7. Crear index patterns requeridos por los dashboards ─────
log "Creando index patterns..."

curl -s -X POST "$DASHBOARDS_URL/api/saved_objects/index-pattern/pets_catalog_pattern" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "pets_catalog*",
      "timeFieldName": "fecha_ingreso"
    }
  }' > /dev/null

curl -s -X POST "$DASHBOARDS_URL/api/saved_objects/index-pattern/hotel_assets_pattern" \
  -H "osd-xsrf: true" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "title": "hotel_assets*",
      "timeFieldName": "fecha_creacion"
    }
  }' > /dev/null

ok "Index patterns creados."

# ── 8. Importar dashboards ────────────────────────────────────
DASHBOARD_FILE="data/dashboard.ndjson"
if [[ -f "$DASHBOARD_FILE" ]]; then
  log "Importando dashboards..."
  IMPORT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$DASHBOARDS_URL/api/saved_objects/_import?overwrite=true" \
    -H "osd-xsrf: true" \
    --form file=@"$DASHBOARD_FILE")
  if [[ "$IMPORT_STATUS" == "200" ]]; then
    ok "Dashboards importados correctamente."
  else
    echo "[HPG] ⚠️  No se pudieron importar los dashboards (HTTP $IMPORT_STATUS)."
  fi
fi

# ── 9. Estado final ───────────────────────────────────────────
echo ""
ok "🎉 Stack completamente listo."
echo ""
echo "  OpenSearch:  $OPENSEARCH_URL"
echo "  Dashboards:  $DASHBOARDS_URL"
echo ""
