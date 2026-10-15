#!/usr/bin/env bash
# ============================================================
# Proyecto 2 — El Quetzal | Área 4 (Julio)
# Respaldo completo de PostgreSQL desplegado en Kubernetes.
# Genera un archivo SQL fuera del Pod.
# ============================================================

set -euo pipefail

NS="proyecto-2-maximus"
FECHA="$(date +%F_%H-%M-%S)"
ARCHIVO="backup_${FECHA}.sql"

echo "Generando respaldo de PostgreSQL..."

kubectl exec deployment/postgres -n "$NS" -- \
  sh -c 'pg_dumpall -U "$POSTGRES_USER"' > "$ARCHIVO"

echo "Respaldo creado correctamente:"
echo "$ARCHIVO"