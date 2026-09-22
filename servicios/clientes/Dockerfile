# ============================================================
# Área 3 + 5 — Microservicio: clientes
# Base ligera, caché de capas, usuario no-root.
# ============================================================
FROM python:3.12-slim

WORKDIR /app

# requirements primero para aprovechar la caché de capas
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 'app.py' y el paquete 'app/' conviven: 'import app' resuelve al paquete,
# asi que gunicorn no encuentra el objeto Flask. Se renombra el punto de
# entrada a wsgi.py para que 'wsgi:app' sea inequivoco.
RUN mv app.py wsgi.py

# Usuario no-root (principio de menor privilegio)
RUN useradd --create-home --shell /bin/bash appuser     && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "wsgi:app"]
