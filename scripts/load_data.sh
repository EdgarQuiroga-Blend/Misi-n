#!/bin/bash
set -euo pipefail

OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

echo ">>> Cargando datos en pets_catalog..."
RESPONSE=$(curl -s -X POST "$OPENSEARCH_URL/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @data/pets_catalog.ndjson)

if echo "$RESPONSE" | grep -q '"errors":true'; then
  echo "❌ Errores al cargar pets_catalog"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
else
  echo "✅ pets_catalog cargado exitosamente"
fi

echo ">>> Cargando datos en hotel_assets..."
RESPONSE=$(curl -s -X POST "$OPENSEARCH_URL/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @data/hotel_assets.ndjson)

if echo "$RESPONSE" | grep -q '"errors":true'; then
  echo "❌ Errores al cargar hotel_assets"
  echo "$RESPONSE" | python3 -m json.tool
  exit 1
else
  echo "✅ hotel_assets cargado exitosamente"
fi

echo ""
echo ">>> Conteo final de documentos:"
curl -s "$OPENSEARCH_URL/_cat/indices/pets_catalog,hotel_assets?v&h=index,docs.count,store.size"
