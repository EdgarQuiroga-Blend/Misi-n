# 🐾 HPG OpenSearch

> Motor de búsqueda para hotel especializado en mascotas (perros y gatos), basado en OpenSearch + Docker.

---

## 📋 Tabla de Contenidos

1. [¿Qué es este proyecto?](#qué-es-este-proyecto)
2. [Equipo](#equipo)
3. [Prerequisitos](#prerequisitos)
4. [Quickstart](#quickstart)
5. [Estructura del repositorio](#estructura-del-repositorio)
6. [Levantar el stack (up)](#levantar-el-stack-up)
7. [Inicializar índices (init)](#inicializar-índices-init)
8. [Cargar datos (load)](#cargar-datos-load)
9. [Verificar funcionamiento (verify)](#verificar-funcionamiento-verify)
10. [Dashboards](#dashboards)
11. [Limpieza total (clean)](#limpieza-total-clean)
12. [Flujo Git y contribución](#flujo-git-y-contribución)
13. [Roadmap AWS](#roadmap-aws)

---

## ¿Qué es este proyecto?

Sistema de búsqueda basado en **OpenSearch 2.x** para gestionar:

- **`pets_catalog`** — catálogo de perros y gatos del hotel.
- **`hotel_assets`** — servicios y recursos disponibles en el hotel.

El flujo completo es: `up → init → load → verify → clean`

---

## Equipo

| Integrante | Fase | Responsabilidad |
|---|---|---|
| **Edgar** | Fase A | Infraestructura & Docker |
| **Jhon**  | Fase B | Índices, Mappings y Datos |
| **Fabio** | Fase C | Queries, Verificación y Dashboards |

---

## Prerequisitos

### Software requerido

| Herramienta | Versión mínima | Verificar |
|---|---|---|
| Docker | 20.x | `docker --version` |
| Docker Compose | 2.x | `docker compose version` |
| curl | cualquiera | `curl --version` |
| git | cualquiera | `git --version` |

### Configuración del sistema (Linux)

OpenSearch requiere que `vm.max_map_count` sea al menos **262144**. El script `up.sh` lo configura automáticamente, pero puedes hacerlo manualmente:

```bash
# Temporal (se pierde al reiniciar)
sudo sysctl -w vm.max_map_count=262144

# Permanente
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

> **macOS / Windows con Docker Desktop:** No es necesario, Docker Desktop lo maneja internamente.

### RAM recomendada

- **Mínimo:** 4 GB disponibles para Docker
- **Recomendado:** 8 GB
- El JVM heap está configurado en 512m por defecto (ajustable en `.env`)

---

## Quickstart

```bash
# 1. Clonar el repositorio
git clone https://github.com/<org>/hpg-opensearch.git
cd hpg-opensearch

# 2. Levantar el stack,indices,datos etc...
./scripts/up.sh


# 3. Verificar queries y cargar Dashboard 
./scripts/verify_queries.sh

# 4. Solo detener (conserva datos)
./scripts/down.sh

# 5. Limpiar todo al finalizar
./scripts/clean.sh
```

---

## Estructura del repositorio

```
MISI-N/
├── css/
│   └── style.css
├── data/
│   ├── dashboard.ndjson            
│   ├── hotel_assets.ndjson           
│   └── pets_catalog.ndjson         
├── docker/
│   └── docker-compose.yml        # Stack OpenSearch + Dashboards
├── docs/
│   └── sources.md                # Origen y proceso de datos (Fabio)
├── opensearch/
│   ├── pets_catalog.json         # Mapping catálogo mascotas (Jhon)
│   └── hotel_assets.json         # Mapping servicios hotel (Jhon)
├── scripts/
│   ├── up.sh                     # Levantar stack
│   ├── create_hotel_data.sh 
│   ├── fix_hotel_data.sh
│   ├── scripts.js
│   ├── down.sh                   # Detener contenedores
│   ├── clean.sh                  # Eliminar todo (volúmenes + red)
│   ├── init_indices.sh           # Crear índices (Jhon)
│   ├── load_data.sh              # Cargar datasets (Jhon)
│   ├── setup_dashboards.sh
│   └── verify_queries.sh         # Ejecutar queries (Fabio)                
├── .gitignore
├── index.html
└── README.md
```

---

## Levantar el stack (up)

```bash
./scripts/up.sh
```

**¿Qué hace?**
1. Verifica prerequisitos (Docker, curl, vm.max_map_count).
2. Levanta `hpg-opensearch` y `hpg-dashboards` con Docker Compose.
3. Espera hasta que OpenSearch responda en `http://localhost:9200`.
4. Muestra las URLs de acceso.

**Cómo validar:**
```bash
curl http://localhost:9200/_cluster/health?pretty
# Esperado: "status": "green" o "yellow"
```

**Servicios levantados:**

| Servicio | URL |
|---|---|
| OpenSearch API | http://localhost:9200 |
| OpenSearch Dashboards | http://localhost:5601 |

---

## Inicializar índices (init)

> 📌 Responsable: **Jhon** — ver su módulo para detalles completos.

```bash
./scripts/init_indices.sh
```

**Cómo validar:**
```bash
curl http://localhost:9200/_cat/indices?v
# Deben aparecer: pets_catalog y hotel_assets
```

---

## Cargar datos (load)

> 📌 Responsable: **Jhon** — ver su módulo para detalles completos.

```bash
./scripts/load_data.sh
```

**Cómo validar:**
```bash
curl http://localhost:9200/pets_catalog/_count
curl http://localhost:9200/hotel_assets/_count
# Ambos deben retornar count > 0
```

---

## Verificar funcionamiento (verify)

> 📌 Responsable: **Fabio** — ver su módulo para detalles completos.

```bash
./scripts/verify_queries.sh
```

---

## Dashboards

> 📌 Responsable: **Fabio** — ver su módulo para guía completa.

Accede en: **http://localhost:5601**

---

## Limpieza total (clean)

```bash
# Solo detener (conserva datos)
./scripts/down.sh

# Eliminar todo — contenedores, volúmenes y red
./scripts/clean.sh
```

**Cómo confirmar que no quedan residuos:**
```bash
docker volume ls | grep hpg    # No debe mostrar nada
docker network ls | grep hpg   # No debe mostrar nada
docker ps -a | grep hpg        # No debe mostrar nada
```

> ⚠️ `clean.sh` elimina **todos los datos indexados**. Úsalo solo cuando quieras un entorno completamente limpio.

---

## Flujo Git y contribución

### Ramas

| Rama | Propósito |
|---|---|
| `main` | Código estable — solo merges desde `develop` |
| `develop` | Integración — aquí se mergean las features |
| `feature/fase-a-edgar` | Infraestructura (Edgar) |
| `feature/fase-b-jhon` | Índices y datos (Jhon) |
| `feature/fase-c-fabio` | Queries y dashboards (Fabio) |

### Convención de commits

```
feat:   nueva funcionalidad
fix:    corrección de errores
docs:   solo documentación
chore:  mantenimiento y estructura
test:   queries o validaciones
```

**Ejemplo:** `feat: agregar script up.sh con espera de readiness`

### Checklist de Pull Request

- [ ] El script/archivo funciona sin errores
- [ ] README actualizado con sección "Cómo validar"
- [ ] Sin secretos ni credenciales reales
- [ ] PR apunta a `develop`, no a `main`
- [ ] Descripción clara de qué hace y cómo probarlo

---

## Roadmap AWS

*(Pendiente de confirmación con el cliente)*

Opciones evaluadas para despliegue en nube:

- **Amazon OpenSearch Service** — servicio gestionado, sin administración de nodos.
- **EC2 + Docker** — mayor control, similar al entorno local.
- **ECS + Fargate** — contenedores sin servidor.

---

*🐾 HPG OpenSearch — Fabio · Jhon · Edgar*

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