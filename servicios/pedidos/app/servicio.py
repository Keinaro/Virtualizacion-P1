"""Capa de lógica de negocio de 'pedidos' — Área 5.

Aquí vive la regla de negocio crítica del proyecto:
confirmar un pedido descuenta el stock de forma ATÓMICA.

Reglas que debe cumplir la implementación:

1. Validar stock de TODOS los productos antes de descontar.
   Si alguno no alcanza, se rechaza el pedido completo (409).
2. El check de stock y el UPDATE van dentro de UNA MISMA
   transacción. Hacerlos como pasos separados abre una
   condición de carrera: dos pedidos simultáneos podrían
   pasar la validación y dejar el stock negativo.
   Bloquear las filas con SELECT ... FOR UPDATE.
3. Todo o nada: cualquier fallo hace ROLLBACK del pedido
   completo, sin descuentos parciales.
4. El pedido registra el carné del integrante que lo creó
   (evidencia personalizada obligatoria).

Códigos HTTP esperados desde la capa de rutas:
  400 -> entrada inválida (cantidad <= 0, payload malformado)
  404 -> producto o cliente inexistente
  409 -> stock insuficiente
  201 -> pedido creado y stock descontado
"""


class StockInsuficienteError(Exception):
    """Algún producto del pedido no tiene stock suficiente (-> 409)."""


class ProductoNoEncontradoError(Exception):
    """Un producto referenciado en el pedido no existe (-> 404)."""


def confirmar_pedido(conexion, carne, lineas):
    """Crea el pedido y descuenta el stock en una sola transacción.

    Args:
        conexion: conexión/sesión transaccional a Postgres.
        carne: carné del integrante que crea el pedido.
        lineas: iterable de (sku, cantidad) con cantidad > 0.

    Returns:
        El id del pedido creado.

    Raises:
        ValueError: alguna cantidad es <= 0.
        ProductoNoEncontradoError: un sku no existe.
        StockInsuficienteError: no alcanza el stock de algún sku.
    """
    # TODO(Área 5): implementar dentro de BEGIN/COMMIT, bloqueando
    # las filas de inventario con SELECT ... FOR UPDATE antes de
    # validar y descontar. ROLLBACK ante cualquier excepción.
    raise NotImplementedError
