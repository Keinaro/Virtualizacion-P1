#!/usr/bin/env bash
# Imprime en un solo bloque todo lo que hay que capturar como evidencia de
# Infraestructura (Área 1): hostname, fecha/hora, red y versiones de Docker.
# Correr dentro de la VM y capturar la pantalla completa de la terminal.
#
# Uso:
#   ./02-verify-evidencias.sh

set -euo pipefail

line() { printf '%.0s-' {1..60}; echo; }

echo "EVIDENCIAS DE INFRAESTRUCTURA — EL QUETZAL"
line

echo "[Hostname]"
hostnamectl | grep -E "Static hostname|Operating System|Kernel"
echo

echo "[Fecha y hora del sistema]"
timedatectl | grep -E "Local time|Time zone"
echo

echo "[Red]"
ip -brief addr show | grep -v "^lo"
echo

echo "[Docker Engine]"
docker --version
echo

echo "[Docker Compose]"
docker compose version
echo

echo "[Estado del daemon]"
sudo systemctl is-active docker
echo

line
echo "Captura esta pantalla completa (con el reloj visible) como evidencia."
