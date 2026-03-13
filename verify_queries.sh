#!/usr/bin/env bash
# =============================================================================
# verify_queries.sh — HPG OpenSearch · Fase C (Fabio)
# Ejecuta las queries de negocio y valida que retornen resultados.
# Uso: ./scripts/verify_queries.sh
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
OPENSEARCH_HOST="${OPENSEARCH_HOST:-http://localhost:9200}"
OPENSEARCH_USER="${OPENSEARCH_USER:-admin}"
OPENSEARCH_PASS="${OPENSEARCH_PASS:-admin}"

PASS=0
FAIL=0
ERRORS=()

# Colores
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log_section() {
  echo -e "\n${CYAN}══════════════════════════════════════════${RESET}"
  echo -e "${CYAN}  $1${RESET}"
  echo -e "${CYAN}══════════════════════════════════════════${RESET}"
}

run_query() {
  local query_num="$1"
  local query_name="$2"
  local index="$3"
  local body="$4"

  echo -e "\n${YELLOW}[Q${query_num}] ${query_name}${RESET}"
  echo -e "     Índice: ${index}"

  response=$(curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
    -H "Content-Type: application/json" \
    -X GET "${OPENSEARCH_HOST}/${index}/_search" \
    -d "${body}")

  hits=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['hits']['total']['value'])" 2>/dev/null || echo "ERROR")

  if [[ "$hits" == "ERROR" ]]; then
    echo -e "     ${RED}✗ Error al ejecutar la query o parsear respuesta${RESET}"
    FAIL=$((FAIL + 1))
    ERRORS+=("Q${query_num}: ${query_name}")
  elif [[ "$hits" -gt 0 ]]; then
    echo -e "     ${GREEN}✓ OK — ${hits} resultado(s) encontrado(s)${RESET}"
    PASS=$((PASS + 1))
  else
    echo -e "     ${RED}✗ FAIL — 0 resultados (se esperaba > 0)${RESET}"
    FAIL=$((FAIL + 1))
    ERRORS+=("Q${query_num}: ${query_name} — 0 hits")
  fi
}

# ---------------------------------------------------------------------------
# Verificar que OpenSearch esté disponible
# ---------------------------------------------------------------------------
log_section "Verificando conexión con OpenSearch..."

if ! curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
     "${OPENSEARCH_HOST}/_cluster/health" | grep -qE '"status":"(green|yellow)"'; then
  echo -e "${RED}✗ No se puede conectar a OpenSearch en ${OPENSEARCH_HOST}${RESET}"
  echo -e "  Asegúrate de haber ejecutado: ./scripts/up.sh"
  exit 1
fi
echo -e "${GREEN}✓ OpenSearch accesible en ${OPENSEARCH_HOST}${RESET}"

# ---------------------------------------------------------------------------
# QUERIES SOBRE pets_catalog
# ---------------------------------------------------------------------------
log_section "Queries sobre pets_catalog"

# Q1 — Gatos disponibles (adoptado: false)
run_query 1 "Gatos disponibles para adopción" "pets_catalog" '{
  "query": {
    "bool": {
      "must": [
        { "term": { "tipo": "gato" } },
        { "term": { "adoptado": false } }
      ]
    }
  }
}'

# Q2 — Perros por peso (entre 10 y 30 kg)
run_query 2 "Perros que pesan entre 10 y 30 kg" "pets_catalog" '{
  "query": {
    "bool": {
      "must": [
        { "term": { "tipo": "perro" } },
        { "range": { "peso": { "gte": 10, "lte": 30 } } }
      ]
    }
  }
}'

# Q3 — Búsqueda por temperamento "amigable"
run_query 3 "Mascotas con temperamento amigable" "pets_catalog" '{
  "query": {
    "term": { "temperamento": "amigable" }
  }
}'

# Q4 — Razas más comunes (agregación)
echo -e "\n${YELLOW}[Q4] Razas más comunes (agregación terms)${RESET}"
echo -e "     Índice: pets_catalog"
response=$(curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -X GET "${OPENSEARCH_HOST}/pets_catalog/_search" \
  -d '{
    "size": 0,
    "aggs": {
      "razas_top": {
        "terms": { "field": "raza", "size": 5 }
      }
    }
  }')
