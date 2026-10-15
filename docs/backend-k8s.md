# Área 5 - Backend en Kubernetes

**Proyecto:** El Quetzal - Fase 2  
**Responsable:** Sofia  
**Namespace:** `proyecto-2-maximus`  
**Criterios:** 7 (configuración del backend), 8 (escalado declarativo) y 9 (autoreparación). También participa en el criterio 13 junto con el Área 6.

## Alcance

El backend del Proyecto 1 se reutiliza sin reescribir la aplicación. Las imágenes publicadas en Docker Hub escuchan en el puerto `5000` y ya exponen `GET /health`. Kubernetes solo cambia la forma de ejecutar y configurar los contenedores:

```text
ConfigMap + Secret -> variables de entorno del Pod Flask
Service inventario -> Pods de inventario:5000
Deployment -> ReplicaSet -> Pods
Gateway -> Service -> backend
```

Los cinco Deployments del backend son `catalogo`, `inventario`, `clientes`, `pedidos` y `reportes`. La responsabilidad específica de esta área es validar la configuración consumida por la aplicación, escalar `inventario` editando su YAML y demostrar la autoreparación de sus Pods.

## Variables que consume el código

Todos los servicios requieren estas variables para construir la conexión SQLAlchemy a PostgreSQL:

| Variable | Origen en Kubernetes | Uso |
|---|---|---|
| `DB_HOST` | ConfigMap `app-config` | Service de PostgreSQL, normalmente `db` |
| `DB_PORT` | ConfigMap `app-config` | Puerto `5432` |
| `DB_NAME` | ConfigMap `app-config` | Nombre de la base del servicio |
| `DB_USER` | Secret `db-credentials` | Usuario de la base |
| `DB_PASSWORD` | Secret `db-credentials` | Contraseña de la base |
| `PORT` | ConfigMap o valor `5000` | Puerto Flask/Gunicorn |

Las comunicaciones entre servicios también leen variables:

| Servicio | Variable | Valor esperado |
|---|---|---|
| `pedidos` | `INVENTARIO_URL` | `http://inventario:5000` |
| `pedidos` | `CLIENTES_URL` | `http://clientes:5000` |
| `reportes` | `INVENTARIO_URL` | `http://inventario:5000` |
| `reportes` | `PEDIDOS_URL` | `http://pedidos:5000` |

`DB_PASSWORD` y las contraseñas del Secret nunca deben aparecer en este documento, en un manifiesto versionado ni en una captura sin ocultar.

## Cómo se inyecta la configuración

El Deployment de cada servicio debe usar el ConfigMap para lo no sensible y referencias puntuales al Secret para las credenciales. La forma recomendada para `inventario` es:

```yaml
envFrom:
  - configMapRef:
      name: app-config
env:
  - name: DB_NAME
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: INVENTARIO_DB
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: INVENTARIO_DB_USER
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: INVENTARIO_DB_PASSWORD
```

El bloque anterior debe estar en `k8s/21-inventario.yaml`, que integra el Área 3. Los nombres de Service coinciden con los nombres usados por el backend, por lo que Kubernetes resuelve `inventario`, `clientes` y `pedidos` mediante DNS interno.

## Verificación del criterio 7

Desde la VM, con el namespace seleccionado:

```bash
NS=proyecto-2-maximus
kubectl config set-context --current --namespace="$NS"
kubectl get configmap app-config -o yaml
kubectl get secret db-credentials
kubectl get deploy inventario
kubectl exec deploy/inventario -- sh -c 'env | sort | grep -E "^(DB_HOST|DB_PORT|DB_NAME|DB_USER|PORT)="'
kubectl logs deploy/inventario --tail=80
```

La captura de variables debe mostrar `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `PORT`, pero nunca `DB_PASSWORD`. Para demostrar que la contraseña existe sin revelarla:

```bash
kubectl exec deploy/inventario -- sh -c 'if [ -n "$DB_PASSWORD" ]; then echo DB_PASSWORD=SET; else echo DB_PASSWORD=MISSING; exit 1; fi'
```

La ausencia de errores de conexión en los logs y la respuesta `200` de la probe `/health` demuestran que el servicio recibió la configuración y conectó con PostgreSQL.

## Escalado declarativo de inventario

El escalado debe quedar registrado en el manifiesto, no ejecutarse únicamente con `kubectl scale`. En `k8s/21-inventario.yaml`, cambiar:

```yaml
spec:
  replicas: 1
