# Progreso Área 4 — Datos

## Trabajo completado

- Se creó una base de datos independiente por microservicio:
  - catalogo_db
  - inventario_db
  - clientes_db
  - pedidos_db
  - reportes_db

- Se creó un usuario independiente para cada base:
  - catalogo_user
  - inventario_user
  - clientes_user
  - pedidos_user
  - reportes_user

- Se separaron los esquemas en:
  - db/schemas/catalogo.sql
  - db/schemas/inventario.sql
  - db/schemas/clientes.sql
  - db/schemas/pedidos.sql
  - db/schemas/reportes.sql

- Se agregó inicialización automática con:
  - db/init/01-crear-bases.sh
  - db/init/02-aplicar-esquemas-y-seeds.sh

- Se agregaron seeds para:
  - categorías
  - inventario
  - carnés reales del grupo

- Se verificó:
  - creación desde cero
  - aislamiento entre usuarios
  - persistencia con el volumen elquetzal_pgdata
  - creación correcta de tablas y datos semilla

- Se agregó documentación del modelo de datos y diagrama ER.

## Cambios que afectan Orquestación

El Área 4 ahora utiliza estos mounts adicionales para inicializar PostgreSQL:

- ./db/init → /docker-entrypoint-initdb.d
- ./db/schemas → /opt/elquetzal/schemas
- ./db/seeds → /opt/elquetzal/seeds

Se recomienda mantenerlos en modo read-only.

## Pendiente de integración con Área 3

El backend nuevo del Área 5 se encuentra en:

backend/<servicio>

pero el docker-compose actual todavía utiliza:

servicios/<servicio>

Además, el backend nuevo utiliza estas variables:

- DB_HOST
- DB_PORT
- DB_USER
- DB_PASSWORD
- DB_NAME

mientras que el docker-compose actual entrega DATABASE_URL.

Por lo tanto, Área 3 debe ajustar:

1. Las rutas de build hacia backend/<servicio>.
2. Las variables de entorno de cada microservicio.
3. Mantener los mounts nuevos del servicio db.
4. Verificar que el volumen siga siendo elquetzal_pgdata.
5. Mantener INVENTARIO_URL, CLIENTES_URL y PEDIDOS_URL para la comunicación interna entre servicios.

## Nota

Los schemas y modelos del backend ya fueron revisados y son compatibles con la estructura de base de datos del Área 4.