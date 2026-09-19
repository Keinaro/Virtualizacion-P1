#!/bin/bash
# ============================================================
# Área 4 — Crea una base y un usuario por microservicio.
# Se ejecuta automáticamente al inicializar el volumen de Postgres
# (docker-entrypoint-initdb.d). Idempotente: se puede repetir.
# ============================================================
set -e

crear_base() {
  local db="$1" usuario="$2" clave="$3"

  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    DO \$\$
    BEGIN
      IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${usuario}') THEN
        CREATE ROLE ${usuario} LOGIN PASSWORD '${clave}';
      END IF;
    END
    \$\$;
EOSQL

  # CREATE DATABASE no corre dentro de un bloque DO; se consulta antes.
  if ! psql --username "$POSTGRES_USER" --dbname postgres -tAc \
       "SELECT 1 FROM pg_database WHERE datname = '${db}'" | grep -q 1; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
      -c "CREATE DATABASE ${db} OWNER ${usuario};"
  fi

  # Menor privilegio: cada usuario solo sobre su propia base.
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
    -c "GRANT ALL PRIVILEGES ON DATABASE ${db} TO ${usuario};"
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "${db}" \
    -c "GRANT ALL ON SCHEMA public TO ${usuario};"
}

crear_base "$CATALOGO_DB"   "$CATALOGO_DB_USER"   "$CATALOGO_DB_PASSWORD"
crear_base "$INVENTARIO_DB" "$INVENTARIO_DB_USER" "$INVENTARIO_DB_PASSWORD"
crear_base "$CLIENTES_DB"   "$CLIENTES_DB_USER"   "$CLIENTES_DB_PASSWORD"
crear_base "$PEDIDOS_DB"    "$PEDIDOS_DB_USER"    "$PEDIDOS_DB_PASSWORD"
crear_base "$REPORTES_DB"   "$REPORTES_DB_USER"   "$REPORTES_DB_PASSWORD"

echo "Bases y usuarios por microservicio creados."
