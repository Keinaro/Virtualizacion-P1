# Área 3 — Orquestación en Kubernetes

Responsable: **Jorge Muñoz**. Criterios que respalda: 2 (parte backend), 5 y 6,
más la integración de todos los manifiestos.

Este documento explica cómo se tradujo el `docker-compose.yml` del Proyecto 1
a manifiestos de Kubernetes (k3s). El runbook del Proyecto 1 sigue en
[`orquestacion.md`](orquestacion.md).

## 1. Traducción Compose → Kubernetes

| En el compose del Proyecto 1 | En Kubernetes | Archivo |
|---|---|---|
| 7 `services` con `container_name` | Deployments (ReplicaSet → Pods con nombre aleatorio) + un Service con el mismo nombre | `11`, `20-24`, `30`, `41` |
| Red `elquetzal_interna` | Red del clúster + DNS por nombre de Service | Automático |
| `ports: "80:80"` del gateway | Services NodePort 30080 y LoadBalancer 8080 | `42` |
| `.env` sin secretos (nombres de base) y valores escritos en el compose (`db`, `5432`, URLs) | ConfigMap `app-config` | `01` |
| `.env` con contraseñas | Secret `db-credentials` | Creado en la VM con `scripts/crear-secret.sh`; plantilla en `plantillas/02-secret.example.yaml` |
| Volumen `elquetzal_pgdata` | PVC `postgres-pvc` | `10` |
| `./db/init`, `./db/schemas`, `./db/seeds` montados en el contenedor | ConfigMaps montados en el Pod de Postgres | `13` |
| `healthcheck` | `readinessProbe` y `livenessProbe` a `/health` | Cada Deployment |
| `depends_on: service_healthy` | `initContainer` que espera a `db` | `20-24` |
| `restart: unless-stopped` | Autoreparación del ReplicaSet + liveness | Automático |
| `nginx.conf` dentro de la imagen | ConfigMap `gateway-conf` | `40` |
| `docker compose up -d` | `scripts/deploy.sh` (aplica en orden y espera cada capa) | `scripts/` |

**Por qué los Services se llaman igual que en el compose.** El código Flask y
el gateway llaman a `db`, `inventario`, `clientes`, etc. por nombre. En
Kubernetes cada Service registra ese nombre en el DNS del clúster, así que
nada del código cambia. Dentro del mismo namespace basta el nombre corto; el
completo sería `inventario.proyecto-2-maximus.svc.cluster.local`.

## 2. Configuración: qué va al ConfigMap y qué al Secret

El backend arma la cadena de conexión en `backend/<servicio>/database.py` con
cinco variables, y falla al arrancar si falta alguna:

```python
required = ("DB_HOST", "DB_PORT", "DB_USER", "DB_PASSWORD", "DB_NAME")
```

| Variable en el contenedor | Origen | Clave |
|---|---|---|
| `DB_HOST` | ConfigMap `app-config` (`envFrom`) | `DB_HOST` = `db` |
| `DB_PORT` | ConfigMap `app-config` (`envFrom`) | `DB_PORT` = `5432` |
| `DB_NAME` | ConfigMap `app-config` (`configMapKeyRef`) | `<SERVICIO>_DB` |
| `DB_USER` | Secret `db-credentials` (`secretKeyRef`) | `<SERVICIO>_DB_USER` |
| `DB_PASSWORD` | Secret `db-credentials` (`secretKeyRef`) | `<SERVICIO>_DB_PASSWORD` |
| `INVENTARIO_URL`, `CLIENTES_URL`, `PEDIDOS_URL` | ConfigMap `app-config` (`envFrom`) | Mismo nombre |

**`envFrom` frente a `env`.** `envFrom` copia todas las claves del ConfigMap
como variables con el mismo nombre; sirve para `DB_HOST`, `DB_PORT` y las URLs,
que son iguales para los 5 servicios. `env` con `valueFrom` toma **una** clave
y la pone bajo **otro** nombre; sirve para `DB_NAME`, `DB_USER` y
`DB_PASSWORD`, porque cada servicio lee la clave de su propia base
(`CATALOGO_DB` → `DB_NAME`).

**El Secret no está en el repositorio.** Se crea en la VM desde el `.env`, que
`.gitignore` excluye:

```bash
cp .env.example .env              # llenar las contraseñas reales
./scripts/crear-secret.sh .env    # toma solo las 12 claves de credenciales
kubectl get secret db-credentials -n proyecto-2-maximus   # DATA 12, sin valores
```

El script filtra el `.env`: solo pasan `POSTGRES_SUPERUSER`,
`POSTGRES_SUPERUSER_PASSWORD` y `<SERVICIO>_DB_USER` / `<SERVICIO>_DB_PASSWORD`
de los cinco servicios. Los valores no pasan por la línea de comandos (no
quedan en el historial de bash) y el archivo temporal se borra al terminar.

**Base64 no es cifrado.** `kubectl get secret -o yaml` muestra los valores en
base64 y `base64 -d` los devuelve tal cual. Lo que protege al Secret es que no
está en el repositorio y que el acceso al clúster está restringido, no la
codificación. Por eso, si un Secret real llegara a subirse, hay que cambiar
las contraseñas: borrar el commit no lo saca del historial.

**Por qué la plantilla vive en `k8s/plantillas/`.** `kubectl apply -f k8s/` no
entra a subcarpetas. Si la plantilla estuviera en `k8s/`, cada `apply` pisaría
el Secret real con los valores `CAMBIAR` y los microservicios dejarían de
autenticarse.

## 3. Deployments del backend

Los cinco archivos `20-catalogo.yaml` … `24-reportes.yaml` son idénticos salvo
el nombre del servicio. Cada uno lleva un Deployment y su Service ClusterIP
separados por `---`.

