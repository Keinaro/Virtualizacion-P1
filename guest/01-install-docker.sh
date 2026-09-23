#!/usr/bin/env bash
# Instala Docker Engine + Compose plugin desde el repositorio oficial de
# Docker (no snap, no docker.io de Ubuntu — ver docs/02-docker-install.md
# para el porqué). Correr dentro de la VM, con sudo.
#
# Uso:
#   ./01-install-docker.sh

set -euo pipefail

echo "==> Instalando dependencias"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "==> Agregando la clave GPG oficial de Docker"
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Agregando el repositorio oficial de Docker"
ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "==> Instalando Docker Engine + Compose plugin"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

echo "==> Habilitando el servicio"
sudo systemctl enable --now docker

echo "==> Permitiendo usar docker sin sudo para $USER (requiere volver a iniciar sesión SSH)"
sudo usermod -aG docker "$USER"

echo ""
echo "==> Verificación:"
docker --version
docker compose version
sudo systemctl is-active docker

echo ""
echo "Nota: cierra esta sesión SSH y vuelve a entrar para que el grupo 'docker'"
echo "tome efecto sin necesitar sudo en cada comando."
