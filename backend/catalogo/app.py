import os
from decimal import Decimal, InvalidOperation

from flask import Flask, jsonify, request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from database import SessionLocal, crear_tablas
from models import Categoria, Producto


def categoria_json(categoria: Categoria) -> dict:
    return {"id": categoria.id, "nombre": categoria.nombre, "descripcion": categoria.descripcion}


def producto_json(producto: Producto) -> dict:
    return {
        "id": producto.id,
        "sku": producto.sku,
        "nombre": producto.nombre,
        "categoria_id": producto.categoria_id,
        "categoria": producto.categoria.nombre if producto.categoria else None,
        "precio": float(producto.precio),
        "creado_en": producto.creado_en.isoformat() if producto.creado_en else None,
    }


def texto(data: dict, campo: str) -> str:
    valor = data.get(campo) if isinstance(data, dict) else None
    if not isinstance(valor, str) or not valor.strip():
        raise ValueError(f"{campo} debe ser texto no vacio")
    return valor.strip()


def precio(data: dict) -> Decimal:
    try:
        valor = Decimal(str(data.get("precio")))
    except (InvalidOperation, TypeError):
        raise ValueError("precio debe ser numerico") from None
    if valor < 0:
        raise ValueError("precio debe ser no negativo")
    return valor


def crear_app() -> Flask:
    app = Flask(__name__)
    crear_tablas()

    @app.get("/health")
    def health():
        return jsonify({"servicio": "catalogo", "estado": "ok"})

    @app.get("/categorias")
    def listar_categorias():
        with SessionLocal() as session:
            categorias = session.scalars(select(Categoria).order_by(Categoria.nombre)).all()
            return jsonify([categoria_json(categoria) for categoria in categorias])

    @app.post("/categorias")
    def crear_categoria():
        try:
            datos = request.get_json(silent=True)
            categoria = Categoria(nombre=texto(datos, "nombre"), descripcion=datos.get("descripcion"))
            with SessionLocal.begin() as session:
                session.add(categoria)
                session.flush()
                respuesta = categoria_json(categoria)
            return jsonify(respuesta), 201
        except (ValueError, AttributeError) as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "La categoria ya existe"}), 409

    @app.get("/productos")
    def listar_productos():
        with SessionLocal() as session:
            productos = session.scalars(select(Producto).order_by(Producto.id)).all()
            return jsonify([producto_json(producto) for producto in productos])

    @app.post("/productos")
    def crear_producto():
        try:
            datos = request.get_json(silent=True)
            producto = Producto(sku=texto(datos, "sku"), nombre=texto(datos, "nombre"), precio=precio(datos))
            producto.categoria_id = datos.get("categoria_id")
            with SessionLocal.begin() as session:
                if producto.categoria_id is not None and session.get(Categoria, producto.categoria_id) is None:
                    return jsonify({"error": "Categoria no encontrada"}), 404
                session.add(producto)
                session.flush()
                respuesta = producto_json(producto)
            return jsonify(respuesta), 201
        except (ValueError, AttributeError) as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "El SKU ya existe"}), 409

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
