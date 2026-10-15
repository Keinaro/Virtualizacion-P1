# Checklist contra la rúbrica (Área 1 — Infraestructura)

Referencia rápida de qué parte de la evaluación depende de este repo.

## Grupal — 14 pts

| Criterio | Pts | Qué aporta este repo |
|---|---|---|
| Arquitectura de microservicios funcional en la VM | 4 | La VM Ubuntu Server + Docker Engine + Compose instalados y verificados es el terreno donde corre todo lo demás. Sin esto no arranca nada. |
| Regla de negocio + persistencia verificada | 3 | Fuera del alcance de Infraestructura (Áreas 4 y 5), pero la VM debe sostener Postgres con volumen persistente sin caerse entre `docker compose down/up`. |
| Docker Hub + variables de entorno + red host↔VM | 2 | La mitad de red host↔VM es 100% de este repo (`docs/03-red-host-vm.md`). Docker Hub y variables de entorno de contenedor son de Áreas 3/4. |
| Documentación (diagrama, modelo de datos, mapa, evidencias) | 2 | `docs/00-sizing.md`, `docs/01-vm-setup.md`, `docs/03-red-host-vm.md`, `docs/04-evidencias.md` cubren la parte de infraestructura de esta documentación. |
| Anexo de costos | 2 | Fuera del alcance (Área 6). |
| Presentación (12 min) | 1 | Transversal. |

## Individual — 6 pts (lo tuyo en la defensa)

| Criterio | Pts | Cómo prepararlo |
|---|---|---|
| Dominio de tu área en la demo | 3 | Practicar: crear la VM desde cero con los scripts, instalar Docker por CLI, explicar el sizing y la red sin leer el documento. |
| Respuesta a la pregunta cruzada | 2 | El docente puede pedirte explicar el área de otro integrante — repasa al menos superficialmente qué hace el gateway (Área 2) y cómo se publican imágenes (Área 3), ya que son las más cercanas a infraestructura. |
| Comprensión del conjunto | 1 | Saber explicar cómo tu VM sostiene el resto de la arquitectura (gateway, microservicios, Postgres) end-to-end. |

## Pendiente antes de la entrega (jueves 24 de septiembre)

- [ ] Confirmar el número real de grupo y actualizar `config/vm.conf`,
      el hostname de la VM y las referencias `srv-elquetzal-maximus` en
      todos los docs.
- [ ] Correr `host/00-disable-hyperv.ps1` (admin + reinicio) antes de crear
      la VM definitiva.
- [ ] Crear la VM con `host/01-create-vm.ps1` e instalar Ubuntu Server.
- [ ] Instalar Docker Engine + Compose con `guest/01-install-docker.sh`.
- [ ] Correr `guest/02-verify-evidencias.sh` y guardar la captura.
- [ ] Coordinar con Área 3 (Orquestación) para probar el `docker-compose.yml`
      completo sobre esta VM en cuanto el equipo tenga el código.
- [ ] Hacer un snapshot de VirtualBox de la VM ya funcionando, antes de la
      defensa en vivo (respaldo si algo se rompe en el demo).
