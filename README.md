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

# 2. Levantar el stack
./scripts/up.sh

# 3. Inicializar índices
./scripts/init_indices.sh

# 4. Cargar datos
./scripts/load_data.sh

# 5. Verificar
./scripts/verify_queries.sh

# 6. Limpiar todo al finalizar
./scripts/clean.sh
```

---

## Estructura del repositorio

```
hpg-opensearch/
├── docker/
│   └── docker-compose.yml        # Stack OpenSearch + Dashboards
├── scripts/
│   ├── up.sh                     # Levantar stack
│   ├── down.sh                   # Detener contenedores
│   ├── clean.sh                  # Eliminar todo (volúmenes + red)
│   ├── init_indices.sh           # Crear índices (Jhon)
│   ├── load_data.sh              # Cargar datasets (Jhon)
│   └── verify_queries.sh         # Ejecutar queries (Fabio)
├── opensearch/
│   ├── pets_catalog.json         # Mapping catálogo mascotas (Jhon)
│   └── hotel_assets.json         # Mapping servicios hotel (Jhon)
├── data/
│   ├── pets_catalog.ndjson       # Dataset perros y gatos (Jhon)
│   └── hotel_assets.ndjson       # Dataset servicios (Jhon)
├── docs/
│   └── sources.md                # Origen y proceso de datos (Fabio)
├── .env.example                  # Variables de entorno (sin secretos)
├── .gitignore
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