| Decisión | Por qué |
|---|---|
| `replicas: 1` | Cuidar los 4 GB de la VM. El escalado a 3 lo demuestra Sofía editando `21-inventario.yaml`. |
| Imagen `keinaro/<servicio>:1.0`, `imagePullPolicy: IfNotPresent` | Las imágenes del Proyecto 1 se reutilizan sin reconstruir. Tag fijo, nunca `latest`, para saber exactamente qué corre en la demo. |
| `initContainer` `espera-db` | Reemplaza a `depends_on: service_healthy`. Corre `pg_isready -h db` hasta que Postgres acepte conexiones; recién entonces arranca el contenedor principal. Sin él, `database.py` intentaría crear tablas contra una base que no existe y el Pod entraría en `CrashLoopBackOff` hasta que Postgres termine. |
| `readinessProbe` a `/health` | El Service solo manda tráfico a Pods que responden. Es lo que hace que `kubectl get endpoints` muestre la IP del Pod. |
| `livenessProbe` a `/health` | Si gunicorn se cuelga, el kubelet reinicia el contenedor (equivale a `restart: unless-stopped` más el `healthcheck`). |
| `requests` 50m / 128Mi, `limits` 500m / 256Mi | gunicorn con 2 workers usa cerca de 150 MB. El `request` reserva memoria al programar el Pod; el `limit` evita que un servicio se coma la VM. |
| Labels `app: <servicio>` y `equipo: maximus` | El Service selecciona por `app`; `equipo` deja rastro del idEquipo en todos los recursos. |

**Selector y labels.** El `selector` del Service (`app: catalogo`) tiene que
coincidir con los `labels` del template del Pod. Si no coinciden, el Service
existe pero `kubectl get endpoints catalogo` sale vacío y el gateway devuelve
502. Es el primer lugar donde mirar.

### Presupuesto de memoria (requests / limits)

| Componente | Pods | Requests | Limits |
|---|---|---|---|
| Backend (5 servicios) | 5 | 640Mi | 1280Mi |
| Postgres | 1 | 256Mi | 512Mi |
| Frontend | 2 | 64Mi | 256Mi |
| Gateway | 2 | 64Mi | 256Mi |
| **Total** | **10** | **1024Mi** | **2304Mi** |

Con inventario en 3 réplicas se suman 256Mi de requests. k3s mismo usa entre
500 y 800 MB; en 4 GB cabe, pero con poco margen (ver Área 1).

## 4. Orden de despliegue (`scripts/deploy.sh`)

```text
1. 00-namespace.yaml
2. verifica el Secret db-credentials → 01-configmap.yaml
3. 10-postgres-pvc, 13-db-scripts, 11-postgres, 12-postgres-svc → espera a postgres
4. 20-catalogo … 24-reportes → espera a los 5
5. 30-frontend → espera
6. 40-gateway-conf, 41-gateway, 42-gateway-svc → espera
```

- La espera es `kubectl rollout status deployment/<x> --timeout=180s`: termina
  cuando todas las réplicas pasan la `readinessProbe`.
- El gateway va al final porque nginx no arranca si un `proxy_pass` apunta a
  un Service que todavía no existe.
- Si falta el Secret, el script se detiene con el comando para crearlo.
- Mientras el equipo integra, un archivo que todavía no llegó por PR se
  reporta como `PENDIENTE` y no detiene el resto.
- Es idempotente: correrlo de nuevo solo aplica lo que cambió.

Antes de aplicar cambios grandes, validar contra el servidor sin crear nada:

```bash
kubectl apply -f k8s/ --dry-run=server
```

## 5. Evidencias del Área 3 (con reloj visible)

| Criterio | Captura |
|---|---|
| 2 | Docker Hub con `keinaro/catalogo`, `inventario`, `clientes`, `pedidos`, `reportes` en `1.0`; `kubectl get deploy,pods -n proyecto-2-maximus` con los 5 en `Running` y `READY 1/1` |
| 5 | `kubectl describe configmap app-config -n proyecto-2-maximus`; fragmento de `20-catalogo.yaml` con `configMapRef` y `configMapKeyRef` |
| 6 | `kubectl get secret db-credentials -n proyecto-2-maximus` (sin valores); fragmento con `secretKeyRef`; `.gitignore`; `git log --all -- .env .env.secrets` vacío |
| Integración | `./scripts/deploy.sh` corriendo de cero hasta `kubectl get all` |

## 6. Preguntas que hay que poder responder

- **Deployment, ReplicaSet y Pod.** El Deployment declara el estado deseado
  (imagen, réplicas). Crea un ReplicaSet, que es quien mantiene N Pods vivos.
  El Pod es la instancia que corre el contenedor. Al cambiar la imagen, el
  Deployment crea un ReplicaSet nuevo y va pasando los Pods (rolling update).
- **ConfigMap frente a Secret.** Los dos inyectan variables o archivos. El
  Secret se guarda aparte, se puede restringir por RBAC y no se imprime en
  `describe`; el ConfigMap es para lo que se puede leer sin riesgo.
- **Por qué el initContainer reemplaza a `depends_on`.** Kubernetes no tiene
  orden de arranque entre Deployments. El initContainer corre antes del
  contenedor principal dentro del mismo Pod y solo termina cuando `db`
  responde.
- **Qué pasa si se cambia el ConfigMap.** Los Pods leen las variables al
  arrancar; hay que hacer `kubectl rollout restart deployment/<x>`.
- **Qué pasa si se cambia una contraseña del Secret después de sembrar la
  base.** Los scripts de `db/init/` solo corren con el volumen vacío, así que
  la contraseña dentro de Postgres no cambia y el servicio falla al
  autenticarse. Hay que cambiarla también con `ALTER ROLE` o volver a sembrar.
