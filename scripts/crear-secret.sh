#!/usr/bin/env bash
# ============================================================
# Proyecto 2 — El Quetzal | Área 3 (Jorge)
# Crea (o actualiza) el Secret db-credentials en la VM a partir
# de un .env que NO está en el repositorio.
#
# Uso:  ./scripts/crear-secret.sh [ruta-al-.env]     (por defecto ./.env)
#
# Del .env solo toma las 12 claves de credenciales; los nombres de
# base y los hosts van al ConfigMap. Los valores nunca pasan por
# la línea de comandos ni quedan en disco: se arma un archivo
# temporal con permisos 600 y se borra al terminar.
# ============================================================
set -euo pipefail

NS=proyecto-2-maximus
ORIGEN="${1:-.env}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"

CLAVES=(
  POSTGRES_SUPERUSER POSTGRES_SUPERUSER_PASSWORD
  CATALOGO_DB_USER   CATALOGO_DB_PASSWORD
  INVENTARIO_DB_USER INVENTARIO_DB_PASSWORD
  CLIENTES_DB_USER   CLIENTES_DB_PASSWORD
  PEDIDOS_DB_USER    PEDIDOS_DB_PASSWORD
  REPORTES_DB_USER   REPORTES_DB_PASSWORD
)

if [[ ! -f "$ORIGEN" ]]; then
  echo "ERROR: no existe $ORIGEN. Copiar .env.example a .env y llenar las contraseñas." >&2
  exit 1
fi

# El namespace tiene que existir antes que el Secret.
if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "Namespace $NS no existe; aplicando k8s/00-namespace.yaml"
  kubectl apply -f "$RAIZ/k8s/00-namespace.yaml"
fi

umask 077
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

for clave in "${CLAVES[@]}"; do
  linea="$(grep -E "^${clave}=" "$ORIGEN" | tail -n 1 || true)"
  valor="${linea#*=}"
  valor="${valor%$'\r'}"                                   # .env editado en Windows
  [[ "$valor" =~ ^\"(.*)\"$ || "$valor" =~ ^\'(.*)\'$ ]] && valor="${BASH_REMATCH[1]}"
  if [[ -z "$linea" || -z "$valor" || "$valor" == "cambiar_esta_clave" ]]; then
    echo "ERROR: falta $clave en $ORIGEN (o sigue en cambiar_esta_clave)." >&2
    exit 1
  fi
  printf '%s=%s\n' "$clave" "$valor" >> "$TMP"
done

# create --dry-run | apply: idempotente, sirve para crear y para actualizar.
kubectl create secret generic db-credentials -n "$NS" \
  --from-env-file="$TMP" --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret db-credentials -n "$NS" equipo=maximus --overwrite >/dev/null

echo
kubectl get secret db-credentials -n "$NS"        # muestra DATA 12, nunca los valores
echo
echo "OJO: si Postgres ya se inicializó, cambiar aquí una contraseña NO la cambia"
echo "dentro de la base; los microservicios fallarían al autenticarse."
