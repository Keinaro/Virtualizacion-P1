<#
.SYNOPSIS
  Apaga (si hace falta) y elimina por completo la VM de El Quetzal,
  incluyendo su disco. Útil para empezar de cero.

.NOTES
  DESTRUCTIVO — borra el disco virtual. Pide confirmación antes de actuar.
#>

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root "config\vm.conf"
$cfg = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
        $parts = $line.Split("=", 2)
        $cfg[$parts[0].Trim()] = $parts[1].Trim()
    }
}
$vmName = $cfg["VM_NAME"]
$VBox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$confirm = Read-Host "Esto eliminará la VM '$vmName' Y SU DISCO por completo. Escribe 'si' para confirmar"
if ($confirm -ne "si") {
    Write-Host "Cancelado." -ForegroundColor Yellow
    exit 0
}

$state = & $VBox showvminfo $vmName --machinereadable 2>$null | Select-String "^VMState="
if ($state -match "running") {
    Write-Host "Apagando la VM..." -ForegroundColor Cyan
    & $VBox controlvm $vmName poweroff
    Start-Sleep -Seconds 2
}

Write-Host "Eliminando VM y disco..." -ForegroundColor Cyan
& $VBox unregistervm $vmName --delete

Write-Host "Listo. '$vmName' eliminada." -ForegroundColor Green
