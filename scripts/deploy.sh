#!/usr/bin/env bash
# ============================================================
# Proyecto 2 — El Quetzal | Área 3 (Jorge)
# Levanta todo el stack en k3s desde cero, en orden y esperando
# a que cada capa esté lista antes de aplicar la siguiente:
#
#   namespace → ConfigMap → Postgres → backend → frontend → gateway
#
# Es el equivalente a `docker compose up -d` con los depends_on.
# Se puede correr varias veces: kubectl apply es idempotente.
#
# Uso:  ./scripts/deploy.sh
# Requisito: el Secret db-credentials ya creado (scripts/crear-secret.sh).
# ============================================================
set -euo pipefail

NS=proyecto-2-maximus
K8S="$(cd "$(dirname "$0")/../k8s" && pwd)"
ESPERA=180s

# Aplica cada archivo si existe. Mientras el equipo integra, un archivo
# que todavía no llegó por PR se reporta como PENDIENTE y no detiene el resto.
aplicar() {
  local archivo
  for archivo in "$@"; do
    if [[ -f "$K8S/$archivo" ]]; then
      kubectl apply -f "$K8S/$archivo"
    else
      echo "PENDIENTE: k8s/$archivo todavía no existe, se omite"
    fi
  done
}

# Espera a que cada Deployment tenga todas sus réplicas listas (readinessProbe en verde).
esperar() {
  local deploy
  for deploy in "$@"; do
    if kubectl get deployment "$deploy" -n "$NS" >/dev/null 2>&1; then
      kubectl rollout status "deployment/$deploy" -n "$NS" --timeout="$ESPERA"
    fi
  done
}

paso() { echo; echo "==> $*"; }

paso "1/6 Namespace"
aplicar 00-namespace.yaml
if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  echo "ERROR: el namespace $NS no existe. Falta k8s/00-namespace.yaml (Área 1)." >&2
  exit 1
fi

paso "2/6 Configuración (ConfigMap + verificación del Secret)"
if ! kubectl get secret db-credentials -n "$NS" >/dev/null 2>&1; then
  echo "ERROR: no existe el Secret db-credentials en $NS." >&2
  echo "       Crearlo primero con: ./scripts/crear-secret.sh .env" >&2
  exit 1
fi
aplicar 01-configmap.yaml

paso "3/6 Postgres (PVC, scripts de init, Deployment, Service)"
aplicar 10-postgres-pvc.yaml 13-db-scripts.yaml 11-postgres.yaml 12-postgres-svc.yaml
esperar postgres

paso "4/6 Backend (5 microservicios)"
aplicar 20-catalogo.yaml 21-inventario.yaml 22-clientes.yaml 23-pedidos.yaml 24-reportes.yaml
esperar catalogo inventario clientes pedidos reportes

paso "5/6 Frontend"
aplicar 30-frontend.yaml
esperar frontend

# Al final: nginx no arranca si un proxy_pass apunta a un Service que no existe.
paso "6/6 Gateway y Services de entrada"
aplicar 40-gateway-conf.yaml 41-gateway.yaml 42-gateway-svc.yaml
esperar gateway

paso "Estado final"
kubectl get all -n "$NS"
echo
kubectl get endpoints -n "$NS"
echo
echo "App: http://192.168.56.10:30080 (NodePort) y http://192.168.56.10:8080 (LoadBalancer)"
