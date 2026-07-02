<#
.SYNOPSIS
  Detiene todo lo levantado por start-all.ps1: busca que proceso esta
  escuchando en cada puerto conocido (backend Java + gateway + frontend)
  y lo mata junto con sus hijos (java.exe lanzado por mvnw, etc.).
#>

$ports = @(5000, 5001, 5002, 5003, 5004, 5005, 5006, 7000, 8000, 9000, 8080, 5173)

foreach ($port in $ports) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($conn in $conns) {
        $procId = $conn.OwningProcess
        try {
            $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
            $name = if ($proc) { $proc.ProcessName } else { "?" }
            Write-Host "Puerto $port -> deteniendo proceso $procId ($name)"
            taskkill /F /T /PID $procId | Out-Null
        } catch {
            Write-Warning "No se pudo detener el proceso $procId en puerto $port"
        }
    }
}

Write-Host "Listo." -ForegroundColor Green
