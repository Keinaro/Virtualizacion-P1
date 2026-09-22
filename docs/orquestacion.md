# Área 3 — Orquestación y publicación

Responsable del `docker-compose.yml`, los `Dockerfile`, las variables de entorno
y la publicación de imágenes en Docker Hub.

Este documento es el **contrato** que las demás áreas deben respetar: los nombres
de servicio y los puertos internos de aquí son los que usan el gateway (Área 2),
el backend (Área 5) y el frontend (Área 6).

---

## 1. Contrato de nombres y puertos

Un contenedor resuelve a otro **por nombre de servicio** dentro de la red
`elquetzal_interna`; nunca por IP. `http://inventario:5000` es una dirección
válida desde cualquier contenedor del stack.

| Servicio (DNS interno) | Imagen                          | Puerto interno | Publicado al host |
|---|---|---|---|
| `db`         | `postgres:16-alpine`              | 5432 | no |
| `catalogo`   | `<namespace>/catalogo:1.0`        | 5000 | no |
| `inventario` | `<namespace>/inventario:1.0`      | 5000 | no |
| `clientes`   | `<namespace>/clientes:1.0`        | 5000 | no |
| `pedidos`    | `<namespace>/pedidos:1.0`         | 5000 | no |
| `reportes`   | `<namespace>/reportes:1.0`        | 5000 | no |
| `gateway`    | `<namespace>/gateway:1.0`         | 80   | **sí — `${GATEWAY_PORT}` (80 en la VM)** |

**Solo el gateway publica puerto.** Los microservicios y Postgres viven
únicamente en la red interna: desde el host no se les puede llegar directo, que
es justo lo que pide el enunciado.

- Red: `elquetzal_interna` (bridge)
- Volumen: `elquetzal_pgdata`

---

## 2. Orden de arranque (healthchecks)

`depends_on` por sí solo espera a que el contenedor **arranque**, no a que la
aplicación **responda**. Por eso cada servicio declara un `healthcheck`:

- `db` → `pg_isready -h 127.0.0.1` (TCP: ver nota abajo)
- Los 5 Flask → sonda HTTP a `/health` con la stdlib de Python
- `gateway` → `wget --spider` contra `/`

La cadena real es:

```
db (healthy) → catalogo, inventario, clientes (healthy)
             → pedidos   (espera inventario + clientes)
             → reportes  (espera inventario + pedidos)
             → gateway   (espera los 5)
```

`pedidos` y `reportes` dependen además de los servicios que consumen por HTTP,
así no reciben peticiones mientras sus dependencias todavía no responden.

**Por qué `-h 127.0.0.1` en `pg_isready`:** la primera vez que se crea el
volumen, la imagen de Postgres ejecuta los scripts de `db/init/` sobre un
servidor temporal que solo escucha por socket Unix. Sin `-h`, `pg_isready` usa
ese socket y reporta *healthy* antes de que existan las bases, y los
microservicios arrancan y fallan. Con `-h 127.0.0.1` la sonda va por TCP, que
solo se abre cuando la inicialización terminó. `start_period: 30s` cubre esa
primera inicialización.

Los microservicios usan la stdlib de Python en lugar de `curl`/`wget` porque la
imagen `python:3.12-slim` no los trae, e instalarlos solo para la sonda infla la
imagen sin necesidad.

Gracias a esto el gateway no acepta tráfico antes de que el backend esté listo,
lo que elimina los errores 502 de los primeros segundos tras un `up`.

---

## 3. Variables de entorno

Cero secretos quemados en el código.

- [`.env.example`](../.env.example) — plantilla, **sí** se versiona
- `.env` — valores reales, **nunca** se versiona (cubierto por `.gitignore`)

```bash
cp .env.example .env    # y rellenar con las claves reales
```

Las credenciales llegan a cada microservicio mediante `DB_HOST`, `DB_PORT`,
`DB_USER`, `DB_PASSWORD` y `DB_NAME`, configuradas en `docker-compose.yml`.
El servicio `db` recibe además las variables `<SERVICIO>_DB*` que consumen los
scripts de `db/init/` (Área 4) para crear cada base y su usuario.

| Variable | Uso |
|---|---|
| `POSTGRES_SUPERUSER` / `POSTGRES_SUPERUSER_PASSWORD` | superusuario, solo lo usa `db` |
| `<SERVICIO>_DB`, `<SERVICIO>_DB_USER`, `<SERVICIO>_DB_PASSWORD` | una base y un usuario por microservicio |
| `GATEWAY_PORT` | puerto de la VM donde escucha el gateway (**80**) |
| `DOCKERHUB_NAMESPACE` | namespace de las imágenes (`keinaro`) |

**Puerto del gateway y la red del Área 1:** la VM usa NAT con la regla
host `127.0.0.1:8080` → VM `80`. Por eso en la VM `GATEWAY_PORT=80`, y desde
el navegador del host se abre `http://127.0.0.1:8080`. Si alguien levanta el
stack directo en su laptop con Docker Desktop, puede usar `GATEWAY_PORT=8080`
en su `.env` local.

---

## 4. Runbook

### Levantar el stack

```bash
cp .env.example .env    # solo la primera vez; luego editar valores
docker compose build
docker compose up -d
docker compose ps       # los 7 contenedores deben verse (healthy)
```

