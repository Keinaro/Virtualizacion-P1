# Configuración de la VM — paso a paso

## Estado verificado en este equipo

- VirtualBox **7.2.18** instalado (`VBoxManage.exe --version` → `7.2.18r175117`).
- Extension Pack instalado en **7.2.12** (desfase menor de parche frente al
  core 7.2.18). No es bloqueante para este proyecto — no usamos PXE ni las
  funciones de Oracle Cloud del extpack — pero si más adelante da warnings
  de versión, actualízalo desde *File → Preferences → Extensions* con el
  paquete que coincida con la versión exacta de VirtualBox instalada.
- Drivers de kernel (`vboxsup`, `VBoxNetLwf`, `VBoxUSBMon`, `vboxnetadp`,
  `vboxnetlwf`) en estado `RUNNING`.
- Adaptador **Host-Only** ya existente: `VirtualBox Host-Only Ethernet
  Adapter` en `192.168.56.1/24` (se generó solo al instalar VirtualBox).
- ISO ya descargada: `ubuntu-22.04.5-live-server-amd64.iso` (LTS, soporte
  hasta 2027).

## 0. Liberar VT-x (recomendado antes de crear la VM)

Windows tenía Hyper-V/WSL2 activos (por Docker Desktop), lo que hace que
VirtualBox corra en modo paravirtualizado sobre Hyper-V: más lento y con
riesgo de que la VM no arranque el día de la defensa. El enunciado prohíbe
usar Docker Desktop del host de todas formas, así que no perdemos nada.

```powershell
# PowerShell como Administrador, luego reiniciar
.\host\00-disable-hyperv.ps1
```

Para revertirlo más adelante (si vuelves a necesitar Docker Desktop u otra
VM de Hyper-V): `host\00b-enable-hyperv.ps1`.

## 1. Crear la VM

Edita primero `config/vm.conf` (número de grupo real, y confirma el carné).
Luego, en PowerShell (no necesita admin para esto):

```powershell
.\host\01-create-vm.ps1
```

Esto usa `VBoxManage` para:
- Crear la VM `srv-elquetzal-maximus` tipo Ubuntu64, headless.
- Asignar 2 vCPU / 4096 MB RAM (ver `00-sizing.md`).
- Crear un disco de 25 GB (VDI, dinámico).
- Adjuntar la ISO de Ubuntu 22.04.5 al lector virtual.
- Configurar Adaptador 1 = NAT con reenvío de puertos (SSH 2222→22, HTTP
  8090→80) y Adaptador 2 = Host-Only (`192.168.56.x`) — ver
  `03-red-host-vm.md` para el porqué.
- Habilitar el arranque en modo headless (sin ventana de VirtualBox).

## 2. Instalar Ubuntu Server 22.04.5

La primera vez sí hace falta la consola gráfica para el instalador:

```powershell
& "C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe" --startvm "srv-elquetzal-maximus"
```

En el instalador (Subiquity):
- Idioma/teclado: el que prefieras.
- Red: deja el adaptador NAT (enp0s3) con DHCP; el Host-Only (enp0s8) también
  por DHCP — VirtualBox trae su propio DHCP para la red Host-Only.
- Disco: usar todo el disco (los 25 GB asignados). El instalador ofrece
  configurarlo como grupo LVM — déjalo marcado, pero revisa el resumen antes
  de confirmar: por defecto solo asigna la mitad del disco al filesystem raíz
  y deja el resto como espacio libre sin usar dentro del grupo de volúmenes.
  Si pasa eso, después de instalar hay que extenderlo:
  ```bash
  sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
  sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
  ```
- **Nombre del host: `srv-elquetzal-maximus`** — esta es una de las
  evidencias personalizadas obligatorias del enunciado, tiene que aparecer
  en las capturas.
- Usuario: crea un usuario normal (ej. `ubuntu`) con contraseña — lo usarás
  por SSH, no hace falta root directo.
- **Instalar el servidor OpenSSH** cuando el instalador lo pregunte (checkbox
  "Install OpenSSH server") — sin esto no podrás entrar por SSH después.
- No selecciones snaps de servidor adicionales (Docker se instala aparte, a
  mano, para controlar la versión — ver `02-docker-install.md`).

Al terminar, la VM reinicia. Quita la ISO del lector virtual (VirtualBox lo
sugiere automáticamente, o hazlo manual: *Configuración → Almacenamiento →
quitar el disco óptico*).

## 3. Confirmar acceso por SSH desde el host

Con la VM encendida (puede quedar en headless desde ahora):

```powershell
ssh -p 2222 ubuntu@127.0.0.1
```

Si conecta, la VM y el reenvío de puertos están funcionando. A partir de acá,
todo el trabajo dentro del guest se hace por SSH — no hace falta abrir la
ventana de VirtualBox de nuevo salvo para depurar arranque.

## 4. Correr en modo headless de forma permanente

```powershell
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "srv-elquetzal-maximus" --type headless
```

(`host/01-create-vm.ps1` deja esto documentado también en su salida final.)
