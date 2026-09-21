import os
from datetime import datetime, timezone
from typing import Any

import requests
from flask import Flask, jsonify, request

from database import SessionLocal, crear_tablas
from models import ReporteGenerado


def obtener_json(url: str) -> Any:
    try:
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        return response.json()
    except (requests.RequestException, ValueError) as error:
        raise RuntimeError("No fue posible consultar un servicio requerido") from error


def calcular_resumen(productos: list[dict], pedidos: list[dict]) -> dict:
    hoy = datetime.now(timezone.utc).date()
    pedidos_hoy = 0
    for pedido in pedidos:
        creado_en = pedido.get("creado_en")
        if not creado_en:
            continue
        try:
            fecha = datetime.fromisoformat(creado_en.replace("Z", "+00:00")).date()
        except ValueError:
            continue
        if fecha == hoy:
            pedidos_hoy += 1

    valor = sum(float(producto.get("precio", 0)) * int(producto.get("stock", 0)) for producto in productos)
    stock_bajo = sum(1 for producto in productos if int(producto.get("stock", 0)) <= int(producto.get("stock_minimo", 0)))
    return {
        "total_productos": len(productos),
        "valor_inventario": round(valor, 2),
        "pedidos_hoy": pedidos_hoy,
        "stock_bajo": stock_bajo,
    }


def reporte_json(reporte: ReporteGenerado) -> dict:
    return {
        "id": reporte.id,
        "tipo": reporte.tipo,
        "parametros": reporte.parametros,
        "resultado": reporte.resultado,
        "generado_en": reporte.generado_en.isoformat() if reporte.generado_en else None,
    }


def crear_app() -> Flask:
    app = Flask(__name__)
    crear_tablas()

    @app.get("/health")
    def health():
        return jsonify({"servicio": "reportes", "estado": "ok"})

    @app.get("/resumen")
    def resumen():
        inventario_url = os.getenv("INVENTARIO_URL", "http://inventario:5000").rstrip("/")
        pedidos_url = os.getenv("PEDIDOS_URL", "http://pedidos:5000").rstrip("/")
        try:
            resultado = calcular_resumen(
                obtener_json(f"{inventario_url}/productos"),
                obtener_json(f"{pedidos_url}/pedidos"),
            )
        except RuntimeError as error:
            return jsonify({"error": str(error)}), 503

        with SessionLocal.begin() as session:
            reporte = ReporteGenerado(tipo="resumen", parametros={}, resultado=resultado)
            session.add(reporte)
            session.flush()
            respuesta = resultado | {"reporte_id": reporte.id}
        return jsonify(respuesta)

    @app.get("/reportes")
    def historial():
        with SessionLocal() as session:
            reportes = session.query(ReporteGenerado).order_by(ReporteGenerado.generado_en.desc()).all()
            return jsonify([reporte_json(reporte) for reporte in reportes])

    @app.post("/reportes/resumen")
    def generar_resumen():
        return resumen()

    return app


app = crear_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
