# Datos — Área 4

Un solo motor PostgreSQL, con una base de datos y un usuario independiente por microservicio.

## Bases de datos

- `catalogo_db` → usuario `catalogo_user`
- `inventario_db` → usuario `inventario_user`
- `clientes_db` → usuario `clientes_user`
- `pedidos_db` → usuario `pedidos_user`
- `reportes_db` → usuario `reportes_user`

## Estructura

db/
├── init/
│   ├── 01-crear-bases.sh
│   └── 02-aplicar-esquemas-y-seeds.sh
│
├── schemas/
│   ├── catalogo.sql
│   ├── inventario.sql
│   ├── clientes.sql
│   ├── pedidos.sql
│   └── reportes.sql
│
└── seeds/
    ├── catalogo.sql
    ├── inventario.sql
    └── clientes.sql

## Inicialización automática

Al crear el volumen de PostgreSQL por primera vez, se ejecutan automáticamente los scripts de `db/init`.

El flujo es:

1. Crear las cinco bases y sus usuarios.
2. Aplicar el esquema correspondiente a cada base.
3. Insertar los datos semilla.

Los scripts de inicialización solo se ejecutan cuando el volumen está vacío.

Para probar una inicialización completamente nueva:

docker compose down -v
docker compose up -d db

## Esquemas

Cada microservicio posee su propia base de datos.

### Catálogo

Tablas:

- `categorias`
- `productos`

La base `catalogo_db` contiene la información descriptiva de las categorías y productos.

### Inventario

Tabla:

- `existencias`

La base `inventario_db` es la fuente oficial para precio y stock de los productos.

La tabla `existencias` contiene:

- id
- sku
- nombre
- categoria
- precio
- stock
- stock_minimo
- actualizado_en

### Clientes

Tabla:

- `clientes`

La base `clientes_db` contiene los datos de los integrantes del grupo y sus carnés.

La tabla `clientes` contiene:

- id
- carne
- nombre
- correo
- creado_en

Los seis carnés del grupo se cargan automáticamente mediante el seed `clientes.sql`.

### Pedidos

Tablas:

- `pedidos`
- `pedido_lineas`

La tabla `pedidos` almacena la información general del pedido.

La tabla `pedido_lineas` almacena los productos y cantidades de cada pedido.

Las referencias hacia clientes e inventario son relaciones lógicas entre microservicios y no foreign keys entre bases de datos diferentes.

### Reportes

Tabla:

- `reportes_generados`

La base `reportes_db` almacena el historial de reportes generados por el servicio de reportes.

El servicio consulta información de inventario y pedidos para calcular las métricas y guarda el resultado generado en esta tabla.

## Usuarios y aislamiento

Cada base tiene su propio usuario:

- `catalogo_user` → `catalogo_db`
- `inventario_user` → `inventario_db`
- `clientes_user` → `clientes_db`
- `pedidos_user` → `pedidos_db`
- `reportes_user` → `reportes_db`

Cada usuario tiene permisos sobre su propia base.

Esto permite mantener aislamiento lógico entre microservicios y aplicar el principio de menor privilegio.

## Seeds

Los datos iniciales están en `db/seeds`.

### Catálogo

`catalogo.sql`

Inserta las categorías iniciales utilizadas por el sistema.

### Inventario

`inventario.sql`

Inserta productos iniciales con stock y stock mínimo.

También incluye productos con stock bajo para poder demostrar las alertas del dashboard.

### Clientes

`clientes.sql`

Inserta los seis integrantes del grupo con su carné, nombre y correo.

Estos carnés son evidencia obligatoria del proyecto y posteriormente se muestran en la interfaz y en los pedidos.

## Persistencia

PostgreSQL utiliza el volumen nombrado:

`elquetzal_pgdata`

El comando:

docker compose down

elimina los contenedores, pero conserva el volumen y los datos.

El comando:

docker compose down -v

elimina también el volumen y provoca que PostgreSQL se inicialice nuevamente desde cero en el próximo arranque.

La persistencia fue comprobada realizando un `down` y un nuevo `up`, verificando que los registros continuaban almacenados.

## Verificaciones útiles

### Listar bases de datos

docker exec -it elquetzal-db psql -U postgres -d postgres -c "\l"

### Listar usuarios

docker exec -it elquetzal-db psql -U postgres -d postgres -c "\du"

### Ver tablas de catálogo

docker exec -it elquetzal-db psql -U catalogo_user -d catalogo_db -c "\dt"

### Ver tablas de inventario

docker exec -it elquetzal-db psql -U inventario_user -d inventario_db -c "\dt"

### Ver tablas de clientes

docker exec -it elquetzal-db psql -U clientes_user -d clientes_db -c "\dt"

### Ver tablas de pedidos

docker exec -it elquetzal-db psql -U pedidos_user -d pedidos_db -c "\dt"

### Ver tablas de reportes

docker exec -it elquetzal-db psql -U reportes_user -d reportes_db -c "\dt"

### Ver carnés del grupo

docker exec -it elquetzal-db psql -U clientes_user -d clientes_db -c "SELECT carne, nombre FROM clientes ORDER BY carne;"

### Ver inventario

docker exec -it elquetzal-db psql -U inventario_user -d inventario_db -c "SELECT sku, nombre, stock, stock_minimo FROM existencias ORDER BY sku;"

## Prueba de aislamiento

Ejemplo de acceso permitido:

docker exec -it elquetzal-db psql -U inventario_user -d inventario_db -c "SELECT COUNT(*) FROM existencias;"

Ejemplo de acceso no permitido:

docker exec -it elquetzal-db psql -U inventario_user -d catalogo_db -c "SELECT * FROM categorias;"

El segundo comando debe responder con un error de permisos, demostrando que los usuarios están aislados entre bases.

## Reproducibilidad

Para comprobar que la base puede construirse desde cero:

docker compose down -v
docker compose up -d db

Después se pueden revisar los logs con:

docker logs elquetzal-db

La inicialización debe crear automáticamente:

- cinco bases de datos
- cinco usuarios
- todos los esquemas
- los datos semilla

Al finalizar los logs deben mostrar:

Esquemas y seeds aplicados correctamente.