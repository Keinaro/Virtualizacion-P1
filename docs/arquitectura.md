# Arquitectura — Proyecto 1: El Quetzal

> Documento del Área 2 + Área 3. Completar con diagramas y capturas
> (con el **reloj del sistema visible**).

## Vista general

```
Navegador del host
        │  http://<ip-vm>:8080
        ▼
┌───────────────────────────────────────────────┐
│ VM Ubuntu Server — srv-elquetzal-grupo-X      │
│                                               │
│  ┌──────────────┐   red docker: elquetzal_interna
│  │   gateway    │ ◄── único puerto publicado  │
│  │   (nginx)    │                             │
│  └──────┬───────┘                             │
│         │ /api/<servicio>/                    │
│    ┌────┴────┬─────────┬─────────┬─────────┐  │
│    ▼         ▼         ▼         ▼         ▼  │
│ catalogo inventario clientes pedidos reportes │
│    └─────────┴────┬────┴─────────┴─────────┘  │
│                   ▼                           │
│              ┌─────────┐                      │
│              │Postgres │ vol: elquetzal_pgdata│
│              └─────────┘                      │
└───────────────────────────────────────────────┘
```

## Mapa de rutas del gateway

| Ruta pública | Servicio | Puerto interno |
|---|---|---|
| `/` | build estático de Vue | — |
| `/api/catalogo/` | `catalogo` | 5000 |
| `/api/inventario/` | `inventario` | 5000 |
| `/api/clientes/` | `clientes` | 5000 |
| `/api/pedidos/` | `pedidos` | 5000 |
| `/api/reportes/` | `reportes` | 5000 |

## Decisiones

- **Un solo puerto expuesto.** Solo el gateway publica hacia el host; los
  microservicios y Postgres viven únicamente en la red interna.
- **Descubrimiento por nombre.** nginx y los servicios se resuelven por el
  nombre declarado en `docker-compose.yml`; cero IPs hardcodeadas.
- **Una base por microservicio** en el mismo motor Postgres: aislamiento
  lógico sin el costo de 5 motores.
- **Persistencia por volumen nombrado** (`elquetzal_pgdata`), verificada con
  `docker compose down && up`.

## Pendiente de documentar

- [ ] Dimensionamiento de la VM (CPU/RAM/disco) con justificación — Área 1
- [ ] Configuración de red host↔VM (bridge o host-only + reenvío) — Área 1
- [ ] URL del namespace de Docker Hub del grupo — Área 3
- [ ] Capturas con reloj del sistema visible
