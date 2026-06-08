
# CoWork Spaces Booking System

Sistema de gestión de reservas para espacios de coworking con control de concurrencia, tarifas dinámicas y autenticación JWT.

![Build and Test](https://github.com/luisguevar/cowork-spaces/actions/workflows/build-and-test.yml/badge.svg)


---

## Stack Tecnológico

| Capa                | Tecnologías                                            |
| ------------------- | ------------------------------------------------------ |
| **Backend**         | .NET 10, Dapper, SQL Server                            |
| **Frontend**        | Angular 21, TypeScript, Angular Material, FullCalendar |
| **Base de Datos**   | SQL Server 2022                                        |
| **Infraestructura** | Docker, GitHub Actions                                 |

---
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
├── postman/                 # Colección de Postman
└── docker-compose.yml
```

---

## Índice de Contenido del README

1. [Instrucciones de instalación y ejecución](#instrucciones-de-instalación-y-ejecución)
2. [Decisiones de arquitectura y trade-offs](#decisiones-de-arquitectura-y-trade-offs)
3. [Justificación de la estrategia de concurrencia elegida](#justificación-de-la-estrategia-de-concurrencia-elegida)
4. [Orden de aplicación de las reglas de tarifas](#orden-de-aplicación-de-las-reglas-de-tarifas)
5. [Cómo ejecutar los tests](#cómo-ejecutar-los-tests)

---

# Instrucciones de instalación y ejecución

## Opción A — Con Docker (Recomendado)

### Requisitos

* Docker Desktop instalado y corriendo.

### Pasos

```bash
git clone https://github.com/luisguevar/cowork-spaces.git
cd cowork-spaces
docker compose up --build
```

### Servicios disponibles

Esto levanta automáticamente los tres servicios sin ningún paso adicional:

| Servicio         | URL                   |
| ---------------- | --------------------- |
| Frontend Angular | http://localhost:4200 |
| API .NET         | http://localhost:5209 |
| Swagger UI       | http://localhost:5209 |

---

## Opción B — Sin Docker

### Requisitos

* .NET 10 SDK
* Node.js 22
* Angular CLI 21

```bash
npm install -g @angular/cli@21
```

* SQL Server (local o remoto)

### Paso 1 — Base de Datos

Ejecutar en orden el contenido de la carpeta `db`:

* **migrations/** → `001_initial_schema.sql`
* **procedures/** → `001_sp_schema.sql`
* **seed/** → `001_seed.sql`

O como alternativa puede usar la carpeta **init/** → `001_init.sql` que fue creada para levantar con docker.

### Paso 2 — Backend

```bash
cd backend
dotnet restore CoWork.slnx
dotnet run --project CoWork.API/CoWork.API.csproj
```

Verificar que la API responde en:

```text
http://localhost:5209
```

Y que Swagger carga correctamente.

### Paso 3 — Frontend

```bash
cd frontend/cowork-frontend
npm install --legacy-peer-deps
ng serve
```

Abrir en el navegador:

```text
http://localhost:4200
```

---

## Credenciales por defecto

Todos los usuarios generados por el script de seed tienen la contraseña:

```text
12345678
```

| Nombre        | Email                                                     |
| ------------- | --------------------------------------------------------- |
| John Smith    | [john.smith@email.com](mailto:john.smith@email.com)       |
| Maria Garcia  | [maria.garcia@email.com](mailto:maria.garcia@email.com)   |
| Carlos Lopez  | [carlos.lopez@email.com](mailto:carlos.lopez@email.com)   |
| Ana Martinez  | [ana.martinez@email.com](mailto:ana.martinez@email.com)   |
| Peter Johnson | [peter.johnson@email.com](mailto:peter.johnson@email.com) |

---

# Decisiones de arquitectura y trade-offs

Esta sección resume las principales decisiones técnicas adoptadas durante el desarrollo de la solución, junto con sus ventajas y compromisos asumidos.

> 📚 **Documentación complementaria**
>
> Se ha preparado documentación adicional con mayor nivel de detalle sobre las decisiones de diseño, justificaciones técnicas, actividades realizadas y análisis por capa de la arquitectura:
>
> https://drive.google.com/drive/folders/1ObNlVw-5Zx4KFE_rd5wNfVg-tnmFwEfq?usp=sharing

---

## Arquitectura en capas

El backend está dividido en cuatro proyectos con dependencias unidireccionales:

```text
CoWork.API
 └─ Controllers
 └─ Middlewares
 └─ Swagger

CoWork.Application
 └─ Services
 └─ DTOs
 └─ Validators (FluentValidation)

CoWork.Domain
 └─ Entities
 └─ Exceptions
 └─ PricingEngine
 └─ CancellationPolicy

CoWork.Infrastructure
 └─ Repositories (Dapper)
 └─ SqlConnectionFactory

CoWork.Tests
 └─ CancellationPolicy
 └─ Concurrency
 └─ PricingEngine
```

### Regla de dependencias

```text
Domain         → no depende de nadie
Infrastructure → depende de Domain
Application    → depende de Domain
API            → depende de todos
Tests          → depende de Domain, Application, Infrastructure y API
```

Esta separación garantiza que la lógica de negocio sea completamente testeable sin dependencia de base de datos ni framework web.

---

## Dapper con Stored Procedures

Se eligió Dapper sobre Entity Framework Core porque el control de concurrencia requiere `WITH (UPDLOCK, ROWLOCK)` — SQL que EF Core no puede generar de forma natural. Los stored procedures permiten que el lock y la verificación de solapamiento ocurran completamente en SQL Server sin round-trips adicionales, y pueden ser revisados y optimizados por un DBA de forma independiente al código C#.

---

## Interfaces de repositorios en Domain

Las interfaces `ISpaceRepository`, `IBookingRepository`, `IReportRepository`, `IUserRepository` e `IAuthRepository` viven en Domain para que el dominio defina sus contratos sin conocer la implementación. Si vivieran en Infrastructure, Application dependería de Infrastructure para usarlas, invirtiendo la dirección correcta de dependencias.

---

## PricingEngine y CancellationPolicy como clases concretas

Son lógica de dominio pura sin dependencias externas — no se abstraen detrás de interfaces porque no hay razón para reemplazarlas. Los tests las instancian directamente con `new PricingEngine()` sin mocks ni contenedor de DI.

El precio siempre se calcula en C# y se pasa como parámetro a `sp_CreateBooking` — el stored procedure nunca contiene reglas de negocio, lo que garantiza que el motor de precios sea testeable de forma aislada.

---

## FluentValidation en la capa Application

Las validaciones de entrada viven en clases dedicadas — `CreateSpaceValidator`, `CreateBookingValidator` y `PricePreviewValidator` — registradas automáticamente con `AddValidatorsFromAssemblyContaining<T>()`. FluentValidation las ejecuta antes de que el request llegue al controller — si hay errores retorna `400 Bad Request` automáticamente sin ejecutar lógica de negocio ni acceder a la base de datos.

---

## Middleware global de excepciones

El manejo de errores se centraliza mediante un único middleware. Las excepciones de dominio se traducen automáticamente al código HTTP correspondiente:

| Excepción                      | Código HTTP               |
| ------------------------------ | ------------------------- |
| BookingConflictException       | 409 Conflict              |
| NotFoundException              | 404 Not Found             |
| BookingNotCancellableException | 400 Bad Request           |
| DomainException                | 400 Bad Request           |
| Exception                      | 500 Internal Server Error |

### Estrategia de logging

* Errores de negocio → `Warning`
* Errores inesperados → `Error`

Todas las respuestas siguen el estándar **ProblemDetails (RFC 7807)**:

```json
{
  "status": 400,
  "title": "Business Rule Violation",
  "detail": "...",
  "instance": "/api/bookings"
}
```

---

## Autenticación JWT

Se implementó autenticación basada en JWT utilizando BCrypt para el almacenamiento seguro de contraseñas.

El token contiene:

* UserId
* Email
* Name

### Backend

Los endpoints de escritura están protegidos mediante:

```csharp
[Authorize]
```

Entre ellos:

* Crear reservas.
* Cancelar reservas.
* Crear espacios.
* Editar espacios.

Los endpoints de consulta permanecen públicos.

### Frontend

El token se almacena en `localStorage` para conservar la sesión entre recargas.

Además:

* Se valida la expiración del token al restaurar sesión.
* Un interceptor HTTP agrega automáticamente el token en cada solicitud autenticada.

---

## Docker con inicialización automática

La solución se ejecuta mediante un único archivo `docker-compose.yml` que orquesta:

* SQL Server
* Backend .NET
* Frontend Angular

Durante el arranque:

- PASO 1: SQL Server inicia.
- PASO 2: Se ejecuta automáticamente `db/init/001_init.sql`.
- PASO 3: Se crean tablas, procedimientos almacenados y datos semilla.
- PASO 4: El backend espera a que la base de datos esté disponible mediante:

```yaml
depends_on:
  condition: service_healthy
```

Esto elimina configuraciones manuales y permite levantar el entorno completo con un único comando.

---

# Trade-offs

| Decisión                        | Ventaja                                                               | Trade-off                                                                                          |
| ------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Dapper + Stored Procedures      | Control total sobre el SQL crítico                                    | No existen migraciones automáticas; los scripts deben mantenerse manualmente fuera de Docker       |
| Pessimistic Locking             | Comportamiento determinista ante concurrencia                         | Mayor contención bajo alta carga                                                                   |
| PricingEngine en C#             | Totalmente testeable de forma aislada                                 | El frontend debe replicar parte del desglose para mostrar previews en tiempo real                  |
| Monorepo                        | Un único repositorio y un único comando de despliegue                 | Pipeline CI/CD más complejo                                                                        |
| JWT en localStorage             | Persistencia de sesión entre recargas                                 | localStorage es accesible desde JavaScript; en producción sería recomendable usar cookies httpOnly |
| Stored Procedures para reportes | Una única llamada retorna múltiples resultsets mediante QueryMultiple | Más difícil de testear unitariamente que lógica escrita en C#                                      |
| HTTP en desarrollo              | Configuración local simple                                            | HTTPS debe configurarse antes de un despliegue productivo                                          |

---

En conjunto, estas decisiones priorizan simplicidad operativa, testabilidad de la lógica de negocio, control explícito de concurrencia y facilidad de despliegue para el alcance de la solución propuesta.

## Justificación de la estrategia de concurrencia elegida

El sistema debe garantizar que nunca se confirmen dos reservas solapadas para el mismo espacio, incluso cuando múltiples peticiones lleguen simultáneamente. Se evaluaron tres estrategias antes de elegir.

**Optimistic Concurrency** — descartado. Asume que los conflictos son raros, pero en un sistema de reservas son el escenario central: espacios populares en horarios pico generan colisiones frecuentes. Produciría reintentos constantes y degradaría la experiencia del usuario.

**Exclusion Constraint** — descartado. SQL Server no soporta exclusion constraints nativos como PostgreSQL. Simularlo requiere triggers o índices filtrados con lógica no estándar que añade complejidad sin ventajas claras.

**Pessimistic Locking con `WITH (UPDLOCK, ROWLOCK)`** — elegido. El comportamiento es determinista: la primera transacción adquiere el lock, verifica disponibilidad e inserta. La segunda espera, reevalúa, detecta el conflicto y retorna `409 Conflict`. Todo ocurre en una sola transacción sin round-trips adicionales. El lock es a nivel de fila (`ROWLOCK`), por lo que dos reservas para espacios distintos no se bloquean entre sí.

### Beneficios de los hints utilizados

#### ROWLOCK

```sql
WITH (ROWLOCK)
```

Garantiza que el bloqueo ocurra únicamente sobre la fila correspondiente al espacio reservado.

Esto evita bloqueos innecesarios sobre:

* Otras filas.
* Otras páginas.
* La tabla completa.

Como resultado, dos usuarios pueden reservar espacios distintos de forma simultánea sin interferirse.

#### UPDLOCK

```sql
WITH (UPDLOCK)
```

Indica que la intención de la transacción es modificar datos posteriormente.

Esto reduce significativamente la posibilidad de deadlocks cuando múltiples transacciones intentan escalar locks compartidos a exclusivos al mismo tiempo.

---

## Implementación

Toda la lógica se ejecuta dentro de `sp_CreateBooking` y de una única transacción.

```sql
BEGIN TRANSACTION

    -- 1. Adquirir lock pesimista sobre el espacio
    --    UPDLOCK: intención de escritura
    --    ROWLOCK: bloqueo a nivel de fila
    SELECT Id
    FROM Spaces WITH (UPDLOCK, ROWLOCK)
    WHERE Id = @SpaceId

    -- 2. Verificar solapamiento
    IF EXISTS (
        SELECT 1
        FROM Bookings
        WHERE SpaceId = @SpaceId
          AND Status NOT IN ('Cancelled')
          AND StartTime < @EndTime
          AND EndTime > @StartTime
    )
    BEGIN
        ROLLBACK
        RAISERROR('BOOKING_CONFLICT', 16, 1)
        RETURN
    END

    -- 3. Crear reserva
    INSERT INTO Bookings (...)
    VALUES (...)

COMMIT
```

### Detección de solapamientos

La condición:

```sql
StartTime < @EndTime
AND EndTime > @StartTime
```

cubre correctamente todos los escenarios posibles:

* Solapamiento parcial izquierdo.
* Solapamiento parcial derecho.
* Solapamiento total.
* Reserva completamente contenida dentro de otra.

---

## Ventaja de ejecutar la lógica dentro de SQL Server

La adquisición del lock y la validación de disponibilidad ocurren completamente dentro del motor de base de datos.

Esto evita:

* Round-trips adicionales.
* Ventanas de tiempo entre validación e inserción.
* Riesgo de condiciones de carrera generadas por lógica distribuida entre C# y SQL.

La base de datos actúa como única fuente de verdad para la operación crítica.

---

## Verificación del comportamiento

El comportamiento fue validado mediante una prueba de concurrencia automatizada.

```csharp
var task1 = client.PostAsJsonAsync("/api/bookings", request);
var task2 = client.PostAsJsonAsync("/api/bookings", request);

var responses = await Task.WhenAll(task1, task2);

Assert.Equal(
    1,
    statusCodes.Count(s => s == HttpStatusCode.Created));

Assert.Equal(
    1,
    statusCodes.Count(s => s == HttpStatusCode.Conflict));
```

### ¿Por qué esta prueba es válida?

`Task.WhenAll` permite lanzar ambas solicitudes antes de esperar la finalización de cualquiera de ellas.

Esto maximiza la simultaneidad y reproduce un escenario real de competencia por el mismo recurso.

El resultado observado es siempre:

| Resultado    | Cantidad |
| ------------ | -------- |
| 201 Created  | 1        |
| 409 Conflict | 1        |

Nunca se obtienen dos reservas confirmadas.

---

## Comportamiento ante concurrencia alta

El lock es a nivel de fila (`ROWLOCK`), por lo que la contención se limita únicamente al espacio involucrado — un pico de demanda sobre la Sala A no afecta las reservas de la Sala B. La duración del bloqueo es mínima porque la transacción solo adquiere el lock, verifica el solapamiento, inserta y hace commit — sin operaciones pesadas en la sección crítica.

Se eligió Pessimistic Locking porque garantiza consistencia fuerte, comportamiento determinista e integración natural con SQL Server. Dado que la prioridad del sistema es la integridad de las reservas por encima del paralelismo máximo sobre un mismo espacio, esta estrategia representa el mejor equilibrio entre simplicidad, rendimiento y seguridad — demostrable mediante el test de concurrencia automatizado.

# Orden de aplicación de las reglas de tarifas

## Principio de aplicación

Las reglas tarifarias se aplican de forma **secuencial y acumulativa**. Cada ajuste se calcula sobre el subtotal resultante del paso anterior y no sobre el precio base original.

Esto implica que el orden de ejecución es relevante, ya que aplicar una regla antes o después puede producir resultados distintos. Por ejemplo, aplicar un descuento antes de un recargo genera un resultado diferente a aplicar el recargo primero y el descuento después.

---

## Orden de aplicación

| Paso | Regla         | Condición                                   | Ajuste                     |
| ---- | ------------- | ------------------------------------------- | -------------------------- |
| 1    | Precio base   | Siempre                                     | Tarifa por hora × duración |
| 2    | Hora pico     | Inicio entre 09:00–11:00 o 17:00–19:00      | +25% sobre subtotal        |
| 3    | Fin de semana | Sábado o domingo                            | +15% sobre subtotal        |
| 4    | Reserva larga | Duración ≥ 4 horas                          | -10% sobre subtotal        |
| 5    | Anticipación  | Reserva creada con ≥ 7 días de anticipación | -5% sobre subtotal         |

---

## Decisiones de diseño

### ¿Por qué los recargos se aplican antes que los descuentos?

Los recargos (hora pico y fin de semana) se aplican antes que los descuentos (reserva larga y anticipación) porque beneficia al usuario — los descuentos se calculan sobre un subtotal ya incrementado, generando un ahorro absoluto mayor que si se aplicaran sobre el precio base. El orden también es intuitivo: primero se determina el costo real del servicio, luego se aplican los incrementos y finalmente los beneficios.

---

### ¿Por qué la hora pico evalúa únicamente la hora de inicio?

La regla de hora pico considera únicamente la hora de inicio de la reserva.

Por ejemplo:

| Inicio | Fin   | ¿Aplica hora pico? |
| ------ | ----- | ------------------ |
| 09:00  | 12:00 | Sí                 |
| 10:00  | 12:00 | Sí                 |
| 11:00  | 13:00 | No                 |
| 17:00  | 18:00 | Sí                 |
| 19:00  | 20:00 | No                 |

Este comportamiento simplifica la implementación y evita tener que dividir una misma reserva en múltiples bloques tarifarios. La regla queda claramente definida y es consistente para todos los usuarios.

---

### ¿Por qué los porcentajes están definidos como constantes?

Los porcentajes utilizados por el motor de tarifas son:

| Regla         | Valor |
| ------------- | ----- |
| Hora pico     | 25%   |
| Fin de semana | 15%   |
| Reserva larga | 10%   |
| Anticipación  | 5%    |

Estos valores se encuentran definidos como constantes dentro de `PricingEngine`. Para el alcance de esta solución los porcentajes son fijos y están definidos por los requisitos del ejercicio.

En un entorno productivo podrían externalizarse a:

* Tablas de configuración.
* Variables de entorno.
* Servicios de configuración centralizados.

---

## Implementación en PricingEngine

```csharp
private const decimal PeakHourRate     = 0.25m;
private const decimal WeekendRate      = 0.15m;
private const decimal LongBookingRate  = 0.10m;
private const decimal EarlyBookingRate = 0.05m;

public PricingResult Calculate(
    decimal hourlyRate,
    DateTime startTime,
    DateTime endTime,
    DateTime createdAt)
{
    var result = new PricingResult();
    var durationHours = (decimal)(endTime - startTime).TotalHours;

    // Paso 1 — Precio base
    result.BasePrice = hourlyRate * durationHours;
    var subtotal = result.BasePrice;

    // Paso 2 — Hora pico
    var hour = startTime.Hour;
    var isPeakHour = (hour >= 9 && hour < 11) || (hour >= 17 && hour < 19);

    if (isPeakHour)
    {
        result.PeakHourAdjustment = subtotal * PeakHourRate;
        subtotal += result.PeakHourAdjustment;
    }

    // Paso 3 — Fin de semana
    var isWeekend = startTime.DayOfWeek == DayOfWeek.Saturday
                 || startTime.DayOfWeek == DayOfWeek.Sunday;

    if (isWeekend)
    {
        result.WeekendAdjustment = subtotal * WeekendRate;
        subtotal += result.WeekendAdjustment;
    }

    // Paso 4 — Reserva larga
    if (durationHours >= 4)
    {
        result.LongBookingDiscount = subtotal * LongBookingRate;
        subtotal -= result.LongBookingDiscount;
    }

    // Paso 5 — Anticipación
    var daysInAdvance = (startTime.Date - createdAt.Date).TotalDays;

    if (daysInAdvance >= 7)
    {
        result.EarlyBookingDiscount = subtotal * EarlyBookingRate;
        subtotal -= result.EarlyBookingDiscount;
    }

    result.FinalPrice = Math.Round(subtotal, 2);

    return result;
}
```

---

## Ejemplo completo de cálculo

### Escenario

* Tarifa por hora: S/ 100
* Duración: 4 horas
* Día: sábado
* Horario: 09:00 a 13:00
* Reserva creada: 10 días antes

### Paso 1 — Precio base

```text
S/ 100 × 4 horas = S/ 400.00
Subtotal       = S/ 400.00
```

### Paso 2 — Hora pico

La reserva inicia a las 09:00.

```text
S/ 400.00 × 25% = S/ 100.00
Subtotal       = S/ 500.00
```

### Paso 3 — Fin de semana

La reserva ocurre un sábado.

```text
S/ 500.00 × 15% = S/ 75.00
Subtotal       = S/ 575.00
```

### Paso 4 — Reserva larga

La duración es de exactamente 4 horas.

```text
S/ 575.00 × 10% = S/ 57.50
Subtotal       = S/ 517.50
```

### Paso 5 — Anticipación

La reserva fue creada 10 días antes.

```text
S/ 517.50 × 5% = S/ 25.88
Subtotal      = S/ 491.62
```

### Resultado final

```text
Precio final = S/ 491.62
```

---

## Consistencia entre backend y frontend

El frontend implementa la misma lógica para mostrar un desglose de precio en tiempo real antes de confirmar la reserva.

Sin embargo, la fuente de verdad siempre es el backend. El precio que finalmente se almacena en la base de datos es exclusivamente el calculado por:

```text
PricingEngine (Backend)
```

El cálculo realizado en el frontend tiene un propósito únicamente informativo y de experiencia de usuario.

---

## Casos límite documentados

### Hora pico

El límite superior es exclusivo.

```csharp
hour >= 9 && hour < 11
```

Por lo tanto:

| Hora inicio | ¿Aplica? |
| ----------- | -------- |
| 09:00       | Sí       |
| 10:59       | Sí       |
| 11:00       | No       |
| 17:00       | Sí       |
| 18:59       | Sí       |
| 19:00       | No       |

---

### Reserva larga

El límite es inclusivo.

```csharp
durationHours >= 4
```

| Duración   | ¿Aplica descuento? |
| ---------- | ------------------ |
| 3.99 horas | No                 |
| 4 horas    | Sí                 |
| 5 horas    | Sí                 |

---

### Anticipación

El límite también es inclusivo.

```csharp
daysInAdvance >= 7
```

| Días de anticipación | ¿Aplica descuento? |
| -------------------- | ------------------ |
| 6 días               | No                 |
| 7 días               | Sí                 |
| 8 días               | Sí                 |

El cálculo utiliza únicamente la fecha:

```csharp
startTime.Date - createdAt.Date
```

Esto evita que diferencias de horas o minutos afecten la aplicación de la regla.

---

## Conclusión

La aplicación secuencial de reglas permite que el cálculo de precios sea determinista, fácil de entender y sencillo de probar mediante tests unitarios.

El orden elegido prioriza una lógica comercial clara:

- Calcular el precio base.
- Aplicar recargos.
- Aplicar descuentos.
- Obtener el precio final.

De esta manera el motor de tarifas produce resultados consistentes tanto para la persistencia de reservas como para la visualización previa en el frontend.
# Cómo ejecutar los tests

La solución incluye pruebas unitarias para las reglas de negocio y una prueba de concurrencia para validar el comportamiento del sistema ante solicitudes simultáneas sobre un mismo espacio.

---

## Requisitos previos

### Para todos los tests

* .NET 10 SDK instalado.

### Adicional para el test de concurrencia

* SQL Server corriendo localmente.
* Base de datos creada.
* Scripts ejecutados.
* Datos seed cargados.

---

## Ejecutar todos los tests

```bash
cd backend

dotnet test CoWork.Tests/CoWork.Tests.csproj --verbosity normal
```

### Resultado esperado

```text
Passed! - Failed: 0, Passed: 19, Skipped: 0
```

---

## Detalle por categoría

| Categoría          | Archivo                    | Tests  | Descripción                                                                                                      |
| ------------------ | -------------------------- | ------ | ---------------------------------------------------------------------------------------------------------------- |
| PricingEngine      | PricingEngineTests.cs      | 10     | Precio base, hora pico mañana/tarde, fin de semana, reserva larga, anticipación, combinaciones y casos negativos |
| CancellationPolicy | CancellationPolicyTests.cs | 8      | Tramos >48h, exactamente 48h, entre 24h-48h, exactamente 24h, <24h, <1h, monto correcto y descripción por tramo  |
| Concurrencia       | ConcurrencyTests.cs        | 1      | Dos peticiones simultáneas al mismo espacio y horario                                                            |
| **Total**          |                            | **19** | **19/19 Passed**                                                                                                 |

---

## Ejecutar solo tests unitarios (sin base de datos)

Los tests de `PricingEngine` y `CancellationPolicy` no tienen dependencias externas.

No requieren:

* SQL Server.
* Docker.
* Servicios externos.
* Infraestructura adicional.

```bash
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName!~ConcurrencyTests" \
  --verbosity normal
```

### Resultado esperado

```text
Passed! - Failed: 0, Passed: 18, Skipped: 0
```

---

## Ejecutar solo el test de concurrencia

La prueba de concurrencia requiere SQL Server corriendo localmente con el seed ejecutado.

Internamente utiliza:

* `WebApplicationFactory`
* API ASP.NET Core en memoria
* SQL Server real
* `Task.WhenAll` para maximizar la simultaneidad

```bash
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName~ConcurrencyTests" \
  --verbosity normal
```

### Resultado esperado

```text
Passed! - Failed: 0, Passed: 1, Skipped: 0
```

### Log esperado durante la ejecución

Durante la prueba puede aparecer el siguiente mensaje en consola:

```text
fail: CoWork.API.Middlewares.ExceptionMiddleware
      Domain exception: El espacio se encuentra reservado para el horario seleccionado.
```

Este comportamiento es esperado y no representa un error en la prueba.

Simplemente indica que una de las dos solicitudes concurrentes recibió correctamente el:

```text
409 Conflict
```

como consecuencia del mecanismo de control de concurrencia implementado.

---

## ¿Qué demuestra el test de concurrencia?

La prueba envía dos solicitudes simultáneas para reservar exactamente el mismo espacio y horario.

```csharp
// Dos peticiones al mismo espacio y horario
var task1 = client.PostAsJsonAsync("/api/bookings", request);
var task2 = client.PostAsJsonAsync("/api/bookings", request);

var responses = await Task.WhenAll(task1, task2);

// Verificaciones
Assert.Contains(HttpStatusCode.Created,  statusCodes);
Assert.Contains(HttpStatusCode.Conflict, statusCodes);

Assert.Equal(
    1,
    statusCodes.Count(s => s == HttpStatusCode.Created));

Assert.Equal(
    1,
    statusCodes.Count(s => s == HttpStatusCode.Conflict));
```

### Resultado esperado

| Código HTTP  | Cantidad |
| ------------ | -------- |
| 201 Created  | 1        |
| 409 Conflict | 1        |

La prueba garantiza que:

* Una solicitud confirma la reserva.
* La otra solicitud es rechazada.
* Nunca se crean dos reservas solapadas.

### ¿Por qué se usa Task.WhenAll?

`Task.WhenAll` inicia ambas tareas antes de esperar la finalización de cualquiera de ellas.

Esto maximiza la simultaneidad y reproduce un escenario real donde dos usuarios intentan reservar el mismo espacio al mismo tiempo.

El mecanismo de **Pessimistic Locking** implementado en `sp_CreateBooking` garantiza que únicamente una transacción pueda completar la operación exitosamente.

---

## Ejecutar tests por categoría específica

### PricingEngine

```bash
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName~PricingEngineTests" \
  --verbosity normal
```

### CancellationPolicy

```bash
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName~CancellationPolicyTests" \
  --verbosity normal
```

### Concurrencia

```bash
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName~ConcurrencyTests" \
  --verbosity normal
```

---

## Pipeline de CI/CD

El pipeline de GitHub Actions ejecuta automáticamente los **18 tests unitarios** en cada push hacia las ramas principales.

La prueba de concurrencia se excluye del pipeline porque requiere una instancia de SQL Server para ejecutarse correctamente.

```yaml
dotnet test CoWork.Tests/CoWork.Tests.csproj \
  --filter "FullyQualifiedName!~ConcurrencyTests" \
  --configuration Release \
  --verbosity normal
```

### ¿Qué valida el pipeline?

* Restauración de dependencias.
* Compilación del backend.
* Ejecución de tests unitarios.
* Detección temprana de regresiones.

El estado actual del pipeline puede verificarse mediante el badge mostrado al inicio de este README.

Un badge en estado exitoso confirma que todas las pruebas unitarias están pasando correctamente.

## Colección de endpoints (14)

| Método | Endpoint | Auth | Descripción |
|---|---|---|---|
| POST | /api/auth/login | No | Obtener token JWT |
| GET | /api/spaces | No | Listar espacios |
| GET | /api/spaces/{id} | No | Detalle de espacio |
| POST | /api/spaces | Sí | Crear espacio |
| PUT | /api/spaces/{id} | Sí | Editar espacio |
| DELETE | /api/spaces/{id} | Sí | Desactivar espacio |
| GET | /api/bookings | No | Listar reservas |
| GET | /api/bookings/{id} | No | Detalle de reserva |
| POST | /api/bookings | Sí | Crear reserva |
| GET | /api/bookings/price-preview | No | Preview de precio en tiempo real |
| PATCH | /api/bookings/{id}/cancel | Sí | Cancelar reserva |
| PATCH | /api/bookings/{id}/status | Sí | Cambiar estado de reserva |
| GET | /api/reports | Si | Reporte de ocupación e ingresos |
| GET | /api/users| No |Listar Usuarios del Sistema |

La documentación completa con ejemplos de request/response está disponible en Swagger: http://localhost:5209
