# Fase C — Queries, Verificación y Dashboards

> **Responsable:** Fabio  
> **Branch:** `feature/fase-c-fabio`

---

## Descripción

Esta fase implementa la capa de verificación y exploración visual del sistema HPG OpenSearch. Incluye las queries de negocio que demuestran el valor del motor de búsqueda, el script de verificación automatizada y la configuración de OpenSearch Dashboards.

---

## Archivos de esta fase

| Archivo | Descripción |
|---------|-------------|
| `scripts/verify_queries.sh` | Ejecuta las 11 queries de negocio y valida resultados |
| `docs/sources.md` | Origen y proceso de generación de los datasets |

---

## Cómo ejecutar la verificación

### Prerequisitos
Antes de correr este script, asegúrate de haber ejecutado las fases anteriores:

```bash
# 1. Levantar el stack (Fase A — Edgar)
./scripts/up.sh

# 2. Crear los índices y cargar datos (Fase B — Jhon)
./scripts/init_indices.sh
./scripts/load_data.sh
```

### Ejecutar verify_queries.sh

```bash
# Dar permisos de ejecución (solo la primera vez)
chmod +x scripts/verify_queries.sh

# Ejecutar
./scripts/verify_queries.sh
```

### Variables de entorno (opcional)
El script usa los valores del `.env` por defecto. Puedes sobreescribirlos:

```bash
OPENSEARCH_HOST=http://localhost:9200 \
OPENSEARCH_USER=admin \
OPENSEARCH_PASS=admin \
./scripts/verify_queries.sh
```

### Resultado esperado

```
══════════════════════════════════════════
  Resumen de verificación
══════════════════════════════════════════
  Total queries ejecutadas : 11
  ✓ Pasaron : 11
  ✗ Fallaron: 0

🎉 Todas las queries pasaron. El sistema está funcionando correctamente.
```

---

## Queries implementadas

### Sobre `pets_catalog`

| # | Nombre | Tipo | Resultado esperado |
|---|--------|------|--------------------|
| Q1 | Gatos disponibles para adopción | bool + term | Gatos con `adoptado: false` |
| Q2 | Perros entre 10 y 30 kg | bool + range | Perros en ese rango de peso |
| Q3 | Mascotas con temperamento amigable | term | Docs con `temperamento: amigable` |
| Q4 | Razas más comunes | aggregation (terms) | Top 5 razas con conteo |
| Q5 | Promedio de edad por tipo | aggregation (avg) | Edad promedio perro vs gato |
| Q6 | Mascotas ingresadas en 2024 | range sobre fecha | Docs con `fecha_ingreso` en 2024 |
| Q7 | Búsqueda fuzzy por nombre | fuzzy | Tolerancia a errores tipográficos |

### Sobre `hotel_assets`

| # | Nombre | Tipo | Resultado esperado |
|---|--------|------|--------------------|
| Q8 | Servicios para gatos | term | Docs con `aplica_a: gato` |
| Q9 | Servicios hasta 100.000 COP | range | Servicios en ese rango de precio |
| Q10 | Tags más frecuentes | aggregation (terms) | Top 5 tags con conteo |
| Q11 | Servicios disponibles premium | bool compuesto | `disponible: true` AND `tags: premium` |

---

## OpenSearch Dashboards

### Acceso
Una vez levantado el stack, acceder a:
```
http://localhost:5601
Usuario: admin
Contraseña: admin
```

### Crear Data Views

1. Ir a **Menu → Stack Management → Index Patterns / Data Views**
2. Crear los siguientes Data Views:

| Data View | Patrón de índice | Campo de tiempo |
|-----------|-----------------|-----------------|
| Mascotas | `pets_catalog*` | `fecha_ingreso` |
| Servicios del Hotel | `hotel_assets*` | `fecha_creacion` |

3. Guardar cada Data View.

### Exploración con Discover

1. Ir a **Menu → Discover**
2. Seleccionar el Data View deseado (ej: `Mascotas`)
3. Usar el selector de tiempo (esquina superior derecha) para filtrar por rango de fechas
4. Aplicar filtros desde la barra de búsqueda, por ejemplo:
   - `tipo: gato AND adoptado: false`
   - `temperamento: amigable`
   - `tipo_servicio: spa`

### Filtros útiles en Discover

```
# Ver solo mascotas no adoptadas
adoptado: false

# Ver perros grandes
tipo: perro AND peso > 20

# Ver servicios premium activos
disponible: true AND tags: premium

# Ver servicios económicos para gatos
aplica_a: gato AND precio < 50000
```

---

## Troubleshooting

| Problema | Causa probable | Solución |
|----------|---------------|----------|
| `0 resultados` en alguna query | Datos no cargados | Ejecutar `./scripts/load_data.sh` primero |
| Error de conexión | Stack no levantado | Ejecutar `./scripts/up.sh` |
| `Error al parsear respuesta` | Índice no existe | Ejecutar `./scripts/init_indices.sh` |
| Dashboards vacío | Data View no creado | Seguir pasos de la sección anterior |

---

*🐾 Fabio · HPG OpenSearch Workshop — Fase C*
