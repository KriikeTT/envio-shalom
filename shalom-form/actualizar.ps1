<#
  Regenera ..\formulario-envio-shalom.html con la lista de agencias Shalom.

  Uso:
    powershell -ExecutionPolicy Bypass -File actualizar.ps1 -Entrada <archivo>

  <archivo> puede ser:
    - un JSON con las filas [[dep, prov, dist, nombre, direccion, horario], ...]
    - el archivo que guarda Claude cuando el resultado de extraer-agencias.js es muy largo
      (formato [{ "type": "text", "text": "\"[[...]]\"..." }])
  Sin -Entrada, solo reconstruye el HTML con el agencias.json actual.
#>
param([string]$Entrada, [switch]$Publicar)

$ErrorActionPreference = 'Stop'
$dir  = $PSScriptRoot
$out  = Join-Path (Split-Path $dir -Parent) 'formulario-envio-shalom.html'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$agPath = Join-Path $dir 'agencias.json'

function Texto-Filas([string]$texto) {
    $t = $texto.Trim()
    # Envoltorio de resultado de herramienta: [{type,text}]
    if ($t -match '^\[\s*\{\s*"type"') {
        $w = $t | ConvertFrom-Json
        $t = $w[0].text
    }
    # El texto puede venir como cadena JSON entre comillas, seguida de notas extra
    if ($t.StartsWith('"')) {
        $t = $t.Substring(0, $t.LastIndexOf('"') + 1) | ConvertFrom-Json
    }
    $t = $t.Substring($t.IndexOf('[['))
    return $t.Substring(0, $t.LastIndexOf(']]') + 2)
}
# Ojo: no usar ConvertTo-Json para guardar (en PowerShell 5.1 deforma los arreglos anidados);
# se guarda el texto JSON tal cual llega.
function Leer-Filas([string]$json) { return ,($json | ConvertFrom-Json) }

$anteriores = @()
if (Test-Path $agPath) { $anteriores = Leer-Filas (Texto-Filas ([IO.File]::ReadAllText($agPath, $utf8))) }

if ($Entrada) {
    $jsonNuevo = Texto-Filas ([IO.File]::ReadAllText((Resolve-Path $Entrada), $utf8))
    $filas = Leer-Filas $jsonNuevo
    if ($filas.Count -lt 300) {
        throw "Solo llegaron $($filas.Count) agencias (se esperan ~490). No se actualiza para no dejar el formulario incompleto. ¿Sigue abierta la sesión de Shalom Pro?"
    }
    # Comparar con la lista anterior
    $clave = { param($f) "$($f[0]) / $($f[1]) / $($f[2]) / $($f[3])" }
    $antes = @{}; foreach ($f in $anteriores) { $antes[(& $clave $f)] = 1 }
    $ahora = @{}; foreach ($f in $filas)      { $ahora[(& $clave $f)] = 1 }
    $nuevas    = @($ahora.Keys | Where-Object { -not $antes.ContainsKey($_) } | Sort-Object)
    $removidas = @($antes.Keys | Where-Object { -not $ahora.ContainsKey($_) } | Sort-Object)
    [IO.File]::WriteAllText($agPath, $jsonNuevo, $utf8)
    Write-Output "Agencias: $($filas.Count) (antes $($anteriores.Count))"
    Write-Output "Nuevas ($($nuevas.Count)):";    $nuevas    | ForEach-Object { Write-Output "  + $_" }
    Write-Output "Ya no disponibles ($($removidas.Count)):"; $removidas | ForEach-Object { Write-Output "  - $_" }
}

$plantilla = [IO.File]::ReadAllText((Join-Path $dir 'plantilla.html'), $utf8)
$ubigeo    = [IO.File]::ReadAllText((Join-Path $dir 'ubigeo.json'), $utf8)
$agencias  = [IO.File]::ReadAllText($agPath, $utf8).Replace('</', '<\/')
$fecha     = (Get-Date).ToString('dd/MM/yyyy')

$html = $plantilla.Replace('__UBIGEO__', $ubigeo).Replace('__AGENCIAS__', $agencias).Replace('__FECHA__', $fecha)
[IO.File]::WriteAllText($out, $html, $utf8)
Write-Output "Formulario regenerado: $out ($fecha)"

# Con -Publicar: sube a GitHub solo si la lista de agencias cambió
if ($Publicar) {
    $raiz = Split-Path $dir -Parent
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    Push-Location $raiz
    try {
        $cambios = git status --porcelain -- shalom-form/agencias.json
        if (-not $cambios) {
            Write-Output "GitHub: sin cambios en las agencias, no se publica nada."
            git checkout -- formulario-envio-shalom.html 2>$null
        } else {
            git add -- shalom-form/agencias.json formulario-envio-shalom.html
            git commit -m "Actualizar agencias Shalom ($fecha)" | Out-Null
            git push
            if ($LASTEXITCODE -ne 0) { throw "No se pudo subir a GitHub (git push falló)." }
            Write-Output "GitHub: cambios publicados."
        }
    } finally { Pop-Location }
}
