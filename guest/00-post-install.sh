#!/usr/bin/env bash
# Post-instalación de Ubuntu Server para El Quetzal.
# Correr dentro de la VM (por SSH), con sudo.
#
# Uso:
#   ./00-post-install.sh srv-elquetzal-maximus
#
# Si no se pasa el hostname como argumento, lo pregunta interactivamente.

set -euo pipefail

HOSTNAME_ARG="${1:-}"

if [ -z "$HOSTNAME_ARG" ]; then
  read -rp "Hostname a asignar (ej. srv-elquetzal-maximus): " HOSTNAME_ARG
fi

echo "==> Poniendo hostname: $HOSTNAME_ARG"
sudo hostnamectl set-hostname "$HOSTNAME_ARG"

# Asegura que /etc/hosts resuelva el nuevo hostname localmente
if ! grep -q "$HOSTNAME_ARG" /etc/hosts; then
  echo "127.0.1.1   $HOSTNAME_ARG" | sudo tee -a /etc/hosts > /dev/null
fi

echo "==> Ajustando zona horaria a America/Guatemala (para que el reloj de las evidencias tenga sentido)"
sudo timedatectl set-timezone America/Guatemala

echo "==> Actualizando paquetes del sistema"
sudo apt-get update
sudo apt-get upgrade -y

echo ""
echo "==> Listo. Verificación:"
hostnamectl
timedatectl