```

a:

```yaml
spec:
  replicas: 3
```

Aplicar y verificar:

```bash
kubectl apply -f k8s/21-inventario.yaml
kubectl get deployment inventario
kubectl get pods -l app=inventario -o wide
kubectl get endpoints inventario
```

Resultado esperado:

```text
NAME         READY   UP-TO-DATE   AVAILABLE
inventario   3/3     3            3
```

El Service `inventario` debe mostrar tres endpoints. Las tres réplicas comparten la misma base `inventario_db`; la consistencia del stock no depende de memoria local del proceso, sino del bloqueo transaccional `SELECT ... FOR UPDATE` en PostgreSQL.

### Qué demuestra la evidencia de escalado

- El estado deseado está en el YAML.
- `kubectl apply` actualiza el Deployment.
- El ReplicaSet crea Pods hasta alcanzar tres réplicas.
- El Service mantiene endpoints para los Pods disponibles.
- El stock continúa protegido por la transacción de PostgreSQL aunque haya varias réplicas.

## Autoreparación

Un Deployment mantiene el número deseado de réplicas mediante su ReplicaSet. Si se elimina un Pod, Kubernetes crea otro automáticamente.

Terminal 1:

```bash
NS=proyecto-2-maximus
kubectl get pods -l app=inventario -n "$NS" -w
```

Terminal 2:

```bash
NS=proyecto-2-maximus
POD=$(kubectl get pods -l app=inventario -n "$NS" -o jsonpath='{.items[0].metadata.name}')
echo "Eliminando $POD"
kubectl delete pod "$POD" -n "$NS"
```

Verificar el ReplicaSet y los eventos:

```bash
kubectl get pods -l app=inventario -n "$NS"
kubectl get rs -l app=inventario -n "$NS"
kubectl describe rs -l app=inventario -n "$NS"
```

La evidencia debe mostrar el Pod antiguo en terminación y otro Pod con nombre diferente en `Running`. No se debe eliminar el Deployment: el Deployment es quien mantiene al ReplicaSet y al conjunto deseado de Pods.

## Dependencias de integración

Para aplicar esta parte se necesita que las otras áreas entreguen:

- **Área 3:** `k8s/21-inventario.yaml`, ConfigMap `app-config`, Secret `db-credentials`, imagen `keinaro/inventario:1.0` y el script de despliegue.
- **Área 4:** Service `db`, PVC y PostgreSQL con `inventario_db` disponible.
- **Área 2:** Gateway y Service que enruten `/api/inventario/` hacia `inventario:5000`.
- **Área 6:** frontend para probar el CRUD desde el navegador.

Mientras esos recursos no existan, se pueden revisar los manifiestos y usar `kubectl apply --dry-run=server`, pero no se puede demostrar el flujo completo desde el navegador.

## Preguntas para la defensa

### ¿Por qué el backend no cambia para Kubernetes?

Porque ya usa variables de entorno y nombres de servicio. Docker Compose y Kubernetes proporcionan esos valores con mecanismos distintos, pero la aplicación Flask conserva el mismo contrato.

### ¿Por qué `DB_USER` y `DB_PASSWORD` salen del Secret?

Son credenciales sensibles. El ConfigMap es apropiado para hosts, puertos y nombres de base; el Secret evita guardar las contraseñas directamente en el YAML de configuración.

### ¿Quién recrea un Pod eliminado?

El ReplicaSet asociado al Deployment observa que hay menos Pods que los declarados en `replicas` y crea uno nuevo. El Deployment administra el ReplicaSet.

### ¿Por qué usar `apply` y no solo `kubectl scale`?

Porque el requisito pide que el estado deseado quede versionado en el YAML. `kubectl apply` hace que el clúster coincida con el archivo que el equipo puede revisar y reproducir.

### ¿Qué protege el stock cuando hay tres réplicas?

La transacción de PostgreSQL con `SELECT ... FOR UPDATE`. El bloqueo vive en la base de datos, no en una variable del contenedor, así que funciona entre réplicas.
