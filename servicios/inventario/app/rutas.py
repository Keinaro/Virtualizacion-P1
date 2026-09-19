"""Capa de rutas del microservicio 'inventario' — Área 5.

Solo traduce HTTP <-> dominio: valida la entrada, llama a la
capa de servicio y mapea el resultado a códigos HTTP.
Sin lógica de negocio ni SQL aquí.
"""
from flask import Blueprint, jsonify

bp = Blueprint("inventario", __name__)


@bp.get("/health")
def health():
    """Sonda usada por el gateway y por los healthchecks."""
    return jsonify({"servicio": "inventario", "estado": "ok"})


# TODO(Área 5): implementar los endpoints de 'inventario'.
