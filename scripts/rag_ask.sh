#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  rag_ask.sh — Pregunta al bot de documentación local (RAG).
#  Uso: ./scripts/rag_ask.sh "¿Cómo se levanta el stack?"
# ─────────────────────────────────────────────────────────────
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo 'Uso: ./scripts/rag_ask.sh "tu pregunta"'
  exit 1
fi

python3 scripts/rag/ask.py "$@"
