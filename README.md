# CoWork Spaces Booking System

Sistema de gestión de reservas para espacios de coworking que permite administrar espacios, horarios y reservas, incorporando control de concurrencia para evitar solapamientos y soporte para tarifas dinámicas.

![Build and Test](https://github.com/luisguevar/cowork-spaces/actions/workflows/build-and-test.yml/badge.svg)


---

## Estructura del Repositorio

```text
cowork-spaces/
├── backend/                 # API REST en .NET 10
├── frontend/                # SPA en Angular 21
├── db/
│   ├── migrations/          # DDL: tablas, constraints e índices
│   ├── procedures/          # Stored procedures
│   ├── seed/                # Datos iniciales
│   └── init/                # Script unificado para Docker
├── docs/                    # Documentación para toma de decisiones
└── docker-compose.yml
```

---

#  Instrucciones de ejecución

## Opción A — Con Docker (Recomendado)

**Requisitos:** Docker Desktop instalado y corriendo.

```bash
git clone https://github.com/luisguevar/cowork-spaces.git
cd cowork-spaces
docker compose up --build
```

### Esto levanta automáticamente

* SQL Server con la base de datos, stored procedures y seed.
* API .NET en `http://localhost:5209`.
* Angular en `http://localhost:4200`.

---

## Opción B — Sin Docker

### FASE 1: Base de Datos

**Requisitos:** Tener SQL Server instalado localmente y ejecutar en orden el contenido de la carpeta `db`:

* **migrations/** → `001_initial_schema.sql`
* **procedures/** → `001_sp_spaces.sql`
* **procedures/** → `002_sp_bookings.sql`
* **procedures/** → `003_sp_reports.sql`
* **seed/** → `001_seed.sql`

---

### FASE 2: Backend

```bash
cd backend
dotnet restore CoWork.slnx
dotnet run --project CoWork.API/CoWork.API.csproj
```

La API queda disponible en:

```text
http://localhost:5209
```

Swagger UI:

```text
http://localhost:5209
```

---

### FASE 3: Frontend

```bash
cd frontend/cowork-frontend
npm install --legacy-peer-deps
ng serve
```

El frontend queda disponible en:

```text
http://localhost:4200
```

---

#  Cómo ejecutar los tests

## Tests unitarios (18 tests)

```bash
cd backend
dotnet test CoWork.Tests/CoWork.Tests.csproj --verbosity normal
```

### Resultado esperado

```text
Passed! - Failed: 0, Passed: 18, Skipped: 0
```

### Resultados por categoría

| Categoría           | Tests  | Resultado        |
| ------------------- | ------ | ---------------- |
| PricingEngine       | 10     | ✓ Passed         |
| CancellationPolicy  | 8      | ✓ Passed         |
| **Total unitarios** | **18** | **18/18 Passed** |

---

## Test de concurrencia

El test de concurrencia requiere SQL Server corriendo localmente:

```bash
cd backend
dotnet test CoWork.Tests/CoWork.Tests.csproj --filter "FullyQualifiedName~ConcurrencyTests" --verbosity normal
```

### Qué demuestra

Dos peticiones simultáneas al mismo espacio y horario resultan en exactamente:

* `201 Created`
* `409 Conflict`

Nunca se confirman ambas reservas.



# Decisiones de arquitectura

## Arquitectura en capas

```text
CoWork.API
├── Controllers
├── Middlewares
├── Swagger
└── DI

CoWork.Application
├── Servicios
├── DTOs
└── Validaciones (FluentValidation)

CoWork.Domain
├── Entidades
├── Excepciones
├── PricingEngine
└── CancellationPolicy

CoWork.Infrastructure
├── Repositorios (Dapper)
└── SqlConnectionFactory
```
## Colección de endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| GET | /api/spaces | Listar espacios |
| GET | /api/spaces/{id} | Detalle de espacio |
| POST | /api/spaces | Crear espacio |
| PUT | /api/spaces/{id} | Editar espacio |
| DELETE | /api/spaces/{id} | Desactivar espacio |
| GET | /api/bookings | Listar reservas |
| GET | /api/bookings/{id} | Detalle de reserva |
| POST | /api/bookings | Crear reserva |
| GET | /api/bookings/price-preview | Preview de precio |
| PATCH | /api/bookings/{id}/cancel | Cancelar reserva |
| GET | /api/reports | Reporte de ocupación e ingresos |

