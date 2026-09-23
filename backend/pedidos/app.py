import os
from decimal import Decimal, InvalidOperation

import requests
from flask import Flask, jsonify, request

from database import SessionLocal, crear_tablas
from models import Pedido, PedidoLinea


class ServicioExternoError(Exception):
    pass


def pedido_json(pedido: Pedido) -> dict:
    return {
        "id": pedido.id,
        "carne": pedido.carne,
        "estado": pedido.estado,
        "total": float(pedido.total),
        "creado_en": pedido.creado_en.isoformat() if pedido.creado_en else None,
        "lineas": [
            {
                "sku": linea.sku,
                "cantidad": linea.cantidad,
                "precio_unitario": float(linea.precio_unitario),
            }
            for linea in pedido.lineas
        ],
    }


def validar_lineas(data: dict) -> tuple[str, list[dict]]:
    if not isinstance(data, dict) or not isinstance(data.get("carne"), str) or not data["carne"].strip():
        raise ValueError("carne es obligatorio")
    lineas = data.get("lineas")
    if not isinstance(lineas, list) or not lineas:
        raise ValueError("lineas debe ser una lista no vacia")

    resultado = []
    for linea in lineas:
        if not isinstance(linea, dict) or not isinstance(linea.get("sku"), str) or not linea["sku"].strip():
            raise ValueError("Cada linea requiere un sku")
        cantidad = linea.get("cantidad")
        if not isinstance(cantidad, int) or isinstance(cantidad, bool) or cantidad <= 0:
            raise ValueError("Cada cantidad debe ser un entero positivo")
        resultado.append({"sku": linea["sku"].strip(), "cantidad": cantidad})
    return data["carne"].strip(), resultado


def reservar_stock(lineas: list[dict]) -> list[dict]:
    url = os.getenv("INVENTARIO_URL", "http://inventario:5000").rstrip("/") + "/reservas"
    try:
        response = requests.post(url, json={"lineas": lineas}, timeout=5)
    except requests.RequestException as error:
        raise ServicioExternoError("No fue posible contactar al servicio de inventario") from error
    if response.status_code != 200:
        try:
            detalle = response.json().get("error", "Reserva rechazada")
        except ValueError:
            detalle = "Reserva rechazada"
        error = ServicioExternoError(detalle)
        error.status_code = response.status_code
        raise error
    return response.json()["lineas"]


def liberar_stock(lineas: list[dict]) -> None:
    url = os.getenv("INVENTARIO_URL", "http://inventario:5000").rstrip("/") + "/reservas/liberar"
    try:
        requests.post(url, json={"lineas": lineas}, timeout=5).raise_for_status()
    except requests.RequestException:
        pass


def verificar_cliente(carne: str) -> None:
    url = os.getenv("CLIENTES_URL", "http://clientes:5000").rstrip("/") + f"/clientes/{carne}"
    try:
        response = requests.get(url, timeout=5)
    except requests.RequestException as error:
        raise ServicioExternoError("No fue posible contactar al servicio de clientes") from error
    if response.status_code == 404:
        error = ServicioExternoError("Cliente no encontrado")
        error.status_code = 404
        raise error
    if response.status_code != 200:
        error = ServicioExternoError("No fue posible validar el cliente")
        error.status_code = 503
        raise error


def crear_app() -> Flask:
    app = Flask(__name__)
    crear_tablas()

    @app.get("/health")
    def health():
        return jsonify({"servicio": "pedidos", "estado": "ok"})

    @app.get("/pedidos")
    def listar_pedidos():
        with SessionLocal() as session:
            pedidos = session.query(Pedido).order_by(Pedido.creado_en.desc(), Pedido.id.desc()).all()
            return jsonify([pedido_json(pedido) for pedido in pedidos])

    @app.post("/pedidos")
    def crear_pedido():
        try:
            carne, lineas = validar_lineas(request.get_json(silent=True))
            verificar_cliente(carne)
            reservadas = reservar_stock(lineas)
            try:
                total = sum(Decimal(str(linea["precio_unitario"])) * linea["cantidad"] for linea in reservadas)
                with SessionLocal.begin() as session:
                    pedido = Pedido(carne=carne, estado="confirmado", total=total)
                    pedido.lineas = [
                        PedidoLinea(
                            sku=linea["sku"],
                            cantidad=linea["cantidad"],
                            precio_unitario=Decimal(str(linea["precio_unitario"])),
                        )
                        for linea in reservadas
                    ]
                    session.add(pedido)
                    session.flush()
                    respuesta = pedido_json(pedido)
            except Exception:
                liberar_stock(reservadas)
                raise
            return jsonify(respuesta), 201
        except ValueError as error:
            return jsonify({"error": str(error)}), 400
        except InvalidOperation:
            return jsonify({"error": "El precio recibido por inventario no es valido"}), 502
        except ServicioExternoError as error:
            return jsonify({"error": str(error)}), getattr(error, "status_code", 503)

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
