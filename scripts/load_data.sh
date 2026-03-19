#!/bin/bash
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

# ── pets_catalog ──────────────────────────────────────────────
COUNT=$(curl -s "$OPENSEARCH_URL/pets_catalog/_count" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))")
if [ "$COUNT" -gt "0" ]; then
  echo "✅ pets_catalog ya tiene datos ($COUNT docs), omitiendo carga"
else
  echo ">>> Cargando datos en pets_catalog..."
  RESPONSE=$(curl -s -X POST "$OPENSEARCH_URL/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    --data-binary @data/pets_catalog.ndjson)
  if echo "$RESPONSE" | grep -q '"errors":true'; then
    echo "❌ Errores al cargar pets_catalog"
    exit 1
  else
    echo "✅ pets_catalog cargado exitosamente"
  fi
fi

# ── hotel_assets ──────────────────────────────────────────────
COUNT=$(curl -s "$OPENSEARCH_URL/hotel_assets/_count" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))")
if [ "$COUNT" -gt "0" ]; then
  echo "✅ hotel_assets ya tiene datos ($COUNT docs), omitiendo carga"
else
  echo ">>> Cargando datos en hotel_assets..."
  RESPONSE=$(curl -s -X POST "$OPENSEARCH_URL/_bulk" \
    -H "Content-Type: application/x-ndjson" \
    --data-binary @data/hotel_assets.ndjson)
  if echo "$RESPONSE" | grep -q '"errors":true'; then
    echo "❌ Errores al cargar hotel_assets"
    exit 1
  else
    echo "✅ hotel_assets cargado exitosamente"
  fi
fi

echo ""
echo ">>> Conteo final de documentos:"
curl -s "$OPENSEARCH_URL/_cat/indices/pets_catalog,hotel_assets?v&h=index,docs.count,store.size"
