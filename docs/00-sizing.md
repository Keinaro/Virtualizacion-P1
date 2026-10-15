# Sizing de la VM — justificación

## Carga de trabajo esperada

Dentro de la VM corre, vía Docker Compose:

| Componente | Naturaleza | RAM aprox. en reposo |
|---|---|---|
| gateway (nginx) | proxy inverso + estáticos de Vue | ~15–25 MB |
| 5 microservicios Flask | dev server (catalogo, inventario, clientes, pedidos, reportes) | ~80–150 MB c/u → 400–750 MB |
| Postgres (1 motor, 5 BD) | shared_buffers + conexiones de una demo | ~150–300 MB |
| Frontend Vue | build estático servido por nginx, **sin runtime propio** | 0 MB adicional |
| Docker Engine + daemon | overhead del propio motor | ~100–150 MB |
| Ubuntu Server headless | SO base sin entorno gráfico | ~300–400 MB |

**Total activo estimado: ~1.0–1.6 GB.** Es carga de demo (una sesión de 12
minutos con tráfico de 1–2 usuarios concurrentes), no tráfico de producción:
no hay que dimensionar para picos reales de Distribuidora El Quetzal, sino
para que la demo corra fluida y estable.

## Decisión de sizing

| Recurso | Asignado | Justificación |
|---|---|---|
| **CPU** | 2 vCPU | El host tiene 10 núcleos / 16 hilos. La carga es I/O-bound (requests HTTP cortos, queries simples), no CPU-bound — 2 vCPU alcanza sin contención y deja margen para picos de arranque (todos los contenedores levantando a la vez). Más vCPU no acelera un workload que no está limitado por cómputo. |
| **RAM** | 4096 MB (4 GB) | Cubre el estimado de ~1.6 GB activo con margen amplio (~2.5×) para: caché de página de Linux, buffers de Postgres bajo carga de la demo, y que `apt`/`docker build` no se queden sin memoria durante el setup. El host tiene 15.7 GB — 4 GB deja ~11 GB libres para Windows, el IDE y el navegador durante la defensa. |
| **Disco** | 25 GB (dinámico) | Ubuntu Server base (~3–4 GB) + imágenes Docker propias con bases slim (nginx, python:slim, postgres) + logs + paquetes ≈ 8–10 GB reales. 25 GB dinámico da holgura para snapshots de VirtualBox (útiles antes de la demo) sin comprometer los 92 GB libres del host. |
| **Red** | 2 adaptadores (NAT + Host-Only) | Ver `03-red-host-vm.md`. |
| **Modo** | Headless | El enunciado lo exige; sin overhead de escritorio gráfico, se administra por SSH. |

## Notas de la máquina host usada

- CPU: Intel Core i7-13620H (10 núcleos / 16 hilos), soporta VT-x.
- RAM total: 15.7 GB.
- Disco C: 92 GB libres al momento de planear esto.
- VirtualBox 7.2.18 instalado y verificado (`VBoxManage --version`).
- Hyper-V/WSL2 estaban activos y se desactivan con `host/00-disable-hyperv.ps1`
  para que VirtualBox use VT-x nativo (`unrestricted guest` pasa de `no` a
  `yes`, mejor rendimiento y compatibilidad).

Si el sizing resulta corto durante las pruebas (swapping, contenedores que
mueren por OOM), subir primero RAM a 6 GB antes que CPU — el cuello de
botella más probable en una demo con todos los servicios activos a la vez es
memoria, no cómputo.
