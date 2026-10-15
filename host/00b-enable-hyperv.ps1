<#
.SYNOPSIS
  Reactiva Hyper-V, VirtualMachinePlatform y WSL (revierte
  00-disable-hyperv.ps1). Útil si necesitas volver a usar Docker Desktop
  del host para otra cosa una vez termine este proyecto.

.NOTES
  Requiere PowerShell como Administrador y reiniciar al terminar.
#>

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Este script necesita PowerShell como Administrador." -ForegroundColor Red
    exit 1
}

function Enable-FeatureIfExists($name) {
    try {
        Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction Stop | Out-Null
        Write-Host "Reactivando feature: $name" -ForegroundColor Cyan
        Enable-WindowsOptionalFeature -Online -FeatureName $name -NoRestart -All -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "$name no existe en esta edición de Windows — se omite." -ForegroundColor Gray
    }
}

Write-Host "Reactivando Hyper-V, VirtualMachinePlatform y WSL (si existen)..." -ForegroundColor Cyan
Enable-FeatureIfExists "Microsoft-Hyper-V-All"
Enable-FeatureIfExists "VirtualMachinePlatform"
Enable-FeatureIfExists "Microsoft-Windows-Subsystem-Linux"

Write-Host ""
Write-Host "Reactivando el hypervisor de Windows en el arranque (bcdedit)..." -ForegroundColor Cyan
bcdedit /set hypervisorlaunchtype auto

Write-Host ""
Write-Host "Listo. Reinicia el equipo para que el cambio tome efecto." -ForegroundColor Yellow
Write-Host "Nota: mientras Hyper-V esté activo, VirtualBox pierde 'unrestricted guest'" -ForegroundColor Gray
Write-Host "y corre más lento. Vuelve a desactivarlo antes de trabajar en el proyecto." -ForegroundColor Gray
