#!/usr/bin/env python3
"""Chunk + embed the repo's documentation files and upsert them into the
`rag_corpus` OpenSearch index. Local-only: no external API keys, embeddings
run on CPU via sentence-transformers.

Usage:
    OPENSEARCH_URL=http://localhost:9200 python3 scripts/rag/chunk_and_embed.py
"""
import os
import sys
from pathlib import Path

from opensearchpy import OpenSearch, helpers
from sentence_transformers import SentenceTransformer

REPO_ROOT = Path(__file__).resolve().parents[2]
INDEX_NAME = "rag_corpus"
EMBEDDING_MODEL = os.environ.get("RAG_EMBEDDING_MODEL", "all-MiniLM-L6-v2")
OPENSEARCH_URL = os.environ.get("OPENSEARCH_URL", "http://localhost:9200")

CHUNK_SIZE = 1500
CHUNK_OVERLAP = 200

# Documentation-relevant files only — raw bulk data (data/*.ndjson) is
# deliberately excluded so embeddings capture architecture/usage knowledge,
# not catalog records. Adjust this list to change what the bot can answer about.
RAG_INCLUDE_GLOBS = [
    "README.md",
    "docs/**/*.md",
    "scripts/*.sh",
    "opensearch/*.json",
    "docker/docker-compose.yml",
    "index.html",
    "css/style.css",
    "scripts/scripts.js",
]


def collect_files() -> list[Path]:
    seen = set()
    files = []
    for pattern in RAG_INCLUDE_GLOBS:
        for path in sorted(REPO_ROOT.glob(pattern)):
            if path.is_file() and path not in seen:
                seen.add(path)
                files.append(path)
    return files


def chunk_text(text: str, size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> list[str]:
    if len(text) <= size:
        return [text] if text.strip() else []
    chunks = []
    start = 0
    while start < len(text):
        end = start + size
        chunks.append(text[start:end])
        if end >= len(text):
            break
        start = end - overlap
    return [c for c in chunks if c.strip()]


def main() -> None:
    client = OpenSearch(hosts=[OPENSEARCH_URL])

    print(f">>> Cargando modelo de embeddings '{EMBEDDING_MODEL}' (local, CPU)...")
    model = SentenceTransformer(EMBEDDING_MODEL)

    files = collect_files()
    if not files:
        print("No se encontraron archivos para indexar. Revisa RAG_INCLUDE_GLOBS.")
        sys.exit(1)

    print(f">>> {len(files)} archivo(s) encontrados para indexar.")

    actions = []
    total_chunks = 0
    for path in files:
        rel_path = str(path.relative_to(REPO_ROOT))
        text = path.read_text(encoding="utf-8", errors="ignore")
        chunks = chunk_text(text)
        if not chunks:
            continue

        # Idempotencia: borra los chunks previos de este archivo antes de
        # reinsertar, para que reejecutar el script no duplique documentos.
        client.delete_by_query(
            index=INDEX_NAME,
            body={"query": {"term": {"source_path": rel_path}}},
            ignore=[404],
        )

        embeddings = model.encode(chunks, show_progress_bar=False)
        for chunk_id, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
            actions.append(
                {
                    "_index": INDEX_NAME,
                    "_source": {
                        "source_path": rel_path,
                        "chunk_id": chunk_id,
                        "text": chunk,
                        "embedding": embedding.tolist(),
                    },
                }
            )
            total_chunks += 1

    helpers.bulk(client, actions)
    client.indices.refresh(index=INDEX_NAME)

    count = client.count(index=INDEX_NAME)["count"]
    print(f"✅ Ingesta completa: {total_chunks} chunks generados, {count} documentos en '{INDEX_NAME}'.")


if __name__ == "__main__":
    main()
