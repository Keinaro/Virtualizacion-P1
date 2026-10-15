# El Quetzal — Proyecto 2: Migración a Kubernetes

Tienda de artesanías guatemaltecas desplegada como microservicios. La misma
aplicación del Proyecto 1, ahora orquestada con **k3s** dentro de la VM
`srv-elquetzal-maximus`.
Virtualización — Ingeniería en Informática y Sistemas, Universidad Rafael Landívar.

**Equipo:** `maximus` · **Namespace:** `proyecto-2-maximus`

> Kubernetes no acepta guiones bajos en nombres de namespace, así que
> `proyecto_2_maximus` (carpeta y repositorio) se escribe `proyecto-2-maximus`
> como namespace.
>
> Repositorio: `Keinaro/proyecto_2_maximus`. Es el mismo repositorio del
> Proyecto 1 (antes `Virtualizacion-P1`), renombrado; GitHub redirige el
> nombre anterior.

## Cómo ejecutar (dentro de la VM)

```bash
git clone https://github.com/Keinaro/proyecto_2_maximus.git && cd proyecto_2_maximus
cp .env.example .env && nano .env        # contraseñas reales; .env no se versiona
./scripts/crear-secret.sh .env           # crea el Secret db-credentials en el clúster
./scripts/deploy.sh                      # aplica todo en orden y espera cada capa
kubectl get all -n proyecto-2-maximus
```

Desde el navegador del host:

- NodePort: `http://192.168.56.10:30080`
- LoadBalancer: `http://192.168.56.10:8080`
- Respaldo si falla la red: `kubectl port-forward svc/gateway 8088:80 --address 0.0.0.0 -n proyecto-2-maximus`

Antes de calificar, el stack de Compose del Proyecto 1 tiene que estar abajo
(`docker compose down`, **sin** `-v`).

## Arquitectura

```text
navegador ─► NodePort 30080 / LoadBalancer 8080
                     │
                gateway (nginx, 2 réplicas)
               ┌─────┴───────────────────────┐
           /   │                     /api/<servicio>/
               ▼                             ▼
        frontend (Vue)        catalogo · inventario · clientes · pedidos · reportes
                                             │  (Flask, puerto 5000)
                                             ▼
                                db (Postgres 16 + PVC, una base por servicio)
```

Todo vive en el namespace `proyecto-2-maximus`. Solo el gateway se expone
fuera del clúster; el backend y la base son ClusterIP.

## Estructura

```text
proyecto_2_maximus/
├── backend/            5 microservicios Flask (código del Proyecto 1, sin cambios)
├── frontend/           Vue 3 + Dockerfile propio (sale del gateway)
├── db/                 init, schemas y seeds (se montan en el Pod de Postgres)
├── k8s/
│   ├── 00-namespace.yaml               Daniel
│   ├── 01-configmap.yaml               Jorge
│   ├── 10-postgres-pvc.yaml            Julio
│   ├── 11-postgres.yaml                Julio
│   ├── 12-postgres-svc.yaml            Julio
│   ├── 13-db-scripts.yaml              Julio
│   ├── 20-catalogo.yaml … 24-reportes.yaml   Jorge (21 lo edita Sofía para escalar)
│   ├── 30-frontend.yaml                Ana Lucía
│   ├── 40-gateway-conf.yaml            Giancarlo
│   ├── 41-gateway.yaml                 Giancarlo
│   ├── 42-gateway-svc.yaml             Giancarlo
│   └── plantillas/
│       └── 02-secret.example.yaml      Jorge (solo claves; el Secret real NO se sube)
├── scripts/            deploy.sh, crear-secret.sh, backup.sh, demo-ciclo-vida.sh
├── docs/               orquestacion-k8s.md (traducción Compose → K8s) y docs del Proyecto 1
├── evidencias/         PDF de evidencias
└── docker-compose.yml  despliegue del Proyecto 1, se conserva como referencia de la traducción
```

## Contrato de nombres

| Elemento | Valor |
|---|---|
| Namespace | `proyecto-2-maximus` |
| Base de datos | Service `db`, puerto 5432, `postgres:16-alpine` |
| Backend | Services `catalogo`, `inventario`, `clientes`, `pedidos`, `reportes` en 5000; imágenes `keinaro/<servicio>:1.0` |
| Frontend | Service `frontend`, puerto 80; imagen `keinaro/frontend:1.0` |
| Gateway | `nginx:1.27-alpine` + ConfigMap; Services `gateway` (ClusterIP 80), `gateway-nodeport` (30080), `gateway-lb` (LoadBalancer 8080) |
| ConfigMap | `app-config`: `DB_HOST`, `DB_PORT`, los 5 nombres de base y las URLs internas |
| Secret | `db-credentials`: superusuario y usuario/contraseña de cada servicio |
| Labels | `app: <nombre>` y `equipo: maximus` en todo recurso |

Los Services se llaman igual que los servicios del compose: ni el código Flask
ni las llamadas entre servicios cambian. Detalle de cada decisión en
[`docs/orquestacion-k8s.md`](docs/orquestacion-k8s.md).

## Áreas y responsables

| Área | Tema | Responsable |
|---|---|---|
| 1 | VM, k3s, red y namespace | Daniel Paz |
| 2 | Gateway y los tres tipos de Service | Giancarlo |
| 3 | Repo, ConfigMap, Secret, Deployments del backend, integración | Jorge Muñoz |
| 4 | Postgres, PVC y persistencia | Julio |
| 5 | Conexión por variables, escalado y autoreparación | Sofía |
| 6 | Frontend en Kubernetes y PDF de evidencias | Ana Lucía |

## Reglas de trabajo

- Cada quien trabaja en `dev/<nombre>` y abre PR a `develop`. Jorge revisa
  contra el contrato de nombres y hace merge; `develop` pasa a `main` el
  miércoles 14 en la noche.
- **Nunca** commitear `.env`, `.env.secrets` ni un Secret real. Si uno se sube,
  cambiar las contraseñas: borrar el commit no lo saca del historial.
- Todo recurso lleva `namespace: proyecto-2-maximus`; nada en `default`.
- Escalar editando `replicas` en el YAML y aplicando; nunca `kubectl scale`.
- Tags fijos (`1.0`), nunca `latest`.
- Validar antes de aplicar: `kubectl apply -f k8s/ --dry-run=server`.
- **Nunca** `kubectl delete namespace proyecto-2-maximus` en la VM de la demo:
  borra el PVC y los datos.
- Capturas con el **reloj del sistema** visible y sin contraseñas.

## Proyecto 1

La documentación del despliegue con Docker Compose y de la VM sigue en
`docs/`: [`orquestacion.md`](docs/orquestacion.md),
[`arquitectura.md`](docs/arquitectura.md),
[`modelo-datos.md`](docs/modelo-datos.md) y los documentos `00`–`05` del
Área 1. Los scripts de creación de la VM están en `host/`, `guest/` y
`config/`.
