# Modelo de datos — Área 4

Un motor Postgres, cinco bases con usuario propio. El esquema de referencia
está en [`db/schema.sql`](../db/schema.sql).

## Bases y responsables

| Base | Usuario | Tablas |
|---|---|---|
| `catalogo_db` | `catalogo_user` | `categorias`, `productos` |
| `inventario_db` | `inventario_user` | `existencias` |
| `clientes_db` | `clientes_user` | `clientes` (carnés del equipo) |
| `pedidos_db` | `pedidos_user` | `pedidos`, `pedido_lineas` |
| `reportes_db` | `reportes_user` | `reportes_generados` |

## Diagrama ER

> TODO(Área 4): agregar el diagrama ER (dbdiagram.io, draw.io o similar)
> y exportarlo a `docs/img/`.

## Regla crítica: descuento atómico de stock

El stock vive en `inventario_db.existencias`. Al confirmar un pedido:

1. `BEGIN`
2. `SELECT ... FOR UPDATE` sobre las filas de los SKU del pedido (bloqueo).
3. Validar que **todas** las cantidades alcanzan; si alguna falla → `ROLLBACK` y 409.
4. `UPDATE existencias SET stock = stock - :cantidad` por cada línea.
5. Insertar `pedidos` + `pedido_lineas` con el carné del integrante.
6. `COMMIT`

Hacer el check y el update fuera de una transacción permite que dos pedidos
simultáneos pasen ambos la validación y dejen el stock inconsistente.

## Evidencia obligatoria

Los carnés del equipo se siembran en `clientes_db` ([`db/seeds/clientes.sql`](../db/seeds/clientes.sql))
y deben verse en la UI y en los pedidos.
