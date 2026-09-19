# ============================================================
# Área 3 + 5 — Microservicio: inventario
# Base ligera, caché de capas, usuario no-root.
# ============================================================
FROM python:3.12-slim

WORKDIR /app

# requirements primero para aprovechar la caché de capas
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Usuario no-root (principio de menor privilegio)
RUN useradd --create-home --shell /bin/bash appuser     && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
