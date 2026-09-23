# El Quetzal — Proyecto 1

Tienda de artesanías guatemaltecas desplegada como microservicios sobre
infraestructura virtualizada.
Virtualización — Ingeniería en Informática y Sistemas, Universidad Rafael Landívar.

## Stack

| Capa | Tecnología |
|---|---|
| Virtualización | VirtualBox + Ubuntu Server (headless) |
| Contenedores | Docker Engine + Docker Compose |
| Gateway | nginx |
| Backend | 5 microservicios Flask (Python 3.12) |
| Base de datos | PostgreSQL 16 (una base por microservicio) |
| Frontend | Vue 3 + Vite (build estático servido por nginx) |

## Estructura

```
elquetzal/
├── gateway/            Área 2 — nginx.conf, Dockerfile
├── backend/            Área 5 — microservicios Flask
│   ├── catalogo/
│   ├── inventario/
│   ├── clientes/
│   ├── pedidos/        regla crítica: descuento atómico de stock
│   └── reportes/
├── frontend/           Área 6 — proyecto Vue
├── db/                 Área 4 — schema, seeds, init
├── docker-compose.yml  Área 3 — orquestación
├── .env.example        Área 3 — plantilla (el .env real NO se versiona)
├── host/               Área 1 — scripts de Windows para crear/gestionar la VM
├── guest/              Área 1 — scripts que corren dentro de Ubuntu Server
├── config/             Área 1 — sizing y variables de la VM
└── docs/               arquitectura, modelo de datos, mapa de propiedad, costos,
                        más setup de VM/Docker/red (Área 1)
```

## Levantar el stack

```bash
# 1. Configurar el entorno
cp .env.example .env
# editar .env con las credenciales reales

# 2. Construir y levantar
docker compose up -d --build

# 3. Verificar (dentro de la VM)
docker compose ps          # los 7 contenedores en (healthy)
curl http://localhost/health
```

En la VM el gateway escucha en el puerto 80 (`GATEWAY_PORT=80`). Desde el
navegador del host se abre `http://127.0.0.1:8080`, gracias al reenvío NAT
host `8080` → VM `80` del Área 1. Runbook completo en
[`docs/orquestacion.md`](docs/orquestacion.md).

## Esquema y datos semilla

Se aplican **automáticamente** la primera vez que se crea el volumen
`elquetzal_pgdata` (scripts de `db/init/`). Detalle en
[`db/README.md`](db/README.md). Los carnés del equipo se siembran en
`clientes_db` — es evidencia obligatoria del proyecto.

## Infraestructura (Área 1)

La VM Ubuntu Server con Docker ya está provisionada. Documentación y scripts:

- [`docs/00-sizing.md`](docs/00-sizing.md) — justificación de CPU/RAM/disco.
- [`docs/01-vm-setup.md`](docs/01-vm-setup.md) — instalación de VirtualBox y la VM paso a paso.
- [`docs/02-docker-install.md`](docs/02-docker-install.md) — instalación de Docker Engine + Compose por CLI.
- [`docs/03-red-host-vm.md`](docs/03-red-host-vm.md) — red host↔VM (NAT+reenvío vs Bridge).
- [`docs/04-evidencias.md`](docs/04-evidencias.md) — checklist de evidencias personalizadas.
- [`docs/05-checklist-entrega.md`](docs/05-checklist-entrega.md) — checklist contra la rúbrica.
- `host/` — scripts de PowerShell para crear y gestionar la VM desde Windows.
- `guest/` — scripts de bash para correr dentro de la VM (post-instalación, Docker, verificación de evidencias).
- `config/vm.conf` — sizing, nombre de grupo, carné y puertos de la VM.

## Publicar imágenes en Docker Hub

```bash
docker login
docker compose build
docker compose push
```

Las etiquetas salen de `DOCKERHUB_NAMESPACE` en `.env`. Usar versiones
semánticas (`1.0`), no solo `latest`, para poder rastrear qué corre en la demo.

## Reglas de trabajo del equipo

- **Nunca** commitear el `.env` real. Solo `.env.example`.
- Respetar los nombres de servicios y puertos de `docker-compose.yml`:
  son el contrato entre áreas.
- El frontend llama **siempre** a través del gateway (`/api/<servicio>/`),
  nunca directo a un microservicio.
- Documentar con capturas donde se vea el **reloj del sistema**.

## Áreas y responsables

| Área | Tema | Responsable |
|---|---|---|
| 1 | Infraestructura (VM, Linux, Docker Engine, red) | Daniel Paz |
| 2 | Gateway y redes Docker | _por asignar_ |
| 3 | Orquestación y publicación | _por asignar_ |
| 4 | Datos (Postgres, esquemas, seeds) | _por asignar_ |
| 5 | Backend de dominio (Flask) | _por asignar_ |
| 6 | Frontend + costos | _por asignar_ |

Detalle completo en [`docs/mapa-de-propiedad.md`](docs/mapa-de-propiedad.md).
