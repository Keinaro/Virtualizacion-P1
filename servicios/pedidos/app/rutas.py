"""Capa de rutas del microservicio 'pedidos' — Área 5.

Solo traduce HTTP <-> dominio: valida la entrada, llama a la
capa de servicio y mapea el resultado a códigos HTTP.
Sin lógica de negocio ni SQL aquí.
"""
from flask import Blueprint, jsonify

bp = Blueprint("pedidos", __name__)


@bp.get("/health")
def health():
    """Sonda usada por el gateway y por los healthchecks."""
    return jsonify({"servicio": "pedidos", "estado": "ok"})


# TODO(Área 5): implementar los endpoints de 'pedidos'.
