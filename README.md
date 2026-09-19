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
├── servicios/          Área 5 — microservicios Flask
│   ├── catalogo/
│   ├── inventario/
│   ├── clientes/
│   ├── pedidos/        regla crítica: descuento atómico de stock
│   └── reportes/
├── frontend/           Área 6 — proyecto Vue
├── db/                 Área 4 — schema, seeds, init
├── docker-compose.yml  Área 3 — orquestación
├── .env.example        Área 3 — plantilla (el .env real NO se versiona)
└── docs/               arquitectura, modelo de datos, mapa de propiedad, costos
```

## Levantar el stack

```bash
# 1. Configurar el entorno
cp .env.example .env
# editar .env con las credenciales reales

# 2. Construir y levantar
docker compose up -d --build

# 3. Verificar
docker compose ps
curl http://localhost:8080/health
```

La app queda en `http://<ip-de-la-vm>:8080` (puerto configurable con
`GATEWAY_PORT`).

## Aplicar esquema y datos semilla

Ver [`db/README.md`](db/README.md). Los carnés del equipo se siembran en
`clientes_db` — es evidencia obligatoria del proyecto.

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
| 1 | Infraestructura (VM, Linux, Docker Engine, red) | _por asignar_ |
| 2 | Gateway y redes Docker | _por asignar_ |
| 3 | Orquestación y publicación | _por asignar_ |
| 4 | Datos (Postgres, esquemas, seeds) | _por asignar_ |
| 5 | Backend de dominio (Flask) | _por asignar_ |
| 6 | Frontend + costos | _por asignar_ |

Detalle completo en [`docs/mapa-de-propiedad.md`](docs/mapa-de-propiedad.md).
