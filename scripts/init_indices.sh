#!/bin/bash
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

# ── pets_catalog ──────────────────────────────────────────────
EXISTS=$(curl -s -o /dev/null -w "%{http_code}" "$OPENSEARCH_URL/pets_catalog")
if [ "$EXISTS" = "200" ]; then
  echo "✅ pets_catalog ya existe, omitiendo creación"
else
  echo ">>> Creando índice pets_catalog..."
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$OPENSEARCH_URL/pets_catalog" \
    -H "Content-Type: application/json" \
    -d @opensearch/pets_catalog.json)
  if [ "$STATUS" = "200" ]; then
    echo "✅ pets_catalog creado correctamente"
  else
    echo "❌ Error creando pets_catalog (HTTP $STATUS)"
    exit 1
  fi
fi

# ── hotel_assets ──────────────────────────────────────────────
EXISTS=$(curl -s -o /dev/null -w "%{http_code}" "$OPENSEARCH_URL/hotel_assets")
if [ "$EXISTS" = "200" ]; then
  echo "✅ hotel_assets ya existe, omitiendo creación"
else
  echo ">>> Creando índice hotel_assets..."
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$OPENSEARCH_URL/hotel_assets" \
    -H "Content-Type: application/json" \
    -d @opensearch/hotel_assets.json)
  if [ "$STATUS" = "200" ]; then
    echo "✅ hotel_assets creado correctamente"
  else
    echo "❌ Error creando hotel_assets (HTTP $STATUS)"
    exit 1
  fi
fi

echo ""
echo ">>> Índices disponibles:"
curl -s "$OPENSEARCH_URL/_cat/indices?v"
