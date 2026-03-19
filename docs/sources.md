# docs/sources.md — Origen y Generación de Datos

> **Autor:** Fabio · Fase C — Queries, Verificación y Dashboards  
> **Proyecto:** HPG OpenSearch · Hotel especializado para mascotas

---

## 1. Descripción general

Los datasets utilizados en este proyecto son **datos sintéticos generados manualmente** con el objetivo de simular un escenario realista de un hotel para mascotas. No provienen de fuentes externas ni de APIs de terceros.

Los datos se generaron siguiendo los mappings definidos en la Fase B (Jhon), respetando los tipos de campo, rangos de valores y restricciones documentadas en la especificación técnica.

---

## 2. Índice `pets_catalog` — Catálogo de mascotas

### Origen
Datos generados manualmente para representar perros y gatos ficticios con características físicas y de temperamento variadas.

### Criterios de generación
| Campo | Criterio |
|-------|----------|
| `nombre` | Nombres comunes de mascotas en español e inglés (Max, Luna, Simba, etc.) |
| `tipo` | Distribución ~60% perros / ~40% gatos |
| `raza` | Razas populares: Labrador, Golden Retriever, Bulldog, Siamés, Persa, etc. |
| `edad` | Rango de 0 a 15 años, distribución uniforme |
| `peso` | Perros: 2–45 kg · Gatos: 2–8 kg |
| `color` | Colores reales de pelaje: negro, blanco, café, atigrado, dorado |
| `sexo` | Distribución 50/50 macho/hembra |
| `temperamento` | Array con 1–3 valores: amigable, activo, tranquilo, tímido, juguetón |
| `adoptado` | ~30% adoptados (true), ~70% disponibles (false) |
| `fecha_ingreso` | Fechas entre 2023-01-01 y 2024-12-31 (formato yyyy-MM-dd) |
| `descripcion` | Texto libre de 1–2 oraciones describiendo la mascota |
| `vacunas` | Array con vacunas aplicadas: rabia, parvovirus, moquillo, triple felina |

### Volumen
- Mínimo: **30 documentos**
- Distribución recomendada: 18 perros + 12 gatos

### Archivo
```
data/pets_catalog.ndjson
```

---

## 3. Índice `hotel_assets` — Servicios del hotel

### Origen
Datos generados manualmente para representar los servicios e instalaciones de un hotel ficticio para mascotas en Colombia.

### Criterios de generación
| Campo | Criterio |
|-------|----------|
| `nombre` | Nombre descriptivo del servicio (ej: "Baño y corte premium", "Habitación suite") |
| `tipo_servicio` | Valores: hospedaje, baño, veterinaria, peluquería, guardería, spa, entrenamiento |
| `aplica_a` | Array con "perro", "gato" o ambos |
| `precio` | Rango: 20.000 – 300.000 COP según tipo de servicio |
| `duracion_horas` | Entre 0.5 y 24 horas (hospedaje = 24h) |
| `disponible` | ~80% disponibles (true) |
| `descripcion` | Texto libre de 1–2 oraciones |
| `tags` | Array con etiquetas: premium, spa, basico, urgencia, domicilio |
| `fecha_creacion` | Fechas entre 2022-01-01 y 2024-12-31 |
| `capacidad_max` | Entre 1 y 20 mascotas simultáneas |

### Volumen
- Mínimo: **30 documentos**

### Archivo
```
data/hotel_assets.ndjson
```

---

## 4. Proceso de carga

Los datos se cargan mediante la **Bulk API de OpenSearch**, usando el script `scripts/load_data.sh` desarrollado en la Fase B. El formato de los archivos es **NDJSON** (Newline Delimited JSON), donde cada documento se precede de una línea de acción:

```json
{ "index": { "_index": "pets_catalog" } }
{ "nombre": "Max", "tipo": "perro", "raza": "Labrador", ... }
```

---

## 5. Validación de datos

Una vez cargados, los datos se verifican con `scripts/verify_queries.sh`, que ejecuta 11 queries de negocio y valida que cada una retorne al menos 1 resultado. Ver sección de queries en el README para detalle de cada validación.

---

## 6. Notas

- Los datos **no contienen información personal real** ni datos sensibles.
- Los precios están expresados en **COP (pesos colombianos)**.
- Las fechas siguen el formato **yyyy-MM-dd** según el mapping de OpenSearch.
- Si se desea regenerar los datos, se puede repetir el proceso manual siguiendo los criterios de esta tabla, o generar nuevos documentos respetando los tipos de campo definidos en los mappings de la Fase B.