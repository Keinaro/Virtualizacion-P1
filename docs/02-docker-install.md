# Instalación de Docker Engine + Compose (por CLI)

El enunciado pide "Docker Engine + Compose instalados en el guest por línea
de comandos" — **no** Docker Desktop, y sin usar el `docker.io` de los repos
de Ubuntu (versión vieja). Usamos el repositorio oficial de Docker.

Todo esto lo automatiza `guest/01-install-docker.sh` (correlo dentro de la
VM, por SSH, con `sudo`). Documento aquí qué hace y por qué, para la defensa
y por si hay que repetirlo a mano:

```bash
# 1. Dependencias para agregar un repo por HTTPS
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# 2. Clave GPG oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 3. Repositorio oficial de Docker para esta versión de Ubuntu
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Instalar Docker Engine + el plugin de Compose (docker compose v2)
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

# 5. Permitir usar docker sin sudo (requiere cerrar sesión y volver a entrar)
sudo usermod -aG docker $USER
```

## Verificación

```bash
docker --version
docker compose version
sudo systemctl status docker --no-pager
docker run --rm hello-world
```

`guest/02-verify-evidencias.sh` imprime todo esto junto con el hostname y la
fecha/hora del sistema, en un solo bloque listo para captura de pantalla.

## Por qué así y no con snap / docker.io

- `snap install docker`: empaquetado por Canonical, versión desactualizada y
  con particularidades de red (netfilter) que complican el `docker network`
  interno que necesita el gateway. Evitar.
- `apt install docker.io`: paquete de los repos estándar de Ubuntu, también
  suele ir varias versiones atrás de Docker Compose v2 (plugin). El
  repositorio oficial de Docker garantiza Engine + Compose v2 alineados y
  es el que documentan los propios docs de Docker para producción.

## Variables de entorno / cero secretos en el código

Esto lo resuelve cada microservicio con su propio `.env` (Área 3 —
Orquestación — y Área 4 — Datos — son responsables del contenido), pero a
nivel de infraestructura garantizamos:

- Docker Engine y Compose quedan instalados de forma que cualquier
  `docker-compose.yml` que use `env_file:` o `environment:` con variables
  funcione sin cambios en el guest.
- El usuario del sistema (`ubuntu`) no tiene por qué tener las credenciales
  de Postgres — esas viven en los `.env` del proyecto, fuera de git
  (ver `.gitignore` en la raíz del repo).
