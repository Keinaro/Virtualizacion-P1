# Mapa de Propiedad — Proyecto 1: El Quetzal sobre infraestructura virtualizada
### Grupo de 6 integrantes — Virtualización, Ingeniería en Informática y Sistemas, URL

Cada integrante es dueño documentado de un área y debe poder defenderla individualmente en la presentación (12 min, pregunta cruzada incluida). Con 6 personas, **ninguna área se fusiona** — cada quien lleva exactamente una de las 6 del enunciado.

---

## Área 1 — Infraestructura (VM, Linux, Docker Engine, red host↔VM)

**Responsable:** Daniel Paz. Implementación real (VM ya provisionada, hostname
`srv-elquetzal-maximus`, Docker instalado) documentada en
[`docs/00-sizing.md`](00-sizing.md) a [`docs/05-checklist-entrega.md`](05-checklist-entrega.md)
y en `host/`, `guest/`, `config/vm.conf`. La guía genérica de esta sección se
deja para referencia.

**Responsabilidad:** que exista una VM Ubuntu Server funcional, bien dimensionada, con Docker instalado y accesible desde el navegador del host.

### Tareas específicas
1. **Dimensionar la VM** antes de crearla: definir CPU/RAM/disco justificando la carga (5 microservicios Flask + Postgres + gateway + build de Vue). Documentar el razonamiento (igual que el ejercicio de Semana 3 — matriz de asignación con 3 líneas de justificación).
2. **Instalar VirtualBox** en el host (si el grupo no lo tiene) y crear la VM con Ubuntu Server (no Desktop) — instalación **headless**, sin entorno gráfico.
3. **Configurar hostname** de la VM con identificador del grupo, ej. `srv-elquetzal-grupo-X`.
4. **Instalar Docker Engine + Docker Compose** en el guest **por línea de comandos** (no GUI, no Docker Desktop).
5. **Configurar la red host↔VM**: Bridge o Host-Only + reenvío de puertos, de modo que el navegador del host abra la app corriendo en la VM.
6. Entregar evidencia con capturas donde se vea el **reloj del sistema**.

### Instalación paso a paso (para quien se está metiendo a esto por primera vez)

**1. Instalar VirtualBox en el host**
```bash
# Windows/Mac: descargar el instalador desde
https://www.virtualbox.org/wiki/Downloads
# Linux (Ubuntu/Debian host):
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack -y
```

**2. Descargar la ISO de Ubuntu Server (LTS, ej. 24.04)**
```
https://ubuntu.com/download/server
```

**3. Crear la VM en VirtualBox**
- Nuevo → Nombre: `srv-elquetzal-grupo-X` → Tipo: Linux → Versión: Ubuntu (64-bit)
- Memoria: según dimensionamiento (mínimo sugerido 4 GB para correr Postgres + 5 servicios Flask + gateway; ideal 6-8 GB si el host lo permite)
- Disco: crear disco virtual VDI, reservado dinámicamente, mínimo 25-30 GB
- CPU: 2 núcleos mínimo (4 si el host lo permite)
- Red: primero NAT para instalar, luego se agrega un segundo adaptador **Host-Only** o se cambia a **Bridge** (ver paso 5)

**4. Instalar Ubuntu Server (headless)**
- Montar la ISO, arrancar la VM, seguir el instalador de texto
- Durante la instalación: definir hostname como `srv-elquetzal-grupo-X`, crear usuario, **activar OpenSSH server** (fundamental para administrarla sin interfaz gráfica)
- Al terminar, quitar la ISO montada y reiniciar

**5. Configurar red host↔VM**
- Opción A (Bridge): Configuración de la VM → Red → Adaptador 1 → "Adaptador puente" — la VM obtiene IP en la misma red que el host, más simple para exponer servicios.
- Opción B (Host-Only + reenvío de puertos): agregar un adaptador Host-Only, y en NAT configurar reglas de reenvío de puertos (ej. host `8080` → VM `80`) desde Configuración → Red → Adaptador NAT → Avanzado → Reenvío de puertos.
- Verificar conectividad: `ip a` dentro de la VM para confirmar la IP asignada, luego `ping` desde el host.

**6. Instalar Docker Engine + Compose (línea de comandos, guía oficial)**
```bash
sudo apt update
sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Permitir usar docker sin sudo
sudo usermod -aG docker $USER
newgrp docker

# Verificar
docker --version
docker compose version
docker run hello-world
```

### Mejores prácticas
- No usar `root` para trabajar día a día; usuario con `sudo` y grupo `docker`.
- Documentar la IP/hostname final de la VM y cómo se accede (SSH + puerto reenviado) para que el resto del equipo no dependa de una sola persona.
- Mantener el sistema actualizado (`sudo apt update && sudo apt upgrade`) antes de la demo.
- Guardar el archivo `.ova`/snapshot de la VM como respaldo antes de la presentación en vivo.