Desde el navegador del host: `http://127.0.0.1:8080` (reenvío NAT del Área 1).

### Verificar que todo responde

Dentro de la VM (gateway en el puerto 80):

```bash
curl -i http://localhost/                      # frontend Vue -> 200
curl http://localhost/health                   # gateway
curl http://localhost/api/catalogo/health
curl http://localhost/api/inventario/health
curl http://localhost/api/clientes/health
curl http://localhost/api/pedidos/health
curl http://localhost/api/reportes/health
```

Desde el host, las mismas rutas con `http://127.0.0.1:8080`.

### Diagnóstico

```bash
docker compose ps -a                   # estado real, incluye los que murieron
docker compose logs -f <servicio>      # logs en vivo
docker compose exec <servicio> sh      # entrar al contenedor
docker compose config                  # ver el compose con variables resueltas
```

### Apagar

```bash
docker compose down        # conserva los datos
docker compose down -v     # BORRA el volumen y los datos — evitar
```

---

## 5. Publicación en Docker Hub

```bash
docker login
docker compose build
docker compose push
```

Como cada servicio ya declara su clave `image:` con `${DOCKERHUB_NAMESPACE}`,
`docker compose push` sube las 6 imágenes sin necesidad de etiquetarlas a mano.

Se usa la etiqueta `1.0` y no `latest`, para poder rastrear exactamente qué
versión corrió en la demo.

Imágenes del grupo (etiqueta `1.0`):

| Imagen | Origen del build |
|---|---|
| `keinaro/catalogo:1.0`   | `backend/catalogo` |
| `keinaro/inventario:1.0` | `backend/inventario` |
| `keinaro/clientes:1.0`   | `backend/clientes` |
| `keinaro/pedidos:1.0`    | `backend/pedidos` |
| `keinaro/reportes:1.0`   | `backend/reportes` |
| `keinaro/gateway:1.0`    | `gateway/Dockerfile` (contexto: raíz) |

`postgres:16-alpine` es imagen oficial, no se publica.

---

## 6. Evidencia de persistencia

Requisito: `docker compose down` seguido de `up` debe conservar los datos.

Prueba ejecutada (2026-09-19):

```bash
# 1. Escribir un marcador
docker compose exec -T db psql -U postgres -d inventario_db \
  -c "CREATE TABLE prueba_persistencia (id serial PRIMARY KEY, nota text, creado timestamptz DEFAULT now());" \
  -c "INSERT INTO prueba_persistencia (nota) VALUES ('marcador antes de docker compose down');"

# 2. Bajar el stack SIN -v
docker compose down
docker volume ls --filter name=elquetzal_pgdata   # el volumen sigue existiendo

# 3. Volver a levantar y consultar
docker compose up -d
docker compose exec -T db psql -U postgres -d inventario_db \
  -c "SELECT id, nota, creado FROM prueba_persistencia;"
```

Resultado: la fila reaparece con su **timestamp original** (`20:11:04`), no uno
nuevo — prueba de que el dato sobrevivió en el volumen `elquetzal_pgdata` y no
fue recreado por los scripts de seed.

La tabla de prueba se eliminó al terminar.

> Para la entrega: repetir esta secuencia en la VM y capturar pantalla con el
> **reloj del sistema visible**.

---

## 7. Decisiones de build

**Imágenes de los microservicios**

- Base `python:3.12-slim` (ligera).
- `requirements.txt` se copia **antes** que el código, para que el `pip install`
  quede cacheado y no se repita en cada cambio de fuente.
- Usuario no-root `appuser` (menor privilegio).
- `.dockerignore` por servicio, para no copiar `venv/`, `__pycache__/` ni `.git/`.

- Servidor `gunicorn` (2 workers) en lugar del servidor de desarrollo de Flask.

Los `Dockerfile` viven en `backend/<servicio>/` y se mantienen junto con el
Área 5. El contexto de build de cada microservicio es su propia carpeta.

**Historial: `wsgi.py`**

En la estructura anterior (`servicios/<servicio>/`) convivían un `app.py` y un
paquete `app/`; `import app` resolvía al paquete y `gunicorn app:app` fallaba
con `Failed to find attribute 'app' in 'app'`. Se resolvió renombrando el punto
de entrada a `wsgi.py`. La refactorización del Área 5 a `backend/` eliminó el
paquete `app/`, así que ahora gunicorn usa `app:app` directo y la carpeta
`servicios/` se retiró.

**Gateway: build multi-etapa**

Etapa 1 (`node:20-alpine`) compila el frontend con `npm run build`; etapa 2
(`nginx:1.27-alpine`) solo se queda con el `dist/`. Node no llega a la imagen
final.

`npm ci` exige un `package-lock.json` — por eso el lockfile está versionado. Se
prefiere `npm ci` sobre `npm install` porque instala exactamente las versiones
del lock, dando builds reproducibles.

**`.dockerignore` en la raíz**

El gateway usa el repo completo como contexto de build, y los `.dockerignore` de
las subcarpetas **no** aplican ahí. Sin uno en la raíz se enviaban `.git/`,
`backend/` y `docs/` al daemon en cada build.
