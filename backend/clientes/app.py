import os

from flask import Flask, jsonify, request
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from database import SessionLocal, crear_tablas
from models import Cliente


def cliente_json(cliente: Cliente) -> dict:
    return {
        "id": cliente.id,
        "carne": cliente.carne,
        "nombre": cliente.nombre,
        "correo": cliente.correo,
        "creado_en": cliente.creado_en.isoformat() if cliente.creado_en else None,
    }


def validar_cliente(data: dict, parcial: bool = False) -> dict:
    if not isinstance(data, dict):
        raise ValueError("El cuerpo debe ser un objeto JSON")
    campos = ("carne", "nombre", "correo")
    if not parcial and any(campo not in data for campo in ("carne", "nombre")):
        raise ValueError("carne y nombre son obligatorios")
    resultado = {campo: data[campo] for campo in campos if campo in data}
    for campo in ("carne", "nombre"):
        if campo in resultado and (not isinstance(resultado[campo], str) or not resultado[campo].strip()):
            raise ValueError(f"{campo} debe ser texto no vacio")
        if campo in resultado:
            resultado[campo] = resultado[campo].strip()
    if "correo" in resultado and resultado["correo"] is not None and not isinstance(resultado["correo"], str):
        raise ValueError("correo debe ser texto o null")
    return resultado


def crear_app() -> Flask:
    app = Flask(__name__)
    crear_tablas()

    @app.get("/health")
    def health():
        return jsonify({"servicio": "clientes", "estado": "ok"})

    @app.get("/clientes")
    def listar_clientes():
        with SessionLocal() as session:
            clientes = session.scalars(select(Cliente).order_by(Cliente.id)).all()
            return jsonify([cliente_json(cliente) for cliente in clientes])

    @app.get("/clientes/<string:carne>")
    def obtener_cliente(carne: str):
        with SessionLocal() as session:
            cliente = session.scalar(select(Cliente).where(Cliente.carne == carne))
            if cliente is None:
                return jsonify({"error": "Cliente no encontrado"}), 404
            return jsonify(cliente_json(cliente))

    @app.post("/clientes")
    def crear_cliente():
        try:
            cliente = Cliente(**validar_cliente(request.get_json(silent=True)))
            with SessionLocal.begin() as session:
                session.add(cliente)
                session.flush()
                respuesta = cliente_json(cliente)
            return jsonify(respuesta), 201
        except ValueError as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "El carne ya existe"}), 409

    @app.route("/clientes/<string:carne>", methods=["PUT", "PATCH"])
    def actualizar_cliente(carne: str):
        try:
            datos = validar_cliente(request.get_json(silent=True), parcial=True)
            with SessionLocal.begin() as session:
                cliente = session.scalar(select(Cliente).where(Cliente.carne == carne))
                if cliente is None:
                    return jsonify({"error": "Cliente no encontrado"}), 404
                for campo, valor in datos.items():
                    setattr(cliente, campo, valor.strip() if isinstance(valor, str) else valor)
                session.flush()
                respuesta = cliente_json(cliente)
            return jsonify(respuesta)
        except ValueError as error:
            return jsonify({"error": str(error)}), 400
        except IntegrityError:
            return jsonify({"error": "El carne ya existe"}), 409

    @app.delete("/clientes/<string:carne>")
    def eliminar_cliente(carne: str):
        with SessionLocal.begin() as session:
            cliente = session.scalar(select(Cliente).where(Cliente.carne == carne))
            if cliente is None:
                return jsonify({"error": "Cliente no encontrado"}), 404
            session.delete(cliente)
        return "", 204

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
