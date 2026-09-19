# Gateway — Área 2

Puerta única del stack. Es el **único** contenedor que publica puerto hacia el host.

## Mapa de rutas

| Ruta pública | Servicio destino | Puerto interno |
|---|---|---|
| `/` | build estático de Vue | — |
| `/api/catalogo/` | `catalogo` | 5000 |
| `/api/inventario/` | `inventario` | 5000 |
| `/api/clientes/` | `clientes` | 5000 |
| `/api/pedidos/` | `pedidos` | 5000 |
| `/api/reportes/` | `reportes` | 5000 |
| `/health` | nginx (200 OK) | — |

## Pruebas desde dentro de la red

Aísla problemas de nginx vs problemas de red:

```bash
docker compose exec gateway curl -s http://inventario:5000/health
docker compose exec gateway curl -s http://localhost/api/inventario/productos
```
