#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-proyecto-2-maximus}"
DEPLOYMENT="${DEPLOYMENT:-inventario}"
SELECTOR="app=${DEPLOYMENT}"

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: no se encontro el comando requerido: $1" >&2
    exit 1
  }
}

require_command kubectl

kubectl get namespace "$NS" >/dev/null 2>&1 || {
  echo "ERROR: no existe el namespace $NS" >&2
  exit 1
}

kubectl get deployment "$DEPLOYMENT" -n "$NS" >/dev/null 2>&1 || {
  echo "ERROR: no existe el Deployment $DEPLOYMENT en $NS" >&2
  exit 1
}

echo "=== Configuracion ==="
echo "Namespace: $NS"
echo "Deployment: $DEPLOYMENT"
echo

echo "=== Estado inicial ==="
kubectl get deployment "$DEPLOYMENT" -n "$NS"
kubectl get pods -l "$SELECTOR" -n "$NS" -o wide
kubectl get endpoints "$DEPLOYMENT" -n "$NS" 2>/dev/null || true

echo
echo "=== Escalado declarativo ==="
echo "El escalado debe hacerse editando k8s/21-inventario.yaml y aplicando el archivo:"
echo "  kubectl apply -f k8s/21-inventario.yaml"
echo
read -r -p "Presiona Enter cuando el YAML tenga replicas: 3 y haya sido aplicado..."
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NS" --timeout=180s
kubectl get deployment "$DEPLOYMENT" -n "$NS"
kubectl get pods -l "$SELECTOR" -n "$NS" -o wide
kubectl get endpoints "$DEPLOYMENT" -n "$NS" 2>/dev/null || true

echo
echo "=== Variables no sensibles recibidas por un Pod ==="
POD=$(kubectl get pods -l "$SELECTOR" -n "$NS" -o jsonpath='{.items[0].metadata.name}')
kubectl exec "$POD" -n "$NS" -- sh -c 'env | sort | grep -E "^(DB_HOST|DB_PORT|DB_NAME|DB_USER|PORT)="'
kubectl exec "$POD" -n "$NS" -- sh -c 'if [ -n "$DB_PASSWORD" ]; then echo DB_PASSWORD=SET; else echo DB_PASSWORD=MISSING; exit 1; fi'

echo
echo "=== Autoreparacion ==="
POD_A=$(kubectl get pods -l "$SELECTOR" -n "$NS" -o jsonpath='{.items[0].metadata.name}')
echo "Pod que se eliminara: $POD_A"
kubectl delete pod "$POD_A" -n "$NS"

echo "Esperando que el ReplicaSet cree un Pod nuevo..."
for _ in $(seq 1 60); do
  PODS=$(kubectl get pods -l "$SELECTOR" -n "$NS" --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  if ! printf '%s\n' "$PODS" | grep -qx "$POD_A" \
      && [ "$(printf '%s\n' "$PODS" | sed '/^$/d' | wc -l)" -eq 3 ]; then
    break
  fi
  sleep 2
done
if printf '%s\n' "$PODS" | grep -qx "$POD_A" \
    || [ "$(printf '%s\n' "$PODS" | sed '/^$/d' | wc -l)" -ne 3 ]; then
  echo "ERROR: el ReplicaSet no recupero las 3 replicas dentro del tiempo esperado" >&2
  exit 1
fi
kubectl get pods -l "$SELECTOR" -n "$NS" -o wide
kubectl get rs -l "$SELECTOR" -n "$NS"
echo

echo "=== Eventos del ReplicaSet ==="
kubectl describe rs -l "$SELECTOR" -n "$NS" | grep -E "SuccessfulCreate|Events|NAME" || true

echo
echo "Ciclo de vida completado. Captura esta terminal con el reloj visible."
