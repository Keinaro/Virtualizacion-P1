# Red host ↔ VM

El enunciado pide explícitamente: *"Red host ↔ VM configurada por el grupo
(Bridge o Host-Only + reenvío) para que el navegador del host abra la app
que corre en la VM."* Usamos **las dos**, cada una para lo que sirve mejor,
en vez de forzar una sola:

## Adaptador 1 — NAT con reenvío de puertos (uso principal)

La laptop se mueve entre redes (casa, universidad) con DHCP y políticas de
red distintas cada vez. Un adaptador **Bridged** puro dependería de que esa
red asigne IP a la VM y permita tráfico cliente-a-cliente — en redes de
campus con aislamiento de clientes (client isolation / 802.1X), esto suele
fallar justo el día que más importa.

Con **NAT + reenvío de puertos**, la VM siempre es alcanzable desde el host
en `127.0.0.1`, sin importar en qué red física esté la laptop:

| Puerto host | Puerto VM | Servicio |
|---|---|---|
| 2222 | 22 | SSH |
| 8080 | 80 | Gateway nginx (la app) |

Configurado por `host/01-create-vm.ps1`:

```powershell
VBoxManage modifyvm "srv-elquetzal-maximus" --natpf1 "ssh,tcp,127.0.0.1,2222,,22"
VBoxManage modifyvm "srv-elquetzal-maximus" --natpf1 "http,tcp,127.0.0.1,8080,,80"
```

El navegador del host abre `http://127.0.0.1:8080` y llega al gateway nginx
de la VM. Este es el modo a usar **en la defensa**, porque no depende de la
red del salón.

## Adaptador 2 — Host-Only (acceso directo, desarrollo)

VirtualBox ya trae creado `VirtualBox Host-Only Ethernet Adapter` en
`192.168.56.1/24` (lo generó la propia instalación). Lo usamos como segundo
adaptador de la VM para:

- SSH directo sin recordar el puerto reenviado: `ssh ubuntu@192.168.56.10`
  (IP fija que le asignamos, ver más abajo).
- Acceder a Postgres o a un microservicio individual durante el desarrollo
  sin tener que abrir un `natpf` nuevo por cada puerto que se prueba.
- Es el adaptador que satisface literalmente "Host-Only" del enunciado,
  como alternativa/complemento documentado al NAT+reenvío.

Para fijar la IP dentro del guest (Netplan, Ubuntu Server), edita
`/etc/netplan/50-cloud-init.yaml` o el archivo que exista y agrega el
segundo adaptador (`enp0s8` normalmente) con:

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      addresses: [192.168.56.10/24]
```

```bash
sudo netplan apply
```

## Bridge — alternativa si el equipo prefiere una sola red física

Si el grupo decide demostrar todo desde una red controlada (ej. el mismo
router en el salón, sin aislamiento de clientes), la alternativa más simple
es cambiar el Adaptador 1 a **Bridged** apuntando al adaptador Wi-Fi o
Ethernet físico del host:

```powershell
VBoxManage modifyvm "srv-elquetzal-maximus" --nic1 bridged --bridgeadapter1 "Intel(R) Wi-Fi 6 AX201 160MHz"
```

La VM obtiene entonces una IP en la misma red que el host (visible con
`ip a` dentro del guest) y el navegador del host la usa directo, sin
reenvío. **No es la opción por defecto de este repo** porque depende de la
red física del momento; queda documentada para poder cambiar en minutos si
hace falta el día de la defensa.

## Recomendación para la demo

Usar NAT + reenvío (`127.0.0.1:8080`) como plan principal — funciona igual
en casa, en la universidad o en cualquier red donde se conecte la laptop —
y tener Host-Only como respaldo para depuración directa por SSH.
