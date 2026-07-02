<#
.SYNOPSIS
  Levanta los 10 microservicios Java (LIbrOnline-Backend), el gateway
  (api-server) y el frontend (school), cada uno en su propia ventana.

.NOTES
  Requisitos previos:
    - JDK 17+ en PATH (java -version)
    - MySQL corriendo en localhost:3306 con las bases creadas
      (ver setup-databases.sql, se ejecuta una sola vez)
    - Variable de entorno DATABASE_URL apuntando a una base Postgres con el
      schema de Drizzle ya aplicado (pnpm --filter @workspace/db run push)
    - pnpm instalado y dependencias del frontend instaladas (pnpm install)
#>

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$backendRoot = Join-Path $root "LIbrOnline-Backend"
$frontendRoot = Join-Path $root "LibrOnlinefrontendv2"

$javaServices = @(
    @{ Name = "Usuarios";             Path = "Usuarios";             Port = 5000 },
    @{ Name = "Mensajeria-Integrada"; Path = "Mensajeria-Integrada"; Port = 5001 },
    @{ Name = "Gestion_Reuniones";    Path = "Gestion_Reuniones";    Port = 5002 },
    @{ Name = "Gestion_Cursos";       Path = "Gestion_Cursos";       Port = 5003 },
    @{ Name = "Creacion_Eventos";     Path = "Creacion_Eventos";     Port = 5004 },
    @{ Name = "Asistencia";           Path = "Asistencia";           Port = 5005 },
    @{ Name = "Anotaciones";          Path = "Anotaciones";          Port = 5006 },
    @{ Name = "direcciones";          Path = "direcciones";          Port = 7000 },
    @{ Name = "Notas";                Path = "Notas";                Port = 8000 },
    @{ Name = "matriculas";           Path = "matriculas";           Port = 9000 }
)

function Start-ServiceWindow {
    param(
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command
    )
    $inner = "`$host.UI.RawUI.WindowTitle = '$Title'; Set-Location -LiteralPath '$WorkingDirectory'; $Command"
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoExit", "-Command", $inner) | Out-Null
}

# Busca un JDK 17+ instalado en disco (no confia en JAVA_HOME/PATH de la
# sesion actual: si esta terminal es vieja, esas variables pueden estar
# desactualizadas aunque el JDK ya este instalado).
function Find-Jdk17Plus {
    $candidates = @()
    $searchRoots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        (Join-Path $env:LOCALAPPDATA "Programs\Eclipse Adoptium")
    )
    foreach ($rootDir in $searchRoots) {
        if (Test-Path $rootDir) {
            Get-ChildItem -Path $rootDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                if (Test-Path (Join-Path $_.FullName "bin\javac.exe")) {
                    $candidates += $_.FullName
                }
            }
        }
    }
    if ($env:JAVA_HOME -and (Test-Path (Join-Path $env:JAVA_HOME "bin\javac.exe"))) {
        $candidates += $env:JAVA_HOME
    }
    # Ordena por el numero de version real (no alfabeticamente por ruta) y se
    # queda con la mas alta: un JDK mas nuevo puede compilar --release N para
    # cualquier N <= su propia version, asi que conviene la mas alta posible.
    $best = $candidates | Select-Object -Unique | ForEach-Object {
        $verOutput = cmd /c "`"$_\bin\java.exe`" -version 2>&1"
        $verText = ($verOutput -join " ")
        if ($verText -match '"(\d+)') {
            [PSCustomObject]@{ Path = $_; Major = [int]$Matches[1] }
        }
    } | Where-Object { $_.Major -ge 17 } | Sort-Object -Property Major -Descending | Select-Object -First 1
    if ($best) { return $best.Path }
    return $null
}

# --- Chequeos previos --------------------------------------------------------

$jdkHome = Find-Jdk17Plus
if (-not $jdkHome) {
    Write-Warning "No se encontro ningun JDK 17+ instalado en las rutas habituales. Los microservicios Java van a fallar al compilar. Instala uno (ej. winget install --id EclipseAdoptium.Temurin.21.JDK -e) y volve a correr este script."
} else {
    Write-Host "JDK detectado: $jdkHome" -ForegroundColor DarkGray
}

# Mismo problema que con JAVA_HOME: si DATABASE_URL esta seteada a nivel de
# usuario pero esta terminal es vieja, no la va a ver. Si no esta presente en
# esta sesion, se usa el cluster Postgres local de desarrollo (puerto 5433,
# sin password, base "libronline") en vez de fallar.
$databaseUrl = if ($env:DATABASE_URL) { $env:DATABASE_URL } else { "postgres://postgres@localhost:5433/libronline" }
if (-not $env:DATABASE_URL) {
    Write-Host "DATABASE_URL no estaba definida en esta sesion, se usa el default local: $databaseUrl" -ForegroundColor DarkGray
}

# --- Backend Java -----------------------------------------------------------

Write-Host "`nLevantando 10 microservicios Java..." -ForegroundColor Cyan
foreach ($svc in $javaServices) {
    $path = Join-Path $backendRoot $svc.Path
    if (-not (Test-Path $path)) {
        Write-Warning "No existe la carpeta $path, se omite $($svc.Name)."
        continue
    }
    Write-Host ("  - {0,-22} puerto {1}" -f $svc.Name, $svc.Port)
    # Se fija JAVA_HOME/PATH a mano dentro de la ventana en vez de heredarlo
    # de esta sesion, para no depender de que la terminal sea "nueva".
    $javaEnvPrefix = if ($jdkHome) { "`$env:JAVA_HOME='$jdkHome'; `$env:Path='$jdkHome\bin;' + `$env:Path; " } else { "" }
    Start-ServiceWindow -Title "$($svc.Name) ($($svc.Port))" -WorkingDirectory $path -Command "$javaEnvPrefix.\mvnw.cmd spring-boot:run"
    Start-Sleep -Milliseconds 300
}

# --- Gateway (api-server) ----------------------------------------------------

Write-Host "`nLevantando gateway api-server (puerto 8080)..." -ForegroundColor Cyan
# Libera el puerto 8080 si habia un proceso previo, para evitar conflictos.
$prev8080 = (Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue).OwningProcess
if ($prev8080) { Stop-Process -Id $prev8080 -Force -ErrorAction SilentlyContinue }
# No se usa "pnpm run dev" porque ese script usa sintaxis bash (export VAR=valor)
# que no existe en PowerShell/cmd; se arma el equivalente (build + start) a mano.
Start-ServiceWindow -Title "api-server (8080)" -WorkingDirectory $frontendRoot `
    -Command "`$env:NODE_ENV='development'; pnpm --filter @workspace/api-server run build; pnpm --filter @workspace/api-server run start"

# --- Frontend (school) -------------------------------------------------------

Write-Host "Levantando frontend school (puerto 5173)..." -ForegroundColor Cyan
Start-ServiceWindow -Title "school (5173)" -WorkingDirectory $frontendRoot `
    -Command "pnpm --filter @workspace/school run dev"

Write-Host "`nListo. Se abrieron $(([array]$javaServices).Count + 2) ventanas, una por servicio." -ForegroundColor Green
Write-Host "Los microservicios Java tardan ~30-60s en arrancar (Hibernate recrea el schema)."
Write-Host "Frontend en http://localhost:5173 una vez que todo este arriba."
Write-Host "Para detener todo: .\stop-all.ps1"
