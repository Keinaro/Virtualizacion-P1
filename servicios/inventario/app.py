"""Punto de entrada del microservicio 'inventario' — Área 5.

Capa de arranque: crea la app Flask y registra las rutas.
La lógica de negocio vive en app/servicio.py y el acceso a
datos en app/repositorio.py (separación de capas).
"""
import os

from flask import Flask

from app.rutas import bp


def crear_app() -> Flask:
    app = Flask(__name__)
    app.config["DATABASE_URL"] = os.environ["DATABASE_URL"]
    app.register_blueprint(bp)
    return app


app = crear_app()


if __name__ == "__main__":
    # Solo para desarrollo local; en contenedor corre gunicorn.
    app.run(host="0.0.0.0", port=5000, debug=True)