---

## Área 2 — Gateway y redes Docker (nginx)

**Responsabilidad:** que exista una puerta única (nginx) que sirva el frontend y enrute las llamadas a cada microservicio, sobre una red interna de Docker con descubrimiento por nombre.

### Tareas específicas
1. Escribir el `nginx.conf` (o `default.conf`) que:
   - Sirve el build estático de Vue en `/`.
   - Enruta `/api/catalogo/` → servicio `catalogo`, `/api/inventario/` → servicio `inventario`, y así con `clientes`, `pedidos`, `reportes`.
2. Crear la **red interna de Docker** (bridge definida en el `docker-compose.yml`) para que los contenedores se resuelvan por nombre de servicio (ej. `http://inventario:5000`), sin exponer cada microservicio directamente al host.
3. Construir la imagen del gateway (`Dockerfile` con nginx + config copiada).
4. Validar que **solo el gateway** publique puerto hacia el host (los microservicios y Postgres quedan solo en la red interna).

### Mejores prácticas
- Usar `location /api/<servicio>/ { proxy_pass http://<servicio>:<puerto>/; }` con el nombre del servicio tal cual está en `docker-compose.yml` — Docker resuelve DNS interno automáticamente.
- Agregar `proxy_set_header Host $host;` y headers estándar de proxy para que las apps backend vean la petición real.
- Nunca hardcodear IPs; siempre nombre de servicio.
- Probar cada ruta con `curl` dentro de la red antes de probarlo desde el navegador, para aislar problemas de nginx vs problemas de red.
- Documentar el mapa de rutas (tabla: ruta pública → servicio → puerto interno) para el documento de arquitectura.

---

## Área 3 — Orquestación y publicación (Compose, Dockerfiles, Docker Hub)

**Responsabilidad:** que todo el stack levante con `docker compose up`, que las imágenes propias estén bien construidas, etiquetadas y publicadas en el Docker Hub del grupo, y que no haya secretos quemados en el código.

### Tareas específicas
1. Escribir el `docker-compose.yml` maestro: todos los servicios (gateway, 5 microservicios Flask, Postgres), red interna, volumen nombrado para Postgres, variables de entorno vía `.env` o `environment:`.
2. Escribir/revisar los `Dockerfile` de cada microservicio (junto con el dueño de backend) siguiendo buenas prácticas de build.
3. Definir y documentar las **variables de entorno** (credenciales de DB, URLs internas) — cero secretos quemados en código; usar `.env` (con `.env.example` versionado, `.env` real fuera de git).
4. Construir y etiquetar imágenes propias (`docker build -t usuariogrupo/servicio:tag .`) y publicarlas al Docker Hub del grupo (`docker push`).
5. Confirmar que `docker compose down && docker compose up` conserva los datos (persistencia por volumen).

### Instalación / cuenta necesaria
```bash
# Crear cuenta de equipo en https://hub.docker.com si no existe
docker login
docker build -t <usuario-docker-hub>/inventario:1.0 ./inventario
docker push <usuario-docker-hub>/inventario:1.0
```

### Mejores prácticas
- Dockerfiles con imagen base ligera (`python:3.12-slim`), `WORKDIR`, copiar solo `requirements.txt` antes del código para aprovechar caché de capas, y usuario no-root cuando sea posible.
- `.dockerignore` para no copiar `venv/`, `__pycache__/`, `.git/` a la imagen.
- Etiquetas semánticas (no solo `latest`) para poder rastrear qué versión corre en la demo.
- `docker-compose.yml` con `depends_on` + healthchecks para que los microservicios no arranquen antes que Postgres esté listo.
- Nunca commitear `.env` real; sí commitear `.env.example`.

---

## Área 4 — Datos (Postgres, esquema por servicio, seeds)

**Responsabilidad:** que exista una base de datos independiente por microservicio (mismo motor Postgres, distinto usuario/esquema), con datos semilla que incluyan los carnés del equipo.

### Tareas específicas
1. Definir el modelo de datos por servicio (`catalogo`, `inventario`, `clientes`, `pedidos`, `reportes`) — tablas, relaciones, tipos.
2. Crear un usuario y base de datos por microservicio dentro del mismo motor Postgres (aislamiento lógico).
3. Escribir los scripts de **seed** (datos iniciales), incluyendo los carnés de los integrantes sembrados en la BD y visibles luego en la UI/pedidos.
4. Configurar el **volumen nombrado** de Docker para que los datos persistan entre `down`/`up`.
5. Documentar el modelo de datos (diagrama ER o similar) para el documento de arquitectura.

