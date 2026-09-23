# Arquitectura — Proyecto 1: El Quetzal

> Documento del Área 2 + Área 3. Resume cómo encajan las piezas; el detalle
> de cada área vive en su propio documento (ver [Referencias](#referencias)).

## Vista general

```
Navegador del host (Windows)
        │  http://127.0.0.1:8080
        ▼
  VirtualBox NAT — reenvío host 8080 → VM 80   (Área 1)
        │
┌───────┼─────────────────────────────────────────────────┐
│ VM Ubuntu Server (headless) — srv-elquetzal-maximus     │
│ Docker Engine + Compose                                 │
│       ▼                                                 │
│  ┌──────────────┐  ◄── único puerto publicado (80)      │
│  │   gateway    │      nginx + build estático de Vue    │
│  └──────┬───────┘                                       │
│         │ /api/<servicio>/     red: elquetzal_interna   │
│    ┌────┴─────┬──────────┬──────────┬──────────┐        │
│    ▼          ▼          ▼          ▼          ▼        │
│ catalogo  inventario  clientes   pedidos   reportes     │
│   :5000     :5000      :5000      :5000     :5000       │
│    │          │          │          │          │        │
│    └──────────┴──────────┴────┬─────┴──────────┘        │
│                               ▼                         │
│                  ┌─────────────────────────┐            │
│                  │ Postgres 16 — 5 bases,  │            │
│                  │ un usuario por servicio │            │
│                  └────────────┬────────────┘            │
│                               ▼                         │
│                  volumen: elquetzal_pgdata              │
└─────────────────────────────────────────────────────────┘
```

Llamadas internas entre servicios (HTTP por nombre de servicio, nunca por IP):

| Origen | Destino | Para qué |
|---|---|---|
| `pedidos` | `clientes` | validar que el carné exista |
| `pedidos` | `inventario` | reservar stock (y liberarlo si el pedido falla) |
| `reportes` | `inventario` | productos, precios y stock para el dashboard |
| `reportes` | `pedidos` | pedidos del día |

## Mapa de rutas del gateway

| Ruta pública | Servicio | Puerto interno |
|---|---|---|
| `/` | build estático de Vue | — |
| `/health` | gateway (respuesta fija) | — |
| `/api/catalogo/` | `catalogo` | 5000 |
| `/api/inventario/` | `inventario` | 5000 |
| `/api/clientes/` | `clientes` | 5000 |
| `/api/pedidos/` | `pedidos` | 5000 |
| `/api/reportes/` | `reportes` | 5000 |

nginx quita el prefijo: `/api/pedidos/pedidos` llega a `pedidos` como
`/pedidos`.

## Flujo de un pedido (regla crítica)

```
Vue ──POST /api/pedidos/pedidos──► gateway ──► pedidos
                                                 │ 1. GET clientes/clientes/<carné>   → 404 si no existe
                                                 │ 2. POST inventario/reservas        → 409 si no hay stock
                                                 │    (SELECT … FOR UPDATE en orden de SKU,       404 si el SKU no existe
                                                 │     valida todas las líneas y luego descuenta)
                                                 │ 3. guarda el pedido en pedidos_db
                                                 │    si falla → POST inventario/reservas/liberar
                                                 ▼
                                            201 confirmado
```

Si no hay stock suficiente para **alguna** línea, no se descuenta ninguna:
el stock queda intacto.

## Orden de arranque

```
db (healthy) → catalogo, inventario, clientes (healthy)
             → pedidos   (espera inventario + clientes)
             → reportes  (espera inventario + pedidos)
             → gateway   (espera los 5)
```

Cada servicio declara un `healthcheck`; `depends_on` con
`condition: service_healthy` evita que el gateway reciba tráfico antes de que
el backend responda. Detalle en [`orquestacion.md`](orquestacion.md).

## Imágenes publicadas

Namespace del grupo: **https://hub.docker.com/u/keinaro**

| Imagen | Base |
|---|---|
| `keinaro/catalogo:1.0` | `python:3.12-slim` + gunicorn |
| `keinaro/inventario:1.0` | `python:3.12-slim` + gunicorn |
| `keinaro/clientes:1.0` | `python:3.12-slim` + gunicorn |
| `keinaro/pedidos:1.0` | `python:3.12-slim` + gunicorn |
| `keinaro/reportes:1.0` | `python:3.12-slim` + gunicorn |
| `keinaro/gateway:1.0` | `nginx:1.27-alpine` (build multi-etapa con `node:20-alpine`) |

`postgres:16-alpine` es imagen oficial y no se publica.

## Decisiones

- **Un solo puerto expuesto.** Solo el gateway publica hacia el host; los
  microservicios y Postgres viven únicamente en la red interna.
- **Descubrimiento por nombre.** nginx y los servicios se resuelven por el
  nombre declarado en `docker-compose.yml`; cero IPs hardcodeadas.
- **Una base por microservicio** en el mismo motor Postgres, cada una con su
  propio usuario: aislamiento lógico y menor privilegio sin el costo de 5
  motores.
- **Persistencia por volumen nombrado** (`elquetzal_pgdata`), verificada con
  `docker compose down && docker compose up`.
- **Cero secretos en el código.** Credenciales vía `.env` (fuera de git);
  solo `.env.example` se versiona.
- **Frontend sin runtime propio.** Vue se compila en el build del gateway y
  nginx lo sirve como estático; Node no llega a la imagen final.

## Referencias

| Tema | Documento | Área |
|---|---|---|
| Dimensionamiento de la VM | [`00-sizing.md`](00-sizing.md) | 1 |
| Red host↔VM (NAT + reenvío, Host-Only) | [`03-red-host-vm.md`](03-red-host-vm.md) | 1 |
| Gateway nginx | [`../gateway/README.md`](../gateway/README.md) | 2 |
| Compose, variables, Docker Hub, persistencia | [`orquestacion.md`](orquestacion.md) | 3 |
| Modelo de datos y diagrama ER | [`modelo-datos.md`](modelo-datos.md) | 4 |
| Endpoints de los microservicios | [`../backend/README.md`](../backend/README.md) | 5 |
| Anexo de costos CAPEX vs OPEX | [`costos.md`](costos.md) | 6 |

## Pendiente

- [ ] Capturas con reloj del sistema visible: `docker compose ps` en la VM,
  app abierta desde el host, namespace de Docker Hub.
