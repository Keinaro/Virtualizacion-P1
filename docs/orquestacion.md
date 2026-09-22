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
| `gateway`    | `<namespace>/gateway:1.0`         | 80   | **sí — `${GATEWAY_PORT}` (8080)** |

**Solo el gateway publica puerto.** Los microservicios y Postgres viven
únicamente en la red interna: desde el host no se les puede llegar directo, que
es justo lo que pide el enunciado.

- Red: `elquetzal_interna` (bridge)
- Volumen: `elquetzal_pgdata`

---

## 2. Orden de arranque (healthchecks)

`depends_on` por sí solo espera a que el contenedor **arranque**, no a que la
aplicación **responda**. Por eso cada servicio declara un `healthcheck`:

- `db` → `pg_isready`
- Los 5 Flask → sonda HTTP a `/health` con la stdlib de Python
- `gateway` → `wget --spider` contra `/`

La cadena real es:

```
db (healthy) → los 5 microservicios (healthy) → gateway
```

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

<<<<<<< HEAD
Las credenciales llegan a cada microservicio mediante `DB_HOST`, `DB_PORT`,
`DB_USER`, `DB_PASSWORD` y `DB_NAME`, configuradas en `docker-compose.yml`.

---

## 4. Runbook

### Levantar el stack

```bash
cp .env.example .env    # solo la primera vez; luego editar valores
docker compose build
docker compose up -d
docker compose ps       # los 7 contenedores deben verse (healthy)
```

Abrir `http://localhost:8080` (o `http://<IP-de-la-VM>:8080` desde el host).

### Verificar que todo responde

```bash
curl -i http://localhost:8080/                      # frontend Vue -> 200
curl http://localhost:8080/api/catalogo/health
curl http://localhost:8080/api/inventario/health
curl http://localhost:8080/api/clientes/health
curl http://localhost:8080/api/pedidos/health
curl http://localhost:8080/api/reportes/health
```

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

> Pendiente: fijar `DOCKERHUB_NAMESPACE` en el `.env` con el namespace real del
> grupo antes de publicar.

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

**`wsgi.py` en lugar de `app.py`**

Cada servicio tiene un `app.py` y además un paquete `app/`. En Python el paquete
gana: `import app` resuelve a `app/__init__.py`, así que `gunicorn app:app`
fallaba con `Failed to find attribute 'app' in 'app'` y los 5 contenedores
reiniciaban en bucle. El `Dockerfile` renombra el punto de entrada a `wsgi.py` y
gunicorn usa `wsgi:app`, que es inequívoco, sin tocar el código del Área 5.

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
