# Checklist de evidencias personalizadas

El enunciado penaliza **−1 punto por cada evidencia ausente o no auténtica**
(hasta −4 sobre el total del grupo). Estas son las que dependen de
Infraestructura (Área 1); las de carné-en-BD y Docker Hub son de las Áreas 4
y 3 respectivamente, pero se listan todas para que el checklist sirva a todo
el equipo.

## Responsabilidad de Infraestructura (Área 1)

- [ ] **Hostname de la VM con identificador de grupo**, visible en la
      captura. Verificar con:
      ```bash
      hostnamectl
      ```
      Debe mostrar `srv-elquetzal-maximus` (X = número real de grupo, no el
      placeholder). Confirmar que `config/vm.conf` y el hostname puesto en el
      instalador de Ubuntu coincidan.

- [ ] **Reloj del sistema visible en las capturas.** Verificar zona horaria
      correcta (para que la hora mostrada tenga sentido en Guatemala,
      UTC-6):
      ```bash
      timedatectl
      ```
      Si no está en `America/Guatemala`:
      ```bash
      sudo timedatectl set-timezone America/Guatemala
      ```
      Para las capturas, correr `date` o dejar visible la barra de estado
      del terminal con hora, junto con el resto de la evidencia.

## Responsabilidad de otras áreas (para que no se les olvide)

- [ ] **Carné sembrado en la base de datos**, visible en la UI y en los
      pedidos (Área 4 siembra el dato, Área 5/6 lo muestran en pantalla).
- [ ] **URL del namespace del grupo en Docker Hub** con las imágenes
      publicadas (Área 3).

## Cómo generar la evidencia de infraestructura en un solo paso

`guest/02-verify-evidencias.sh` imprime, en orden, todo lo que hay que
capturar de esta área: hostname, fecha/hora, IP de cada adaptador, versión
de Docker Engine y de Compose, y estado del daemon. Correrlo y capturar la
pantalla completa de la terminal es la evidencia lista para el envío previo
al portal.
