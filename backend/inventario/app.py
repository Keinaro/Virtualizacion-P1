import os
from decimal import Decimal, InvalidOperation

from flask import Flask, jsonify, request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from database import SessionLocal, crear_tablas
from models import Existencia


def producto_json(producto: Existencia) -> dict:
    return {
        "id": producto.id,
        "sku": producto.sku,
        "nombre": producto.nombre,
        "categoria": producto.categoria,
        "precio": float(producto.precio),
        "stock": producto.stock,
        "stock_minimo": producto.stock_minimo,
        "actualizado_en": producto.actualizado_en.isoformat() if producto.actualizado_en else None,
    }


def validar_producto(data: dict, parcial: bool = False) -> dict:
    campos = ("sku", "nombre", "categoria", "precio", "stock", "stock_minimo")
    if not isinstance(data, dict):
        raise ValueError("El cuerpo debe ser un objeto JSON")
    if not parcial and any(campo not in data for campo in ("sku", "nombre", "precio", "stock")):
        raise ValueError("sku, nombre, precio y stock son obligatorios")

    resultado = {}
    for campo in campos:
        if campo in data:
            resultado[campo] = data[campo]
    for campo in ("sku", "nombre"):
        if campo in resultado and (not isinstance(resultado[campo], str) or not resultado[campo].strip()):
            raise ValueError(f"{campo} debe ser texto no vacio")
    for campo in ("stock", "stock_minimo"):
        if campo in resultado and (not isinstance(resultado[campo], int) or isinstance(resultado[campo], bool) or resultado[campo] < 0):
            raise ValueError(f"{campo} debe ser un entero no negativo")
    if "precio" in resultado:
        try:
            resultado["precio"] = Decimal(str(resultado["precio"]))
        except (InvalidOperation, TypeError):
            raise ValueError("precio debe ser numerico") from None
        if resultado["precio"] < 0:
            raise ValueError("precio debe ser no negativo")
    return resultado


def crear_app() -> Flask:
    app = Flask(__name__)
    crear_tablas()

    @app.get("/health")
    def health():
        return jsonify({"servicio": "inventario", "estado": "ok"})

    @app.get("/productos")
    def listar_productos():
        with SessionLocal() as session:
            productos = session.scalars(select(Existencia).order_by(Existencia.id)).all()
            return jsonify([producto_json(producto) for producto in productos])

    @app.post("/productos")
    def crear_producto():
        try:
            datos = validar_producto(request.get_json(silent=True))
            producto = Existencia(**datos)
            with SessionLocal.begin() as session:
                session.add(producto)
                session.flush()
                respuesta = producto_json(producto)
            return jsonify(respuesta), 201
        except ValueError as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "El SKU ya existe"}), 409

    @app.route("/productos/<string:sku>", methods=["PUT", "PATCH"])
    def actualizar_producto(sku: str):
        try:
            datos = validar_producto(request.get_json(silent=True), parcial=True)
            with SessionLocal.begin() as session:
                producto = session.scalar(select(Existencia).where(Existencia.sku == sku))
                if producto is None:
                    return jsonify({"error": "Producto no encontrado"}), 404
                for campo, valor in datos.items():
                    setattr(producto, campo, valor)
                session.flush()
                respuesta = producto_json(producto)
            return jsonify(respuesta)
        except ValueError as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "El SKU ya existe"}), 409

    @app.delete("/productos/<string:sku>")
    def eliminar_producto(sku: str):
        with SessionLocal.begin() as session:
            producto = session.scalar(select(Existencia).where(Existencia.sku == sku))
            if producto is None:
                return jsonify({"error": "Producto no encontrado"}), 404
            session.delete(producto)
        return "", 204

    @app.post("/reservas")
    def reservar_stock():
        datos = request.get_json(silent=True)
        lineas = datos.get("lineas") if isinstance(datos, dict) else None
        if not isinstance(lineas, list) or not lineas:
            return jsonify({"error": "lineas debe ser una lista no vacia"}), 400
        acumuladas = {}
        try:
            for linea in lineas:
                sku, cantidad = linea.get("sku"), linea.get("cantidad")
                if not isinstance(sku, str) or not sku or not isinstance(cantidad, int) or isinstance(cantidad, bool) or cantidad <= 0:
                    raise ValueError("Cada linea requiere sku y cantidad positiva")
                acumuladas[sku] = acumuladas.get(sku, 0) + cantidad
            with SessionLocal.begin() as session:
                productos = {}
                for sku in sorted(acumuladas):
                    producto = session.scalar(select(Existencia).where(Existencia.sku == sku).with_for_update())
                    if producto is None:
                        return jsonify({"error": f"Producto no encontrado: {sku}"}), 404
                    if producto.stock < acumuladas[sku]:
                        return jsonify({"error": f"Stock insuficiente para {sku}", "sku": sku}), 409
                    productos[sku] = producto
                resultado = []
                for sku, cantidad in acumuladas.items():
                    producto = productos[sku]
                    producto.stock -= cantidad
                    resultado.append({"sku": sku, "cantidad": cantidad, "precio_unitario": float(producto.precio)})
            return jsonify({"lineas": resultado}), 200
        except ValueError as error:
            return jsonify({"error": str(error)}), 400

    @app.post("/reservas/liberar")
    def liberar_stock():
        datos = request.get_json(silent=True)
        lineas = datos.get("lineas") if isinstance(datos, dict) else None
        if not isinstance(lineas, list) or not lineas:
            return jsonify({"error": "lineas debe ser una lista no vacia"}), 400
        try:
            acumuladas = {}
            for linea in lineas:
                sku, cantidad = linea.get("sku"), linea.get("cantidad")
                if not isinstance(sku, str) or not sku or not isinstance(cantidad, int) or isinstance(cantidad, bool) or cantidad <= 0:
                    raise ValueError("Cada linea requiere sku y cantidad positiva")
                acumuladas[sku] = acumuladas.get(sku, 0) + cantidad
            with SessionLocal.begin() as session:
                for sku, cantidad in acumuladas.items():
                    producto = session.scalar(select(Existencia).where(Existencia.sku == sku).with_for_update())
                    if producto is None:
                        return jsonify({"error": f"Producto no encontrado: {sku}"}), 404
                    producto.stock += cantidad
            return jsonify({"liberadas": lineas}), 200
        except ValueError as error:
            return jsonify({"error": str(error)}), 400

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
