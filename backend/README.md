# Área 5 - Backend

Los cinco microservicios usan Flask, SQLAlchemy y PostgreSQL independiente. Cada servicio requiere `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD` y `DB_NAME`. El puerto es `5000` por defecto y puede cambiarse con `PORT`.

## Contratos principales

- `GET /health`
- Inventario: `GET|POST /productos`, `PUT|PATCH|DELETE /productos/<sku>`
- Pedidos: `GET|POST /pedidos`
- Clientes: `GET|POST /clientes`, `GET|PUT|PATCH|DELETE /clientes/<carne>`
- Catalogo: `GET|POST /categorias` y `GET|POST /productos`
- Reportes: `GET /resumen`, `POST /reportes/resumen` y `GET /reportes`

## Prueba manual por gateway

Definir la URL del gateway antes de ejecutar:

```bash
BASE=http://localhost:8090/api
```

Consultar inventario:

```bash
curl "$BASE/inventario/productos"
```

Crear un pedido valido usando un carne sembrado:

```bash
curl -X POST "$BASE/pedidos/pedidos" \
  -H "Content-Type: application/json" \
  -d '{"carne":"0000000","lineas":[{"sku":"CAF-001","cantidad":2}]}'
```

La respuesta debe ser `201`, con `estado: "confirmado"`, el carne y el total. Consultar inventario nuevamente debe mostrar el stock reducido en 2.

Probar stock insuficiente:

```bash
curl -i -X POST "$BASE/pedidos/pedidos" \
  -H "Content-Type: application/json" \
  -d '{"carne":"0000000","lineas":[{"sku":"CAF-001","cantidad":999999}]}'
```

Debe responder `409` y el stock debe permanecer sin cambios. Un carne inexistente debe responder `404`:

```bash
curl -i -X POST "$BASE/pedidos/pedidos" \
  -H "Content-Type: application/json" \
  -d '{"carne":"no-existe","lineas":[{"sku":"CAF-001","cantidad":1}]}'
```

Consultar el dashboard:

```bash
curl "$BASE/reportes/resumen"
```

La respuesta contiene `total_productos`, `valor_inventario`, `pedidos_hoy` y `stock_bajo`. Los reportes generados quedan guardados y pueden consultarse con:

```bash
curl "$BASE/reportes/reportes"
```
