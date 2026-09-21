#!/bin/bash
set -e

echo "Aplicando esquemas y datos iniciales..."

aplicar_sql() {
  local db="$1"
  local usuario="$2"
  local archivo="$3"

  echo "Aplicando $archivo en $db..."

  psql \
    -v ON_ERROR_STOP=1 \
    --username "$usuario" \
    --dbname "$db" \
    -f "$archivo"
}

# -------------------------
# Esquemas
# -------------------------

aplicar_sql "$CATALOGO_DB" \
            "$CATALOGO_DB_USER" \
            "/opt/elquetzal/schemas/catalogo.sql"

aplicar_sql "$INVENTARIO_DB" \
            "$INVENTARIO_DB_USER" \
            "/opt/elquetzal/schemas/inventario.sql"

aplicar_sql "$CLIENTES_DB" \
            "$CLIENTES_DB_USER" \
            "/opt/elquetzal/schemas/clientes.sql"

aplicar_sql "$PEDIDOS_DB" \
            "$PEDIDOS_DB_USER" \
            "/opt/elquetzal/schemas/pedidos.sql"

aplicar_sql "$REPORTES_DB" \
            "$REPORTES_DB_USER" \
            "/opt/elquetzal/schemas/reportes.sql"

# -------------------------
# Seeds
# -------------------------

aplicar_sql "$CATALOGO_DB" \
            "$CATALOGO_DB_USER" \
            "/opt/elquetzal/seeds/catalogo.sql"

aplicar_sql "$INVENTARIO_DB" \
            "$INVENTARIO_DB_USER" \
            "/opt/elquetzal/seeds/inventario.sql"

aplicar_sql "$CLIENTES_DB" \
            "$CLIENTES_DB_USER" \
            "/opt/elquetzal/seeds/clientes.sql"

echo "Esquemas y seeds aplicados correctamente."