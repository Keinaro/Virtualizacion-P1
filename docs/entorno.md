# Entorno del Proyecto 2: VM y k3s

Todo corre en una sola VM, `srv-elquetzal-maximus`, la misma del Proyecto 1: Ubuntu Server 22.04.5, 2 vCPU, 4 GB de RAM y 23 GB de disco. Vive en la laptop de Daniel y solo esa laptop llega a ella, así que los manifiestos se aplican desde ahí.

## Red

La VM tiene dos adaptadores. El NAT (`enp0s3`, 10.0.2.15) reenvía el SSH al host (2222 → 22). El Host-Only (`enp0s8`) tiene la IP fija 192.168.56.10, y es la que usan k3s y el navegador del host.

En el Proyecto 1 esa IP la daba el DHCP de VirtualBox (salió 192.168.56.103), así que hubo que fijarla. Se hizo con un archivo propio en lugar de editar el de cloud-init, que se regenera en cada arranque:

```yaml
# /etc/netplan/60-hostonly.yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses: [192.168.56.10/24]
```

Como respaldo, por si el Host-Only falla el día de la calificación, en VirtualBox hay dos reenvíos NAT: host 8091 → VM 30080 (NodePort) y host 8092 → VM 8080 (LoadBalancer). El 8080 del host está ocupado por otro servicio de la laptop, por eso no se usa ese número.

## k3s

Se instaló con el script oficial (`get.k3s.io`), versión v1.36.5+k3s1 y configuración por defecto, es decir con Traefik y ServiceLB, porque el LoadBalancer del criterio 11 depende de ServiceLB. Antes de instalar se escribió `/etc/rancher/k3s/config.yaml`:

```yaml
node-ip: 192.168.56.10
node-external-ip: 192.168.56.10
flannel-iface: enp0s8
```

Sin eso k3s toma la IP de la interfaz NAT (10.0.2.15), que el host no alcanza, y el `EXTERNAL-IP` del LoadBalancer saldría con una IP inútil para entrar desde el navegador. ServiceLB publica los puertos en la IP del nodo, por eso hay que fijarla.

Traefik ocupa los puertos 80 y 443 de la VM. El LoadBalancer del gateway va en 8080 para no quedarse en `<pending>`.

Para usar `kubectl` sin sudo se copió `/etc/rancher/k3s/k3s.yaml` a `~/.kube/config` y se exportó `KUBECONFIG` en el `.bashrc`. El `kubectl` que instala k3s ignora `~/.kube/config` si la variable no está, porque por defecto lee un archivo que solo puede leer root.

El stack de Compose del Proyecto 1 se bajó con `docker compose down` (sin `-v`, el volumen `elquetzal_pgdata` sigue ahí) porque su gateway usaba el puerto 80.

## Namespace

`k8s/00-namespace.yaml` crea `proyecto-2-maximus`. Todo lo demás lleva `namespace: proyecto-2-maximus` en el YAML y nada se aplica en `default`.

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl get ns proyecto-2-maximus
```

## Desplegar en la VM

```bash
cd ~/Virtualizacion-P1 && git pull
./scripts/crear-secret.sh .env     # una sola vez, con el .env real (no está en el repo)
./scripts/deploy.sh
```

## Comprobar el entorno

```bash
kubectl get nodes -o wide     # Ready, INTERNAL-IP y EXTERNAL-IP = 192.168.56.10
kubectl cluster-info
kubectl get storageclass      # local-path (default)
kubectl get all -n proyecto-2-maximus
```

## Memoria

Con k3s solo, sin la aplicación, la VM (3.8 GB útiles) tiene unos 2.6 GB disponibles. Después de desplegar todo conviene correr `free -h` y `kubectl top nodes`; si quedan menos de 500 MB libres, apagar la VM y subirla a 6 GB en VirtualBox (Configuración → Sistema).