buckets=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); b=d['aggregations']['razas_top']['buckets']; [print(f\"       - {x['key']}: {x['doc_count']}\") for x in b]" 2>/dev/null || echo "ERROR")
if [[ "$buckets" == "ERROR" ]]; then
  echo -e "     ${RED}✗ Error al ejecutar la agregación${RESET}"
  FAIL=$((FAIL + 1))
  ERRORS+=("Q4: Razas más comunes")
else
  echo -e "     ${GREEN}✓ Top razas:${RESET}"
  echo "$buckets"
  PASS=$((PASS + 1))
fi

# Q5 — Promedio de edad por tipo (perro/gato)
echo -e "\n${YELLOW}[Q5] Promedio de edad por tipo (perro / gato)${RESET}"
echo -e "     Índice: pets_catalog"
response=$(curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -X GET "${OPENSEARCH_HOST}/pets_catalog/_search" \
  -d '{
    "size": 0,
    "aggs": {
      "por_tipo": {
        "terms": { "field": "tipo" },
        "aggs": {
          "edad_promedio": { "avg": { "field": "edad" } }
        }
      }
    }
  }')
result=$(echo "$response" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for b in d['aggregations']['por_tipo']['buckets']:
    print(f\"       - {b['key']}: {b['edad_promedio']['value']:.1f} años promedio\")
" 2>/dev/null || echo "ERROR")
if [[ "$result" == "ERROR" ]]; then
  echo -e "     ${RED}✗ Error en la agregación${RESET}"
  FAIL=$((FAIL + 1))
  ERRORS+=("Q5: Promedio de edad por tipo")
else
  echo -e "     ${GREEN}✓ Resultados:${RESET}"
  echo "$result"
  PASS=$((PASS + 1))
fi

# Q6 — Mascotas ingresadas en 2024
run_query 6 "Mascotas ingresadas en 2024" "pets_catalog" '{
  "query": {
    "range": {
      "fecha_ingreso": {
        "gte": "2024-01-01",
        "lte": "2024-12-31",
        "format": "yyyy-MM-dd"
      }
    }
  }
}'

# Q7 — Búsqueda fuzzy por nombre
run_query 7 "Búsqueda fuzzy por nombre (tolerancia a errores)" "pets_catalog" '{
  "query": {
    "fuzzy": {
      "nombre": {
        "value": "max",
        "fuzziness": "AUTO"
      }
    }
  }
}'

# ---------------------------------------------------------------------------
# QUERIES SOBRE hotel_assets
# ---------------------------------------------------------------------------
log_section "Queries sobre hotel_assets"

# Q8 — Servicios para gatos
run_query 8 "Servicios disponibles para gatos" "hotel_assets" '{
  "query": {
    "term": { "aplica_a": "gato" }
  }
}'

# Q9 — Servicios por rango de precio (hasta 100.000 COP)
run_query 9 "Servicios con precio hasta 100.000 COP" "hotel_assets" '{
  "query": {
    "range": {
      "precio": { "lte": 100000 }
    }
  }
}'

# Q10 — Tags más frecuentes (agregación)
echo -e "\n${YELLOW}[Q10] Tags más frecuentes (agregación terms)${RESET}"
echo -e "      Índice: hotel_assets"
response=$(curl -s -u "${OPENSEARCH_USER}:${OPENSEARCH_PASS}" \
  -H "Content-Type: application/json" \
  -X GET "${OPENSEARCH_HOST}/hotel_assets/_search" \
  -d '{
    "size": 0,
    "aggs": {
      "tags_top": {
        "terms": { "field": "tags", "size": 5 }
      }
    }
  }')
buckets=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); b=d['aggregations']['tags_top']['buckets']; [print(f\"       - {x['key']}: {x['doc_count']}\") for x in b]" 2>/dev/null || echo "ERROR")
if [[ "$buckets" == "ERROR" ]]; then
  echo -e "     ${RED}✗ Error al ejecutar la agregación${RESET}"
  FAIL=$((FAIL + 1))
  ERRORS+=("Q10: Tags más frecuentes")
else
  echo -e "     ${GREEN}✓ Top tags:${RESET}"
  echo "$buckets"
  PASS=$((PASS + 1))
fi

# Q11 — Servicios disponibles premium (bool compuesto)
run_query 11 "Servicios disponibles con tag premium" "hotel_assets" '{
  "query": {
    "bool": {
      "must": [
        { "term": { "disponible": true } },
        { "term": { "tags": "premium" } }
      ]
    }
  }
}'

# ---------------------------------------------------------------------------
# Resumen final
# ---------------------------------------------------------------------------
log_section "Resumen de verificación"

TOTAL=$((PASS + FAIL))
echo -e "  Total queries ejecutadas : ${TOTAL}"
echo -e "  ${GREEN}✓ Pasaron : ${PASS}${RESET}"
echo -e "  ${RED}✗ Fallaron: ${FAIL}${RESET}"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo -e "\n  ${RED}Queries con problemas:${RESET}"
  for e in "${ERRORS[@]}"; do
    echo -e "    - ${e}"
  done
fi

if [[ "$FAIL" -eq 0 ]]; then
  echo -e "\n${GREEN}🎉 Todas las queries pasaron. El sistema está funcionando correctamente.${RESET}\n"
  exit 0
else
  echo -e "\n${RED}⚠️  Algunas queries fallaron. Revisa los datos cargados y los índices.${RESET}\n"
  exit 1
fi
