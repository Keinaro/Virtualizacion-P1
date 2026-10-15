<#
.SYNOPSIS
  Desactiva Hyper-V, la Plataforma de Máquina Virtual y WSL para que
  VirtualBox use VT-x nativo en lugar de correr paravirtualizado sobre
  Hyper-V (más lento, y a veces la VM ni arranca).

.NOTES
  - Requiere PowerShell como Administrador.
  - Requiere REINICIAR el equipo al terminar.
  - Funciona tanto en Windows 11 Pro/Enterprise (con Hyper-V completo) como
    en Windows 11 Home (donde el feature "Hyper-V" ni existe, pero el
    hypervisor igual se activa por WSL2/Docker Desktop vía
    VirtualMachinePlatform). El paso que realmente libera VT-x para
    VirtualBox en cualquier edición es el `bcdedit /set hypervisorlaunchtype off`
    del final — los `Disable-WindowsOptionalFeature` son un plus si existen.
  - El proyecto de El Quetzal prohíbe usar Docker Desktop del host de todas
    formas (todo corre dentro de la VM de VirtualBox), así que apagar el
    hypervisor no quita nada que este proyecto necesite.
  - Reversible con 00b-enable-hyperv.ps1 si luego necesitas Docker Desktop
    o WSL para otra cosa.
#>

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Este script necesita PowerShell como Administrador. Ábrelo con 'Ejecutar como administrador' y vuelve a correrlo." -ForegroundColor Red
    exit 1
}

function Disable-FeatureIfExists($name) {
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction Stop
        if ($feature.State -ne "Disabled") {
            Write-Host "Desactivando feature: $name" -ForegroundColor Cyan
            Disable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -ErrorAction Stop | Out-Null
        } else {
            Write-Host "$name ya estaba desactivado." -ForegroundColor Gray
        }
    } catch {
        Write-Host "$name no existe en esta edición de Windows (normal en Windows 11 Home) — se omite." -ForegroundColor Gray
    }
}

Write-Host "Paso 1/2: features opcionales (si existen en esta edición)..." -ForegroundColor Cyan
Disable-FeatureIfExists "Microsoft-Hyper-V-All"
Disable-FeatureIfExists "VirtualMachinePlatform"
Disable-FeatureIfExists "Microsoft-Windows-Subsystem-Linux"

Write-Host ""
Write-Host "Paso 2/2: apagando el hypervisor de Windows en el arranque (bcdedit)..." -ForegroundColor Cyan
Write-Host "Esta es la parte que realmente libera VT-x para VirtualBox, funciona en" -ForegroundColor Gray
Write-Host "cualquier edición de Windows (Home incluido)." -ForegroundColor Gray
bcdedit /set hypervisorlaunchtype off

Write-Host ""
Write-Host "Listo. REINICIA el equipo para que el cambio tome efecto." -ForegroundColor Yellow
Write-Host "Después de reiniciar, verifica con:  bcdedit /enum | findstr hypervisorlaunchtype" -ForegroundColor Yellow
Write-Host "Debe decir 'Off'." -ForegroundColor Yellow
Write-Host ""
Write-Host "Nota: Docker Desktop/WSL2 del host dejarán de arrancar mientras el" -ForegroundColor Gray
Write-Host "hypervisor esté apagado. No afecta al proyecto: todo el Docker que" -ForegroundColor Gray
Write-Host "usamos corre dentro de la VM de VirtualBox, no en el host." -ForegroundColor Gray
