<#
.SYNOPSIS
  Crea la VM de El Quetzal en VirtualBox (headless) con el sizing
  documentado en docs/00-sizing.md y la red descrita en
  docs/03-red-host-vm.md, leyendo la configuración de config/vm.conf.

.NOTES
  - No requiere Administrador (VBoxManage corre con permisos de usuario).
  - Idempotente: si la VM ya existe, avisa y no la vuelve a crear.
  - Deja la VM apagada, con la ISO de Ubuntu montada, lista para instalar
    el sistema operativo a mano (docs/01-vm-setup.md, paso 2).
#>

$ErrorActionPreference = "Stop"

# --- Cargar config/vm.conf ---
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root "config\vm.conf"
if (-not (Test-Path $envFile)) {
    Write-Host "No se encontró $envFile" -ForegroundColor Red
    exit 1
}

$cfg = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $cfg[$parts[0].Trim()] = $parts[1].Trim()
    }
}

$VBox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $VBox)) {
    Write-Host "No se encontró VBoxManage.exe en $VBox — revisa la instalación de VirtualBox." -ForegroundColor Red
    exit 1
}

$vmName    = $cfg["VM_NAME"]
$ramMb     = $cfg["RAM_MB"]
$cpuCount  = $cfg["CPU_COUNT"]
$diskGb    = [int]$cfg["DISK_GB"]
$isoPath   = $cfg["ISO_PATH"]
$vmFolder  = $cfg["VM_BASE_FOLDER"]
$sshPort   = $cfg["SSH_HOST_PORT"]
$httpPort  = $cfg["HTTP_HOST_PORT"]

if (-not (Test-Path $isoPath)) {
    Write-Host "No se encontró la ISO en $isoPath — revisa ISO_PATH en config/vm.conf." -ForegroundColor Red
    exit 1
}

# --- ¿Ya existe? ---
$existing = & $VBox list vms
if ($existing -match [regex]::Escape("`"$vmName`"")) {
    Write-Host "La VM '$vmName' ya existe. No se vuelve a crear." -ForegroundColor Yellow
    Write-Host "Para empezar de cero, corre antes: .\host\02-destroy-vm.ps1" -ForegroundColor Yellow
    exit 0
}

Write-Host "Creando VM '$vmName'..." -ForegroundColor Cyan
& $VBox createvm --name $vmName --ostype "Ubuntu_64" --basefolder $vmFolder --register

Write-Host "Asignando sizing: $cpuCount vCPU / $ramMb MB RAM..." -ForegroundColor Cyan
& $VBox modifyvm $vmName `
    --cpus $cpuCount `
    --memory $ramMb `
    --vram 16 `
    --graphicscontroller vmsvga `
    --boot1 dvd --boot2 disk --boot3 none --boot4 none `
    --audio-driver none

Write-Host "Configurando red (NAT + reenvío, y Host-Only)..." -ForegroundColor Cyan
& $VBox modifyvm $vmName --nic1 nat
& $VBox modifyvm $vmName --natpf1 "ssh,tcp,127.0.0.1,$sshPort,,22"
& $VBox modifyvm $vmName --natpf1 "http,tcp,127.0.0.1,$httpPort,,80"
& $VBox modifyvm $vmName --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

Write-Host "Creando disco de $diskGb GB..." -ForegroundColor Cyan
$diskPath = Join-Path (Join-Path $vmFolder $vmName) "$vmName.vdi"
& $VBox createmedium disk --filename $diskPath --size ($diskGb * 1024) --format VDI --variant Standard

Write-Host "Adjuntando disco e ISO..." -ForegroundColor Cyan
& $VBox storagectl $vmName --name "SATA" --add sata --controller IntelAhci
& $VBox storageattach $vmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $diskPath
& $VBox storagectl $vmName --name "IDE" --add ide
& $VBox storageattach $vmName --storagectl "IDE" --port 0 --device 0 --type dvddrive --medium $isoPath

Write-Host ""
Write-Host "VM '$vmName' creada." -ForegroundColor Green
Write-Host "Sizing: $cpuCount vCPU / $ramMb MB / $diskGb GB disco (justificación en docs/00-sizing.md)" -ForegroundColor Green
Write-Host "Red: NAT (SSH host:$sshPort -> VM:22, HTTP host:$httpPort -> VM:80) + Host-Only" -ForegroundColor Green
Write-Host ""
Write-Host "Siguiente paso — instalar Ubuntu (necesita ventana gráfica la primera vez):" -ForegroundColor Cyan
Write-Host "  & `"C:\Program Files\Oracle\VirtualBox\VirtualBoxVM.exe`" --startvm `"$vmName`"" -ForegroundColor White
Write-Host ""
Write-Host "Después de instalar y confirmar SSH, arrancar siempre headless con:" -ForegroundColor Cyan
Write-Host "  & `"$VBox`" startvm `"$vmName`" --type headless" -ForegroundColor White