### Mejores prácticas
- Un usuario de DB por microservicio con permisos acotados solo a su propia base (principio de menor privilegio).
- Scripts de inicialización idempotentes (que se puedan correr más de una vez sin romper nada).
- Nombrar claramente el volumen (`elquetzal_pgdata`) para identificarlo fácilmente en `docker volume ls`.
- Probar la persistencia explícitamente antes de la demo: `docker compose down` (sin `-v`) y `docker compose up`, confirmar que los datos siguen ahí.

---

## Área 5 — Backend de dominio (microservicios Flask + regla de negocio)

**Responsabilidad:** implementar los 5 microservicios Flask (`catalogo`, `inventario`, `clientes`, `pedidos`, `reportes`) y la regla de negocio crítica: descuento de stock atómico al confirmar un pedido.

### Tareas específicas
1. Implementar endpoints REST de cada microservicio (CRUD de inventario: listar, crear, editar, eliminar productos con SKU, nombre, categoría, precio, stock).
2. Implementar `pedidos`: crear pedido con productos y cantidades, **validar stock disponible**, rechazar si algún producto no alcanza, y si es válido, **descontar el inventario en una transacción atómica** (todo o nada).
3. El pedido debe registrar el carné del integrante que lo creó.
4. Construir la lógica de `reportes` (resuelta por el grupo, sin ejemplo dado).
5. Conectar cada microservicio a su propia base de datos vía variables de entorno.

### Mejores prácticas
- Usar transacciones de base de datos (`BEGIN`/`COMMIT`/`ROLLBACK`, o el manejo transaccional del ORM) para el descuento de stock — nunca hacer el check de stock y el update como pasos separados sin transacción (condición de carrera).
- Separar capa de rutas / lógica de negocio / acceso a datos, aunque sea un microservicio pequeño (facilita la defensa individual y el debugging).
- Validar entradas (cantidades negativas, productos inexistentes) y devolver códigos HTTP apropiados (400, 404, 409 para conflicto de stock).
- Escribir al menos pruebas manuales documentadas (con `curl` o Postman) para el flujo de pedido, para poder demostrarlo rápido en los 12 minutos de defensa.

---

## Área 6 — Frontend + costos (Vue + anexo de costos)

**Responsabilidad:** construir el frontend Vue (inventario, pedidos, dashboard) servido por el gateway, y el anexo de costos CAPEX vs OPEX.

### Tareas específicas
1. Construir la app Vue con 3 vistas: **inventario** (listar/crear/editar/eliminar productos), **pedidos** (crear pedido, ver historial con carné visible), **dashboard** (total de productos, valor total del inventario en Q, pedidos del día, alerta de stock bajo).
2. Consumir la API a través del gateway (`/api/<servicio>/...`), nunca llamando directo a los microservicios.
3. Generar el **build real** de producción (`npm run build`) para que nginx lo sirva como estático — no correr el dev server en la demo.
4. Elaborar el **anexo de costos**: comparativo CAPEX vs OPEX en quetzales (infraestructura tradicional vs contenedores), con beneficios operativos y de escalabilidad para El Quetzal (las herramientas se entregan el jueves 3 de septiembre).

### Mejores prácticas
- Manejar estados de carga y error en las llamadas a la API (spinner, mensajes de error legibles), no solo el "happy path".
- Centralizar la URL base de la API en una sola constante/config, para que cambiar de entorno (dev → VM) sea un solo cambio.
- Diseño simple y funcional; priorizar que los flujos funcionen sobre estética elaborada, dado el tiempo del proyecto.
- Para el anexo de costos: usar cifras realistas y justificadas (licencias, hardware, mantenimiento vs consumo de nube/contenedores), no solo estimaciones sin sustento.

---

## Coordinación entre roles (dependencias clave)

| De → Hacia | Qué necesita el que recibe |
|---|---|
| Área 1 → todos | VM lista con Docker instalado y accesible antes de que el resto pueda desplegar nada |
| Área 5 → Área 2 | Nombre de puerto interno de cada microservicio, para las rutas del gateway |
| Área 4 → Área 5 | Esquema y credenciales de cada base para que el backend conecte |
| Área 5 → Área 6 | Contratos de API (endpoints, formato de request/response) definidos temprano |
| Área 3 → todos | `docker-compose.yml` como "contrato" de nombres de servicios/puertos que todos deben respetar |

**Recomendación de buena práctica de equipo:** definir el contrato de nombres de servicios y puertos (Área 3) y el contrato de endpoints de API (Área 5) en la primera semana, por escrito, antes de que cada quien empiece a codear en paralelo — evita retrabajo de integración al final.

## Checklist de evidencia personalizada (obligatoria, penalización si falta)
- [ ] Carnés sembrados en la BD, visibles en UI y en pedidos (Área 4 + 5 + 6)
- [ ] Hostname de la VM con identificador del grupo, visible en capturas (Área 1)
- [ ] URL del namespace del grupo en Docker Hub con imágenes publicadas (Área 3)
- [ ] Capturas con el reloj del sistema visible (todos, al documentar)
