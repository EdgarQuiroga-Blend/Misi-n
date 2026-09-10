#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  rag_ingest.sh — Crea el índice rag_corpus y (re)indexa la
#  documentación del repo con embeddings locales.
#  Uso: ./scripts/rag_ingest.sh
# ─────────────────────────────────────────────────────────────
set -euo pipefail
OPENSEARCH_URL="${OPENSEARCH_URL:-http://localhost:9200}"

# ── 1. Crear índice rag_corpus si no existe ───────────────────
EXISTS=$(curl -s -o /dev/null -w "%{http_code}" "$OPENSEARCH_URL/rag_corpus")
if [ "$EXISTS" = "200" ]; then
  echo "✅ rag_corpus ya existe, omitiendo creación"
else
  echo ">>> Creando índice rag_corpus..."
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$OPENSEARCH_URL/rag_corpus" \
    -H "Content-Type: application/json" \
    -d @opensearch/rag_corpus.json)
  if [ "$STATUS" = "200" ]; then
    echo "✅ rag_corpus creado correctamente"
  else
    echo "❌ Error creando rag_corpus (HTTP $STATUS)"
    exit 1
  fi
fi

# ── 2. Chunking + embeddings + indexación ─────────────────────
echo ">>> Indexando documentación (chunking + embeddings locales)..."
python3 scripts/rag/chunk_and_embed.py

echo ""
echo ">>> Estado del índice:"
curl -s "$OPENSEARCH_URL/_cat/indices/rag_corpus?v&h=index,docs.count,store.size"
