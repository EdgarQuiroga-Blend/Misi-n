#!/usr/bin/env python3
"""Retrieve + generate: answers a question grounded strictly in the repo's
own documentation, indexed in the OpenSearch `rag_corpus` index.

Usage:
    python3 scripts/rag/ask.py "¿Cómo se levanta el stack?"
"""
import os
import sys

import requests
from opensearchpy import OpenSearch
from sentence_transformers import SentenceTransformer

INDEX_NAME = "rag_corpus"
EMBEDDING_MODEL = os.environ.get("RAG_EMBEDDING_MODEL", "all-MiniLM-L6-v2")
OPENSEARCH_URL = os.environ.get("OPENSEARCH_URL", "http://localhost:9200")
OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
LLM_MODEL = os.environ.get("RAG_LLM_MODEL", "llama3.2")
TOP_K = int(os.environ.get("RAG_TOP_K", "5"))

SYSTEM_PROMPT_TEMPLATE = """\
Eres el asistente de documentación del proyecto HPG OpenSearch (buscador para un hotel de
mascotas, basado en OpenSearch + Docker).

Los resultados de búsqueda de abajo son tu ÚNICA fuente de verdad. No tienes conocimiento propio
del proyecto: todo lo que afirmes debe estar escrito en ellos.

Reglas de contenido (OBLIGATORIAS):
- Usa SOLO lo que aparezca explícitamente en los resultados. No inventes ni completes con
  conocimiento general.
- Si los resultados no alcanzan para responder con certeza, dilo explícitamente y señala qué falta.
- Si cubren solo parte de la pregunta, responde esa parte y señala qué no está documentado.
- Si la pregunta es ajena a este proyecto, dilo en una frase y no sigas la conversación por ahí.

Reglas de estilo (OBLIGATORIAS):
- Empieza directamente con la respuesta (sin "Respuesta:" ni repetir la pregunta).
- Markdown claro: negritas en términos clave, listas cuando enumeres.

Resultados de búsqueda:
{search_results}

IDIOMA (REGLA FINAL): responde SIEMPRE en español, incluidos los rechazos. Conserva sin traducir
los literales técnicos (nombres de archivos, comandos, variables de entorno, rutas).
"""


def retrieve(question: str, client: OpenSearch, model: SentenceTransformer) -> list[dict]:
    query_vector = model.encode(question).tolist()
    response = client.search(
        index=INDEX_NAME,
        body={
            "size": TOP_K,
            "query": {"knn": {"embedding": {"vector": query_vector, "k": TOP_K}}},
        },
    )
    return [hit["_source"] for hit in response["hits"]["hits"]]


def generate(question: str, chunks: list[dict]) -> str:
    if not chunks:
        search_results = "(sin resultados)"
    else:
        search_results = "\n\n".join(
            f"[Fuente: {c['source_path']}]\n{c['text']}" for c in chunks
        )
    system_prompt = SYSTEM_PROMPT_TEMPLATE.format(search_results=search_results)

    response = requests.post(
        f"{OLLAMA_URL}/api/generate",
        json={
            "model": LLM_MODEL,
            "system": system_prompt,
            "prompt": question,
            "stream": False,
            "options": {"temperature": 0},
        },
        timeout=120,
    )
    response.raise_for_status()
    return response.json()["response"].strip()


def main() -> None:
    if len(sys.argv) < 2:
        print('Uso: python3 scripts/rag/ask.py "tu pregunta"')
        sys.exit(1)
    question = " ".join(sys.argv[1:])

    client = OpenSearch(hosts=[OPENSEARCH_URL])
    model = SentenceTransformer(EMBEDDING_MODEL)

    chunks = retrieve(question, client, model)
    answer = generate(question, chunks)

    print(answer)
    if chunks:
        sources = sorted({c["source_path"] for c in chunks})
        print("\nFuentes:")
        for source in sources:
            print(f"  - {source}")


if __name__ == "__main__":
    main()
