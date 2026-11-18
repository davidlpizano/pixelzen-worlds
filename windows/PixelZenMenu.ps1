param(
    [switch]$Tray,
    [switch]$SoloAplicar
)

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$ErrorActionPreference = 'SilentlyContinue'
$Aqui = Split-Path -Parent $MyInvocation.MyCommand.Path
$Raiz = Split-Path -Parent $Aqui
$LivelyLocalDir = if (Test-Path (Join-Path $Aqui 'lively\index.html')) { Join-Path $Aqui 'lively' } else { Join-Path $Raiz 'windows\lively' }
$TemasDir = if (Test-Path (Join-Path $Aqui 'lively\temas')) {
    Join-Path $Aqui 'lively\temas'
} elseif (Test-Path (Join-Path $Aqui 'temas')) {
    Join-Path $Aqui 'temas'
} elseif (Test-Path (Join-Path $Raiz 'docs\temas')) {
    Join-Path $Raiz 'docs\temas'
} else {
    Join-Path $Raiz 'windows\lively\temas'
}
$EsInstalada = (Test-Path (Join-Path $Aqui 'lively\temas')) -or (Test-Path (Join-Path $Aqui 'temas'))
$DataDir = if ($EsInstalada) { Join-Path $env:LOCALAPPDATA 'PixelZenWorlds' } else { $Aqui }
if (-not (Test-Path $DataDir)) { New-Item -Path $DataDir -ItemType Directory -Force | Out-Null }
$ConfigPath = Join-Path $DataDir 'config.json'
$IconPath = Join-Path $Aqui 'pixelzen.ico'
$VbsPath = Join-Path $Aqui 'PixelZenApp.vbs'
$AutoRegPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$AutoRegName = 'PixelZenWorlds'

function Resolver-Preview([string]$temaId, [string]$fase, [string]$variante = 'principal') {
    $sub = switch ($variante) {
        'secundaria' { 'secundario' }
        'True'       { 'secundario' }
        'bloqueo'    { 'bloqueo' }
        default      { '' }
    }
    $temaDirLocal = Join-Path $TemasDir $temaId
    $temaDirEsc = Join-Path $Raiz "escenas\$temaId"
    $baseLocal = if ($sub) { Join-Path $temaDirLocal $sub } else { $temaDirLocal }
    $baseEsc = if ($sub) { Join-Path $temaDirEsc $sub } else { $temaDirEsc }
    $fbRoot = Join-Path $Raiz 'docs'
    $pref = switch ($sub) {
        'secundario' { 'm2-' }
        'bloqueo'    { 'm3-' }
        default      { '' }
    }
    $fbTema = if ($sub) { Join-Path $fbRoot "temas\$temaId\$sub" } else { Join-Path $fbRoot "temas\$temaId" }
    $cands = @(
        (Join-Path $baseLocal "preview\$fase\v3.png"),
        (Join-Path $baseEsc "preview\$fase\v3.png"),
        (Join-Path $baseLocal 'fondo.png'),
        (Join-Path $temaDirLocal 'fondo.png'),
        (Join-Path $fbRoot "previews\$temaId\${pref}$fase.png"),
        (Join-Path $fbTema "images\escena-$fase.png")
    )
    foreach ($p in $cands) {
        if ($p -and (Test-Path $p)) { return ([System.IO.Path]::GetFullPath($p)) }
    }
    return $null
}

function Resolver-Python {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -notmatch 'WindowsApps\\python\.exe$') { return $cmd.Source }
    foreach ($cand in @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python312\python.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python311\python.exe'),
        'C:\Python312\python.exe'
    )) {
        if (Test-Path $cand) { return $cand }
    }
    return $null
}

function Cargar-Config {
    $def = [ordered]@{
        tema = 'fittoa'
        temaSecundario = 'igual'
        monitores = 2
        modo = '90m'
        horaFija = 21.5
        fps = 16
        hud = $true
        soloWidgets = $false
        compactoHud = $false
        clima = 'normal'
        rotacionMinutos = 0
        pausaJuego = $true
        audioReactivo = $true
        hotkeys = $true
        eventoSeq = 0
        eventoTipo = ''
        trayAlCerrar = $true
        usarBloqueo = $true
        fondoPrincipal = 'principal'
        fondoSecundario = 'secundaria'
        fondoBloqueo = 'bloqueo'
        stats = [ordered]@{
            tiempo = $true
            clima = $true
            sistema = $true
            gpu = $true
            red = $true
            audio = $true
            dev = $true
            foco = $true
            grimorio = $true
        }
    }
    if (Test-Path $ConfigPath) {
        try {
            $raw = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($k in 'tema','temaSecundario','monitores','modo','horaFija','fps','hud','soloWidgets','compactoHud','clima','rotacionMinutos','pausaJuego','audioReactivo','hotkeys','eventoSeq','eventoTipo','trayAlCerrar','usarBloqueo','fondoPrincipal','fondoSecundario','fondoBloqueo') {
                if ($null -ne $raw.$k) { $def[$k] = $raw.$k }
            }
            if ($raw.stats) {
                foreach ($sk in 'tiempo','clima','sistema','gpu','red','audio','dev','foco','grimorio') {
                    if ($null -ne $raw.stats.$sk) { $def.stats[$sk] = [bool]$raw.stats.$sk }
                }
            }
        } catch {}
    }
    return $def
}

function Guardar-Config($cfg) {
    $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigPath -Encoding UTF8
}

function Detectar-Fase($modo, $horaFija) {
    $h = if ($modo -eq 'fija') { [double]$horaFija } else { (Get-Date).Hour + (Get-Date).Minute / 60.0 }
    if ($h -ge 8.0 -and $h -lt 17.5) { return 'dia' }
    if (($h -ge 6.0 -and $h -lt 8.0) -or ($h -ge 17.5 -and $h -lt 20.0)) { return 'dorado' }
    return 'noche'
}

function Aplicar-Fondos-Windows($tema, $numMonitores, $fase, $fondoPrincipal = 'principal', $fondoSecundario = 'secundaria', $temaSecundario = 'igual') {
    $p1 = Resolver-Preview $tema $fase $fondoPrincipal
    $tSec = if ($temaSecundario -and $temaSecundario -ne 'igual') { $temaSecundario } else { $tema }
    $p2 = Resolver-Preview $tSec $fase $fondoSecundario
    if (-not $p2) { $p2 = $p1 }

    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers' -Name 'BackgroundType' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    $code = @'
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct PZRECT { public int Left, Top, Right, Bottom; }

[ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPzDesktopWallpaper {
    void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
    [return: MarshalAs(UnmanagedType.LPWStr)]
    string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
    [return: MarshalAs(UnmanagedType.LPWStr)]
    string GetMonitorDevicePathAt(uint monitorIndex);
    uint GetMonitorDevicePathCount();
    PZRECT GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
}

[ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")]
public class PzDesktopWallpaperClass {}

public class PzWallApp {
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfoW(int uAction, int uParam, string lpvParam, int fuWinIni);

    public static void Apply(string p1, string p2, int numMon) {
        var dw = (IPzDesktopWallpaper)new PzDesktopWallpaperClass();
        uint count = dw.GetMonitorDevicePathCount();
        int primIdx = 0;
        for (uint i = 0; i < count; i++) {
            string id = dw.GetMonitorDevicePathAt(i);
            PZRECT r = dw.GetMonitorRECT(id);
            if (r.Left == 0 && r.Top == 0) { primIdx = (int)i; break; }
        }
        for (uint i = 0; i < count; i++) {
            string id = dw.GetMonitorDevicePathAt(i);
            if ((int)i == primIdx || numMon <= 1) {
                dw.SetWallpaper(id, p1);
            } else {
                dw.SetWallpaper(id, p2);
            }
        }
        if (count == 0) { SystemParametersInfoW(20, 0, p1, 3); }
    }
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    try {
        [PzWallApp]::Apply($p1, $p2, [int]$numMonitores)
    } catch {
        [PzWallApp]::SystemParametersInfoW(20, 0, $p1, 3) | Out-Null
    }
}

function Limpiar-RestosLively {
    $livelyWallRoot = Join-Path $env:LOCALAPPDATA 'Lively Wallpaper\Library\wallpapers'
    $habiaPrueba = $false
    foreach ($name in @('pixelzen-m1', 'pixelzen-m2')) {
        $dir = Join-Path $livelyWallRoot $name
        if (Test-Path $dir) {
            $habiaPrueba = $true
            $lnk = Join-Path $dir 'temas'
            if (Test-Path $lnk) { cmd /c rmdir "`"$lnk`"" 2>$null | Out-Null }
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    if ($habiaPrueba) {
        Stop-Process -Name 'Lively', 'Lively.UI.WinUI', 'Lively.WebView2' -Force -ErrorAction SilentlyContinue
    }
}

function Detener-CiclosPrevios {
    foreach ($pf in @('pixelzen_win.pid', 'pixelzen_hud.pid')) {
        $pfile = Join-Path $env:TEMP $pf
        if (Test-Path $pfile) {
            $oldPid = Get-Content $pfile -ErrorAction SilentlyContinue
            if ($oldPid) { Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue }
        }
    }
}

function Detener-MotoresFondo {
    foreach ($pf in @('pixelzen_motor.pid', 'pixelzen_win.pid')) {
        $pfile = Join-Path $env:TEMP $pf
        if (Test-Path $pfile) {
            $oldPid = Get-Content $pfile -ErrorAction SilentlyContinue
            if ($oldPid) { Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue }
            Remove-Item $pfile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Motor-NativoActivo {
    $motorPidFile = Join-Path $env:TEMP 'pixelzen_motor.pid'
    if (Test-Path $motorPidFile) {
        $oldPid = Get-Content $motorPidFile -ErrorAction SilentlyContinue
        if ($oldPid -and (Get-Process -Id ([int]$oldPid) -ErrorAction SilentlyContinue)) { return $true }
    }
    return $false
}

function Aplicar-Bloqueo-Windows($tema, $variante, $fase) {
    $src = Resolver-Preview $tema $fase $variante
    if (-not $src -or -not (Test-Path $src)) { return $false }
    $lockA = Join-Path $DataDir 'lockscreen_a.png'
    $lockB = Join-Path $DataDir 'lockscreen_b.png'
    $curImg = ''
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime
        $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
        $null = [Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime]
        $curImg = [Windows.System.UserProfile.LockScreen]::OriginalImageFile.AbsolutePath
    } catch { return $false }
    $outPath = if ($curImg -and ($curImg -match 'lockscreen_a\.png$')) { $lockB } else { $lockA }

    try {
        $bmpIn = [System.Drawing.Bitmap]::new($src)
        try {
            $dstW = 1920; $dstH = 1080
            $bmpOut = [System.Drawing.Bitmap]::new($dstW, $dstH, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            try {
                $g = [System.Drawing.Graphics]::FromImage($bmpOut)
                try {
                    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                    $scale = [Math]::Max($dstW / [double]$bmpIn.Width, $dstH / [double]$bmpIn.Height)
                    $srcW = [float]($dstW / $scale)
                    $srcH = [float]($dstH / $scale)
                    $srcX = [float](($bmpIn.Width - $srcW) * 0.5)
                    $srcY = [float][Math]::Max(0, [Math]::Min($bmpIn.Height - $srcH, [Math]::Round(($bmpIn.Height - $srcH) * 0.55)))
                    $g.DrawImage($bmpIn, [System.Drawing.Rectangle]::new(0, 0, $dstW, $dstH), $srcX, $srcY, $srcW, $srcH, [System.Drawing.GraphicsUnit]::Pixel)
                } finally { $g.Dispose() }
                $bmpOut.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
            } finally { $bmpOut.Dispose() }
        } finally { $bmpIn.Dispose() }

        $null = [Windows.Foundation.IAsyncAction, Windows.Foundation, ContentType = WindowsRuntime]
        $asTaskGen = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -like 'IAsyncOperation*'
        }) | Select-Object -First 1
        $asTaskAct = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and (-not $_.IsGenericMethodDefinition) -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction'
        }) | Select-Object -First 1
        $opFile = [Windows.Storage.StorageFile]::GetFileFromPathAsync($outPath)
        $tFile = $asTaskGen.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @($opFile))
        $null = $tFile.Wait(-1)
        $sf = $tFile.Result
        $act = [Windows.System.UserProfile.LockScreen]::SetImageFileAsync($sf)
        $tSet = $asTaskAct.Invoke($null, @($act))
        $null = $tSet.Wait(-1)
        return $true
    } catch {
        return $false
    }
}

$script:modoMotor = 'nativo'
$script:bloqueoOk = $false
$script:climaRealPath = Join-Path $DataDir 'clima_real.json'
$script:climaRealCache = $null
$script:lastClimaFetch = [datetime]::MinValue

function Obtener-ClimaRealMenu {
    $ahoraUtc = [DateTime]::UtcNow
    if ($script:climaRealCache -and ($ahoraUtc - $script:lastClimaFetch).TotalMinutes -lt 10) {
        return $script:climaRealCache
    }
    if ((-not $script:climaRealCache) -and (Test-Path $script:climaRealPath)) {
        try {
            $disk = Get-Content $script:climaRealPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($disk -and $disk.ok -and $disk.updatedUtc) {
                $dt = [DateTime]::Parse([string]$disk.updatedUtc).ToUniversalTime()
                $script:climaRealCache = $disk
                $script:lastClimaFetch = $dt
                if (($ahoraUtc - $dt).TotalMinutes -lt 10) { return $disk }
            }
        } catch {}
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $lat = $null; $lon = $null; $city = ''; $country = ''
        $g1 = Invoke-RestMethod -Uri 'http://ip-api.com/json/?fields=status,country,city,lat,lon' -TimeoutSec 2
        if ($g1 -and $g1.status -eq 'success' -and $null -ne $g1.lat) {
            $lat = [double]$g1.lat; $lon = [double]$g1.lon; $city = [string]$g1.city; $country = [string]$g1.country
        }
        if ($null -eq $lat) {
            $g2 = Invoke-RestMethod -Uri 'https://ipwho.is/' -TimeoutSec 2
            if ($g2 -and $g2.success -and $null -ne $g2.latitude) {
                $lat = [double]$g2.latitude; $lon = [double]$g2.longitude; $city = [string]$g2.city; $country = [string]$g2.country
            }
        }
        if ($null -ne $lat -and $null -ne $lon) {
            $inv = [System.Globalization.CultureInfo]::InvariantCulture
            $om = Invoke-RestMethod -Uri ("https://api.open-meteo.com/v1/forecast?latitude={0}&longitude={1}&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day&timezone=auto" -f $lat.ToString('0.####', $inv), $lon.ToString('0.####', $inv)) -TimeoutSec 2
            if ($om -and $om.current) {
                $cur = $om.current
                $wcode = [int]$cur.weather_code
                $wdesc = switch ($wcode) {
                    0 { 'Despejado' } 1 { 'Mayormente despejado' } 2 { 'Parcialmente nublado' } 3 { 'Nublado' }
                    { $_ -in 45,48 } { 'Niebla' }
                    { $_ -in 51,53,55,56,57 } { 'Llovizna' }
                    { $_ -in 61,63,65,66,67,80,81,82 } { 'Lluvia' }
                    { $_ -in 71,73,75,77,85,86 } { 'Nieve' }
                    { $_ -in 95,96,99 } { 'Tormenta' }
                    default { 'Despejado' }
                }
                $wef = switch ($wcode) {
                    { $_ -in 45,48 } { 'niebla' }
                    { $_ -in 51,53,55,56,57,61,63,65,66,67,80,81,82 } { 'lluvia' }
                    { $_ -in 71,73,75,77,85,86 } { 'nieve' }
                    { $_ -in 95,96,99 } { 'tormenta' }
                    default { 'normal' }
                }
                $resCl = [pscustomobject]@{
                    ok = $true; city = $(if ($city) { $city } else { 'Tu ubicación' }); country = $country
                    lat = $lat; lon = $lon
                    temp = [Math]::Round([double]$cur.temperature_2m, 1)
                    apparent = [Math]::Round([double]$cur.apparent_temperature, 1)
                    hum = [int][Math]::Round([double]$cur.relative_humidity_2m)
                    wind = [Math]::Round([double]$cur.wind_speed_10m, 0)
                    code = $wcode; desc = $wdesc; efecto = $wef; isDay = [int]$cur.is_day
                    updatedUtc = $ahoraUtc.ToString('o')
                }
                $script:climaRealCache = $resCl
                $script:lastClimaFetch = $ahoraUtc
                ($resCl | ConvertTo-Json -Depth 3) | Set-Content -Path $script:climaRealPath -Encoding UTF8 -ErrorAction SilentlyContinue
                return $resCl
            }
        }
    } catch {}
    $script:lastClimaFetch = $ahoraUtc.AddMinutes(-8)
    return $script:climaRealCache
}

function Aplicar-Todo($c) {
    $fase = Detectar-Fase $c.modo $c.horaFija
    if ($c.soloWidgets) {
        $c.hud = $true
        Guardar-Config $c
        Detener-MotoresFondo
        Detener-CiclosPrevios
        $script:modoMotor = 'solo-widgets'
        $script:bloqueoOk = $false
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$(Join-Path $Aqui 'PixelZenHud.ps1')`"" -WindowStyle Hidden
        return $fase
    }
    Guardar-Config $c
    Limpiar-RestosLively
    $fp = if ($c.fondoPrincipal) { $c.fondoPrincipal } else { 'principal' }
    $fs = if ($c.fondoSecundario) { $c.fondoSecundario } else { 'secundaria' }
    $fb = if ($c.fondoBloqueo) { $c.fondoBloqueo } else { 'bloqueo' }
    $ts = if ($c.temaSecundario) { $c.temaSecundario } else { 'igual' }
    $cl = if ($c.clima) { $c.clima } else { 'normal' }
    $rot = if ($null -ne $c.rotacionMinutos) { [int]$c.rotacionMinutos } else { 0 }
    $pj = if ($null -ne $c.pausaJuego -and -not [bool]$c.pausaJuego) { 0 } else { 1 }
    $ar = if ($null -ne $c.audioReactivo -and -not [bool]$c.audioReactivo) { 0 } else { 1 }
    $hk = if ($null -ne $c.hotkeys -and -not [bool]$c.hotkeys) { 0 } else { 1 }
    $fpsVal = if ($null -ne $c.fps -and [int]$c.fps -ge 4) { [int]$c.fps } else { 16 }
    $horaStr = ([double]$c.horaFija).ToString('0.##', [System.Globalization.CultureInfo]::InvariantCulture)
    Aplicar-Fondos-Windows $c.tema $c.monitores $fase $fp $fs $ts
    if ($c.usarBloqueo) {
        $script:bloqueoOk = Aplicar-Bloqueo-Windows $c.tema $fb $fase
    } else {
        $script:bloqueoOk = $false
    }
    Detener-CiclosPrevios

    $motorPath = Join-Path $Aqui 'PixelZenMotor.ps1'
    if (Test-Path $motorPath) {
        $script:modoMotor = 'nativo'
        $motorPidFile = Join-Path $env:TEMP 'pixelzen_motor.pid'
        if (Test-Path $motorPidFile) {
            $oldM = Get-Content $motorPidFile -ErrorAction SilentlyContinue
            if ($oldM) { Stop-Process -Id ([int]$oldM) -Force -ErrorAction SilentlyContinue }
        }
        $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$motorPath`" -Tema $($c.tema) -Monitores $($c.monitores) -Modo $($c.modo) -Hora $horaStr -Fps $fpsVal -FondoPrincipal $fp -FondoSecundario $fs -Clima $cl -TemaSecundario $ts -RotacionMinutos $rot -PausaJuego $pj -AudioReactivo $ar -Hotkeys $hk" -WindowStyle Hidden -PassThru
        if ($proc) { Set-Content -Path $motorPidFile -Value $proc.Id -Encoding ASCII }
    } else {
        $script:modoMotor = 'estatico'
        $pyPidFile = Join-Path $env:TEMP 'pixelzen_win.pid'
        $py = Resolver-Python
        $pyConPillow = $false
        if ($py) {
            try {
                & $py -c "import PIL" 2>$null
                $pyConPillow = ($LASTEXITCODE -eq 0)
            } catch { $pyConPillow = $false }
        }
        if ($pyConPillow -and $c.modo -ne 'fija') {
            $flag = if ($c.modo -eq 'demo') { '--demo' } elseif ($c.modo -eq 'real') { '--real' } else { '--90m' }
            $proc = Start-Process -FilePath $py -ArgumentList "`"$(Join-Path $Aqui 'pixelzen_win.py')`" --tema $($c.tema) --monitores $($c.monitores) $flag" -WindowStyle Hidden -PassThru
            if ($proc) { Set-Content -Path $pyPidFile -Value $proc.Id -Encoding ASCII }
        } elseif ($c.modo -ne 'fija' -and (Test-Path (Join-Path $Aqui 'PixelZenCiclo.ps1'))) {
            $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$(Join-Path $Aqui 'PixelZenCiclo.ps1')`" -Tema $($c.tema) -Monitores $($c.monitores) -Modo $($c.modo) -Hora $($c.horaFija) -FondoPrincipal $fp -FondoSecundario $fs" -WindowStyle Hidden -PassThru
            if ($proc) { Set-Content -Path $pyPidFile -Value $proc.Id -Encoding ASCII }
        }
    }

    if ($c.hud) {
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$(Join-Path $Aqui 'PixelZenHud.ps1')`"" -WindowStyle Hidden
    }
    return $fase
}

function Detener-Hud {
    $hudPidFile = Join-Path $env:TEMP 'pixelzen_hud.pid'
    if (Test-Path $hudPidFile) {
        $oldHud = Get-Content $hudPidFile -ErrorAction SilentlyContinue
        if ($oldHud) { Stop-Process -Id ([int]$oldHud) -Force -ErrorAction SilentlyContinue }
    }
}

function Hay-HudActivo {
    $hudPidFile = Join-Path $env:TEMP 'pixelzen_hud.pid'
    if (Test-Path $hudPidFile) {
        $pidVal = Get-Content $hudPidFile -ErrorAction SilentlyContinue
        if ($pidVal -and (Get-Process -Id ([int]$pidVal) -ErrorAction SilentlyContinue)) { return $true }
    }
    return $false
}

function AutoInicio-Activo {
    $val = (Get-ItemProperty -Path $AutoRegPath -Name $AutoRegName -ErrorAction SilentlyContinue).$AutoRegName
    return [bool]$val
}

function Set-AutoInicio($activar) {
    if ($activar) {
        if (-not (Test-Path $AutoRegPath)) { New-Item -Path $AutoRegPath -Force | Out-Null }
        $cmd = "wscript.exe `"$VbsPath`" --tray"
        Set-ItemProperty -Path $AutoRegPath -Name $AutoRegName -Value $cmd
    } else {
        Remove-ItemProperty -Path $AutoRegPath -Name $AutoRegName -ErrorAction SilentlyContinue
    }
}

function Crear-AccesoDirecto {
    $desk = [Environment]::GetFolderPath('Desktop')
    $lnkPath = Join-Path $desk 'PixelZen Worlds.lnk'
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($lnkPath)
    $sc.TargetPath = 'wscript.exe'
    $sc.Arguments = "`"$VbsPath`""
    $sc.WorkingDirectory = $Aqui
    $sc.Description = 'Abrir PixelZen Worlds (Fondos animados, multimonitor y HUD)'
    if (Test-Path $IconPath) { $sc.IconLocation = $IconPath }
    $sc.Save()
    return $lnkPath
}

if ($SoloAplicar) {
    $c = Cargar-Config
    $null = Aplicar-Todo $c
    exit 0
}

# Evitar dos ventanas abiertas: si ya hay PID activo y no es modo bandeja, avisar o cerrar instancia previa
$appPidFile = Join-Path $env:TEMP 'pixelzen_app.pid'
if (Test-Path $appPidFile) {
    $prevPid = Get-Content $appPidFile -ErrorAction SilentlyContinue
    if ($prevPid -and $prevPid -ne $PID) {
        Stop-Process -Id ([int]$prevPid) -Force -ErrorAction SilentlyContinue
    }
}
Set-Content -Path $appPidFile -Value $PID -Encoding ASCII

function Obtener-Version {
    foreach ($vp in @((Join-Path $Aqui 'VERSION'), (Join-Path $Raiz 'VERSION'))) {
        if (Test-Path $vp) {
            $txt = (Get-Content $vp -Raw -ErrorAction SilentlyContinue).Trim()
            if ($txt) { return $txt }
        }
    }
    return '1.1.0'
}

function Cargar-Temas {
    $mapaSerie = @{
        'fittoa'                  = @{ serie = 'Mushoku Tensei'; titulo = 'Región de Fittoa' }
        'continente-demoniaco'    = @{ serie = 'Mushoku Tensei'; titulo = 'Continente Demoníaco' }
        'black-clover'            = @{ serie = 'Black Clover'; titulo = 'Aldea de Hage' }
        'hunter-x-hunter'         = @{ serie = 'Hunter × Hunter'; titulo = 'Isla Ballena' }
        'spiderman-miles-morales' = @{ serie = 'Spider-Man: Miles Morales'; titulo = 'Brooklyn y Manhattan' }
        'solo-leveling'           = @{ serie = 'Solo Leveling'; titulo = 'Castillo del Monarca' }
        'demon-slayer'            = @{ serie = 'Demon Slayer'; titulo = 'Tren Infinito' }
        'stranger-things'         = @{ serie = 'Stranger Things'; titulo = 'Hawkins y el Revés' }
        'harry-potter'            = @{ serie = 'Harry Potter'; titulo = 'Castillo de Hogwarts' }
        'naruto'                  = @{ serie = 'Naruto'; titulo = 'Konoha & Modo Baryon' }
        'jujutsu-kaisen'          = @{ serie = 'Jujutsu Kaisen'; titulo = 'Expansión de Dominio' }
        'attack-on-titan'         = @{ serie = 'Attack on Titan'; titulo = 'El Retumbar y la Muralla' }
        'one-piece'               = @{ serie = 'One Piece'; titulo = 'Gear 5 & Onigashima' }
        'dragon-ball-z'           = @{ serie = 'Dragon Ball Z'; titulo = 'Ultra Instinto en Namek' }
        'cyberpunk-edgerunners'   = @{ serie = 'Cyberpunk: Edgerunners'; titulo = 'Night City & Sandevistan' }
        'terraza-michis'          = @{ serie = 'Vida Zen · Mascotas'; titulo = 'Terraza de los Michis' }
        'salon-noah-maggie'       = @{ serie = 'Vida Zen · Mascotas'; titulo = 'Salón de Noah y Maggie' }
    }
    $lista = @()
    if (Test-Path $TemasDir) {
        foreach ($d in (Get-ChildItem -Path $TemasDir -Directory | Sort-Object Name)) {
            $id = $d.Name
            if ($id.StartsWith('_')) { continue }
            $tj = Join-Path $d.FullName 'tema.json'
            if (-not (Test-Path $tj)) { continue }
            $anime = 'PixelZen'
            $titulo = $id
            $m1 = 'Escena principal'
            $m2 = 'Continuación de la historia'
            try {
                $raw = Get-Content $tj -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($raw.nombre) {
                    $titulo = [string]$raw.nombre
                    if ($titulo -match '^([^·]+)·\s*(.+)$') {
                        $anime = $Matches[1].Trim()
                        $titulo = $Matches[2].Trim()
                    }
                }
                if ($raw.anime) { $anime = [string]$raw.anime }
                if ($raw.subtitulo) { $m1 = [string]$raw.subtitulo }
                elseif ($raw.descripcion) { $m1 = [string]$raw.descripcion }
            } catch {}

            $serie = if ($raw -and $raw.serie) { [string]$raw.serie } elseif ($mapaSerie.ContainsKey($id)) { $mapaSerie[$id].serie } else { $anime }
            if ($mapaSerie.ContainsKey($id)) { $titulo = $mapaSerie[$id].titulo }

            $sj = Join-Path $d.FullName 'secundario\tema.json'
            if (Test-Path $sj) {
                try {
                    $sraw = Get-Content $sj -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($sraw.nombre) { $m2 = [string]$sraw.nombre }
                    elseif ($sraw.subtitulo) { $m2 = [string]$sraw.subtitulo }
                } catch {}
            }
            $m3 = 'Pantalla de bloqueo'
            $bj = Join-Path $d.FullName 'bloqueo\tema.json'
            if (Test-Path $bj) {
                try {
                    $braw = Get-Content $bj -Raw -Encoding UTF8 | ConvertFrom-Json
                    if ($braw.nombre) { $m3 = [string]$braw.nombre }
                    elseif ($braw.subtitulo) { $m3 = [string]$braw.subtitulo }
                } catch {}
            }
            $lista += @{ id = $id; serie = $serie; anime = $serie; titulo = $titulo; m1 = $m1; m2 = $m2; m3 = $m3 }
        }
    }
    if ($lista.Count -eq 0) {
        return @(@{ id = 'fittoa'; serie = 'Mushoku Tensei'; anime = 'Mushoku Tensei'; titulo = 'Región de Fittoa'; m1 = 'Aldea de Buena'; m2 = 'Reino de Asura'; m3 = 'Santuario del Teletransporte' })
    }
    return $lista
}

$VersionActual = Obtener-Version
$temas = Cargar-Temas
$seriesList = @()
$seriesByName = [ordered]@{}
foreach ($t in $temas) {
    if (-not $seriesByName.Contains($t.serie)) {
        $seriesByName[$t.serie] = @()
        $seriesList += $t.serie
    }
    $seriesByName[$t.serie] += $t
}

$screens = [System.Windows.Forms.Screen]::AllScreens
$monSummary = ($screens | ForEach-Object -Begin { $i = 1 } -Process {
    $tag = if ($_.Primary) { 'Principal' } else { 'Secundario' }
    "Pantalla ${i}: $tag ($($_.Bounds.Width)×$($_.Bounds.Height))"
    $i++
}) -join '   ·   '

function New-PzSprite([string[]]$grid, [string]$palSpec) {
    $pal = New-Object System.Collections.Hashtable ([System.StringComparer]::Ordinal)
    foreach ($tok in ($palSpec -split '\s+')) {
        if ($tok -match '^([^=]+)=(.+)$') { $pal[$Matches[1]] = $Matches[2] }
    }
    $h = $grid.Count
    $w = 0
    foreach ($r in $grid) { if ($r.Length -gt $w) { $w = $r.Length } }
    $bytes = New-Object byte[] ($w * $h * 4)
    for ($y = 0; $y -lt $h; $y++) {
        $row = $grid[$y]
        for ($x = 0; $x -lt $row.Length; $x++) {
            $ch = [string]$row[$x]
            if ($ch -eq '.' -or -not $pal.ContainsKey($ch)) { continue }
            $hex = [string]$pal[$ch]
            if ($hex.StartsWith('#')) { $hex = $hex.Substring(1) }
            $b = [Convert]::ToByte($hex.Substring(4, 2), 16)
            $g = [Convert]::ToByte($hex.Substring(2, 2), 16)
            $rC = [Convert]::ToByte($hex.Substring(0, 2), 16)
            $a = if ($hex.Length -ge 8) { [Convert]::ToByte($hex.Substring(6, 2), 16) } else { [byte]255 }
            $idx = ($y * $w + $x) * 4
            $bytes[$idx] = $b; $bytes[$idx + 1] = $g; $bytes[$idx + 2] = $rC; $bytes[$idx + 3] = $a
        }
    }
    $bmp = [System.Windows.Media.Imaging.BitmapSource]::Create($w, $h, 96, 96, [System.Windows.Media.PixelFormats]::Bgra32, $null, $bytes, $w * 4)
    $bmp.Freeze()
    return $bmp
}

function Get-MenuSprites {
    $s = @{}

    # Emblema circular Bonsái al atardecer (24x24)
    $s.bonsai_circle = New-PzSprite @(
        '........oooooooo........'
        '......ooyyyyyyyyoo......'
        '....ooyyyyyyyyyyyyoo....'
        '...oyyyyGGGGGGGyyyyyo...'
        '..oyyyGGLLLLLLLGyyyyyo..'
        '..oyyyGLLllllllGyyyyyo..'
        '.oyyGGLLllGGGGGGGoooo...'
        '.oyGLLLllGLLLLLLLGGoo...'
        '.ooGllGGGGGllLLLLlGGo...'
        'oaaaGggggggGllllGGggao..'
        'oaaaaoGTTggggGGTTggaaao.'
        'oaaaaaaoTTTggTTTaaaaao..'
        'oaaaaaaaaoTTTTToaaaaao..'
        '.orrrrrrrroTTTorrrrro...'
        '.orrrrrrroTBBTTooooor...'
        '..ooooooTTBBBBTTooooo...'
        '..ogggooBBBBBBBBooggo...'
        '...oooPPPPPPPPPPPooo....'
        '...oopPPPPPPPPPPPpoo....'
        '....oopppppppppppoo.....'
        '.....ooooooooooooo......'
        '......oowwwwwwwwo.......'
        '........oooooooo........'
        '........................'
    ) 'o=#0A0D19 y=#F9CC52 a=#F08834 r=#C95427 G=#245E3B L=#459A54 l=#79CE6D g=#19442B T=#5D3723 B=#3F2215 P=#91543A p=#623421 w=#3E4B78'

    # Bonsái completo en maceta con sol dorado (32x28)
    $s.bonsai_pot = New-PzSprite @(
        '............oooooooo............'
        '.........ooyyyyyyyyyyoo.........'
        '.......ooyyyyyyyyyyyyyyoo.......'
        '......oyyyyGGGGGGGGyyyyyyo......'
        '.....oyyyGGLLLLLLLLGyyyyyyo.....'
        '....oyyyGLLllllllllGGyyyyyyo....'
        '....oyyGGLLllGGGGGGGGGGyyyyo....'
        '...oyGGGllGGLLLLLLLLLLGGyyyo....'
        '...oGGLLllGGllllllGGGGllGGyo....'
        '..oyGLLllGGgggGGGGGllLLLLGyo....'
        '..oyGGGgGGTTggggGGGGGllGGayyo...'
        '..oaayyyoTTTTggTTTggggGaaaao....'
        '...oaaaayooTTTTTToGGTTggaaao....'
        '...orrrrryyoTTTToGLLllGrrrro....'
        '....orrrrrroTBBToGllGGrrrro.....'
        '.....ooooooTBBBTTooGooooo.......'
        '..........oTBBBBTo..............'
        '.........ooTBBBBBTTo............'
        '........oTTBBBBBBBBTo...........'
        '.......ooooooooooooooo..........'
        '......ooPPPPPPPPPPPPPPoo........'
        '......oPPPPPPPPPPPPPPPPo........'
        '.......ooPPPPPPPPPPPPoo.........'
        '.......oppppppppppppppo.........'
        '.......oppppppppppppppo.........'
        '........oooooooooooooo..........'
        '........oo..oooo..oooo..........'
        '................................'
    ) 'o=#0A0D19 y=#F8C54A a=#F08B33 r=#C8552A G=#235E3A L=#449852 l=#7BCE6C g=#174027 T=#6B3E26 B=#422415 P=#96563C p=#633422'

    # Estrella dorada tarjetas (13x11)
    $s.star = New-PzSprite @(
        '......o......'
        '.....oyo.....'
        '.....oYo.....'
        '.ooooYYGoooo.'
        'oYYYYYYYYYYGo'
        '.oYYYYYYYYGo.'
        '..oYYYYYYGo..'
        '..oYYooYYGo..'
        '.oYYo..oYYGo.'
        '.oGo....oGGo.'
        '.oo......oo..'
    ) 'o=#0A0D19 y=#FFF1A8 Y=#F7C63E G=#C98416'

    # Casa sidebar (16x13)
    $s.nav_home = New-PzSprite @(
        '.......oo.......'
        '.....oorroo.....'
        '...oorRRRRroo...'
        '..orRRRRRRRroo..'
        '.oRRRRRRRRRRRro.'
        'oRooooooooooooRo'
        '..oWWWWWWWWWWo..'
        '..oWWooWWooWWo..'
        '..oWWbbWWCCWWo..'
        '..oWWbbWWCCWWo..'
        '..oWWbbWWWWWWo..'
        '..oWWbbWWWWWWo..'
        '..oooooooooooo..'
    ) 'o=#0A0D19 r=#EA6A5B R=#C74137 W=#F0E9DC b=#7A4C32 C=#72D8E6'

    # Monitor / Mundos sidebar (16x12)
    $s.nav_monitors = New-PzSprite @(
        '................'
        '.oooooooooooooo.'
        'oCCCCCCCCCCCCCo.'
        'oCsssssssssssCo.'
        'oCsGGyyyyyyGGCo.'
        'oCsGGGGLLGGGGCo.'
        'oCsGGGGGGGGGGCo.'
        'oCCCCCCCCCCCCCo.'
        '.oooooooooooooo.'
        '......oSSo......'
        '....ooSSSSoo....'
        '....oooooooo....'
    ) 'o=#0A0D19 C=#8DA8D6 s=#1A2E52 G=#348C5E L=#6AD47E y=#F7C948 S=#5E739E'

    # Disquete / Guardar / Widgets sidebar (16x12)
    $s.nav_save = New-PzSprite @(
        '.ooooooooooooo..'
        'oBBBBMMMMMMBoBo.'
        'oBBBBMoMMMoBBBB.'
        'oBBBBMMMMMMBBBBo'
        'oBBBBBBBBBBBBBBo'
        'oBooooooooooooBo'
        'oBoWWWWWWWWWWoBo'
        'oBoRRRRRRRRRRoBo'
        'oBoYYYYYYYYYYoBo'
        'oBoCCCCCCCCCCoBo'
        'oBoWWWWWWWWWWoBo'
        'oooooooooooooooo'
    ) 'o=#0A0D19 B=#48649C M=#CFD8EA W=#F2EFE7 R=#D85555 Y=#ECC148 C=#49B5C4'

    # Sol con nube clima (22x13)
    $s.weather = New-PzSprite @(
        '....o....o....o.......'
        '..o..o..ooo..o........'
        '...o.ooyyyyyoo........'
        '.ooooyYYYYYYYyo.......'
        '...ooyYYYYoYYYYo......'
        '..o.oyYYYooWWWWoo.....'
        '....ooyYoWWWWWWWWoo...'
        '.....ooWWWWWWWWWWWWoo.'
        '....oWWWWWWWWWWWWWWWWo'
        '...oWWWWWWWWWWWWWCCCCo'
        '...oWCCCCCCCCCCCCCCCCo'
        '....oBBBBBBBBBBBBBBBo.'
        '.....ooooooooooooooo..'
    ) 'o=#0A0D19 y=#FFE26A Y=#F7BA33 W=#FFFFFF C=#D7EEFA B=#94BED9'

    # Gato pixel-art mascota (18x16)
    $s.cat = New-PzSprite @(
        '..oo......oo......'
        '.oOOo....oOOo.....'
        '.oOroo..oorOo.....'
        '.oOOOOOOOOOOo.....'
        '.oOOppOOppOOo.....'
        '.oOOwkoowkOOo..oo.'
        '.oOOBBkkBBOOo.oOOo'
        '.oOOBMMMMBBOo.oOOo'
        '..ooOOOOOOoo..oOro'
        '..oOBBBBBBOoooOOo.'
        '.oOOBMMMMBOOOOOo..'
        '.oOOBMMMMBOOOOOo..'
        '.oOOOOOOOOooooo...'
        '..oOOoOOo.........'
        '..oOOoOOo.........'
        '...oo..oo.........'
    ) 'o=#0A0D19 O=#F2983C r=#D26E22 p=#C8601E w=#FFFFFF k=#141826 B=#FFD598 M=#FFEAC8'

    # Engranaje metálico Ajustes (22x21)
    $s.gear = New-PzSprite @(
        '........oooooo........'
        '........oLLLLo........'
        '....ooooLLLLLLoooo....'
        '..ooLLLLLLMMLLLLLLoo..'
        '.oLLLLooMMMMMMooLLLLo.'
        '.oLLLoMMDDDDDDMMoLLLo.'
        '..ooLMMDoMMMMoDDMLoo..'
        '..oLMMDoMooooMoDDMLo..'
        'ooLLMDoMo....oMoDDMLoo'
        'oLLLMDoMo....oMoDDMLLo'
        'oLLLMDoMo....oMoDDMLLo'
        'oLLLMDoMo....oMoDDMLLo'
        'ooLLMDoMo....oMoDDMLoo'
        '..oLMMDoMooooMoDDMLo..'
        '..ooLMMDoMMMMoDDMLoo..'
        '.oDDDoMMDDDDDDMMoDDDo.'
        '.oDDDDoMMMMMMMMoDDDDo.'
        '..ooDDDDDDMMDDDDDDoo..'
        '....ooooDDDDDDoooo....'
        '........oDDDDoo.......'
        '........oooooo........'
    ) 'o=#0A0D19 L=#E2EAF6 M=#9FB0CE D=#69799B'

    # Plantita izquierda (14x11)
    $s.plant_left = New-PzSprite @(
        '....oo........'
        '...oLLo...oo..'
        '...oLGo..oLLo.'
        'oooLGoo..oLGo.'
        'oLLGGGo.oGGoo.'
        '.ooGGGGooGGo..'
        '...ooGGGGGGo..'
        '.....oGGGGoo..'
        '....ooGGGo....'
        '....oDDDDoo...'
        '...oooooooo...'
    ) 'o=#0A0D19 L=#78D872 G=#3C9C50 D=#276937'

    # Flor púrpura derecha (14x10)
    $s.flower_right = New-PzSprite @(
        '...oo....oo...'
        '..oPPo..oPPo..'
        '.oPYYPoPYYPo..'
        '..oPPooPPPo...'
        '...ooGGGGoo...'
        '....oGLLGo....'
        '..oooGGGGooo..'
        '.oLLGGGGGGLLo.'
        '..oooGGGGooo..'
        '.....oGGo.....'
    ) 'o=#0A0D19 P=#B878F2 Y=#F8D454 G=#3B9B4E L=#76D670'

    # Brote tarjeta Widgets (10x9)
    $s.sprout = New-PzSprite @(
        '...oooo...'
        '..oYYYYo..'
        '..oYyyYo..'
        '...oooo...'
        '.ooGooGoo.'
        'oLLGGGGLLo'
        '.ooGGGGoo.'
        '...oGGo...'
        '...oooo...'
    ) 'o=#0A0D19 Y=#FFE066 y=#F2AD29 G=#3FA354 L=#7CE678'

    return $s
}

$menuSprites = Get-MenuSprites

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Pixelzen - Fondos &amp; Widgets"
        Width="1160" Height="712"
        MinWidth="960" MinHeight="620"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" ResizeMode="CanResizeWithGrip"
        Background="#0A0D19" Foreground="#F4F0E4"
        FontFamily="Segoe UI">
  <Window.Resources>
    <!-- Scrollbar pixel dark -->
    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="7"/>
      <Setter Property="MinWidth" Value="7"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Grid Background="Transparent" Margin="2,2,0,2">
              <Track x:Name="PART_Track" IsDirectionReversed="True">
                <Track.Thumb>
                  <Thumb Cursor="Hand">
                    <Thumb.Template>
                      <ControlTemplate TargetType="Thumb">
                        <Border x:Name="ThBd" Background="#36467A" CornerRadius="3"/>
                        <ControlTemplate.Triggers>
                          <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="ThBd" Property="Background" Value="#54DED4"/>
                          </Trigger>
                        </ControlTemplate.Triggers>
                      </ControlTemplate>
                    </Thumb.Template>
                  </Thumb>
                </Track.Thumb>
              </Track>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Navegación lateral estilo Pixelzen -->
    <Style x:Key="SideNavBtn" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="#B8C7E2"/>
      <Setter Property="BorderBrush" Value="Transparent"/>
      <Setter Property="BorderThickness" Value="0,1,0,1"/>
      <Setter Property="HorizontalContentAlignment" Value="Left"/>
      <Setter Property="Padding" Value="22,10,12,10"/>
      <Setter Property="Margin" Value="0,2"/>
      <Setter Property="FontSize" Value="13.5"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#20325A"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Botón biselado retro pixel-art -->
    <Style x:Key="PillBtn" TargetType="Button">
      <Setter Property="Background" Value="#243560"/>
      <Setter Property="Foreground" Value="#F3EFE4"/>
      <Setter Property="BorderBrush" Value="#5B78B4"/>
      <Setter Property="BorderThickness" Value="1.5"/>
      <Setter Property="Padding" Value="12,6"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="#0A0D19" CornerRadius="7" Padding="1.5">
              <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="5.5" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#314880"/>
                <Setter TargetName="Bd" Property="BorderBrush" Value="#7CF6EE"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1A2648"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Toggle Switch pixel -->
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#F4F0E4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Margin" Value="0,4"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Background="Transparent">
              <Border x:Name="Track" Width="38" Height="20" CornerRadius="6" Background="#121B36" BorderBrush="#40588C" BorderThickness="1.5" VerticalAlignment="Center" Margin="0,0,10,0">
                <Border x:Name="Knob" Width="13" Height="13" CornerRadius="3" Background="#8FA4C6" HorizontalAlignment="Left" Margin="2,0,0,0" VerticalAlignment="Center"/>
              </Border>
              <ContentPresenter VerticalAlignment="Center" RecognizesAccessKey="True"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Track" Property="Background" Value="#1B5650"/>
                <Setter TargetName="Track" Property="BorderBrush" Value="#5EE8C2"/>
                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                <Setter TargetName="Knob" Property="Margin" Value="0,0,2,0"/>
                <Setter TargetName="Knob" Property="Background" Value="#7CF6EE"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Track" Property="BorderBrush" Value="#7CF6EE"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Opacity" Value="0.45"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- RadioButton pixel -->
    <Style TargetType="RadioButton">
      <Setter Property="Foreground" Value="#F4F0E4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Margin" Value="0,3"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="RadioButton">
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Background="Transparent">
              <Border x:Name="Ring" Width="18" Height="18" CornerRadius="5" Background="#0D152C" BorderBrush="#40588C" BorderThickness="1.5" VerticalAlignment="Center" Margin="0,0,10,0">
                <Border x:Name="Dot" Width="8" Height="8" CornerRadius="2" Background="#54DED4" Visibility="Collapsed" HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
              <ContentPresenter VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="Ring" Property="BorderBrush" Value="#54DED4"/>
                <Setter TargetName="Ring" Property="Background" Value="#143648"/>
                <Setter TargetName="Dot" Property="Visibility" Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Ring" Property="BorderBrush" Value="#54DED4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- ComboBox oscuro pixel -->
    <Style TargetType="ComboBoxItem">
      <Setter Property="Foreground" Value="#DCE6F5"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Padding" Value="10,7"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBoxItem">
            <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}" Margin="3,1">
              <ContentPresenter VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsHighlighted" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#21386C"/>
                <Setter Property="Foreground" Value="#7CF6EE"/>
              </Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="Bd" Property="Background" Value="#1A465C"/>
                <Setter Property="Foreground" Value="#54DED4"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style TargetType="ComboBox">
      <Setter Property="Foreground" Value="#F4F0E4"/>
      <Setter Property="Background" Value="#101B34"/>
      <Setter Property="BorderBrush" Value="#3D568C"/>
      <Setter Property="BorderThickness" Value="1.5"/>
      <Setter Property="SnapsToDevicePixels" Value="True"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ComboBox">
            <Grid>
              <ToggleButton x:Name="ToggleBtn" Focusable="False" IsChecked="{Binding IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press" Cursor="Hand">
                <ToggleButton.Template>
                  <ControlTemplate TargetType="ToggleButton">
                    <Border x:Name="Bd" Background="#101B34" BorderBrush="#3D568C" BorderThickness="1.5" CornerRadius="6">
                      <Grid>
                        <Grid.ColumnDefinitions>
                          <ColumnDefinition Width="*"/>
                          <ColumnDefinition Width="28"/>
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="1" Text="▾" Foreground="#54DED4" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                      </Grid>
                    </Border>
                    <ControlTemplate.Triggers>
                      <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#54DED4"/>
                        <Setter TargetName="Bd" Property="Background" Value="#162444"/>
                      </Trigger>
                      <Trigger Property="IsChecked" Value="True">
                        <Setter TargetName="Bd" Property="BorderBrush" Value="#54DED4"/>
                      </Trigger>
                    </ControlTemplate.Triggers>
                  </ControlTemplate>
                </ToggleButton.Template>
              </ToggleButton>
              <ContentPresenter x:Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" Margin="10,4,28,4" VerticalAlignment="Center" HorizontalAlignment="Left"/>
              <Popup x:Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                <Grid x:Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="260">
                  <Border x:Name="DropDownBorder" Background="#0E1730" BorderBrush="#496BB0" BorderThickness="2" CornerRadius="7" Margin="0,4,0,0" Padding="2">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                      <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                    </ScrollViewer>
                  </Border>
                </Grid>
              </Popup>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Slider pixel rectangular -->
    <Style TargetType="Slider">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Slider">
            <Grid VerticalAlignment="Center" Height="22">
              <Border Height="10" CornerRadius="3" Background="#121E36" BorderBrush="#0A0D19" BorderThickness="2" VerticalAlignment="Center"/>
              <Track x:Name="PART_Track">
                <Track.DecreaseRepeatButton>
                  <RepeatButton Command="Slider.DecreaseLarge" IsTabStop="False">
                    <RepeatButton.Template>
                      <ControlTemplate TargetType="RepeatButton">
                        <Border Height="6" Margin="2,0,0,0" CornerRadius="2" Background="#46B8C6" VerticalAlignment="Center"/>
                      </ControlTemplate>
                    </RepeatButton.Template>
                  </RepeatButton>
                </Track.DecreaseRepeatButton>
                <Track.Thumb>
                  <Thumb>
                    <Thumb.Template>
                      <ControlTemplate TargetType="Thumb">
                        <Border x:Name="Knob" Width="14" Height="20" CornerRadius="3" Background="#8FA4CE" BorderBrush="#0A0D19" BorderThickness="2">
                          <Border Background="#CBD8F0" Margin="1,1,1,10" CornerRadius="1"/>
                        </Border>
                        <ControlTemplate.Triggers>
                          <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Knob" Property="Background" Value="#7CF6EE"/>
                          </Trigger>
                        </ControlTemplate.Triggers>
                      </ControlTemplate>
                    </Thumb.Template>
                  </Thumb>
                </Track.Thumb>
              </Track>
            </Grid>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Botón de barra de título cuadrado -->
    <Style x:Key="WinCtrlBtn" TargetType="Button">
      <Setter Property="Width" Value="26"/>
      <Setter Property="Height" Value="24"/>
      <Setter Property="Margin" Value="4,0,0,0"/>
      <Setter Property="Background" Value="#465486"/>
      <Setter Property="BorderBrush" Value="#7084BE"/>
      <Setter Property="Foreground" Value="#FFFFFF"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border Background="#0A0D19" CornerRadius="5" Padding="1.5">
              <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1.5,1.5,1,1" CornerRadius="3.5">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
              </Border>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="Bd" Property="Opacity" Value="0.88"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <!-- Marco pixel-art exterior -->
  <Border Background="#0A0D19" Padding="3" CornerRadius="8">
    <Border Background="#151C36" BorderBrush="#414D7D" BorderThickness="2.5" CornerRadius="6">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="38"/>
          <RowDefinition Height="3"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Barra de título Pixelzen -->
        <Border x:Name="TitleBarBorder" Grid.Row="0" CornerRadius="4,4,0,0" Padding="10,0,8,0">
          <Border.Background>
            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
              <GradientStop Color="#2B345E" Offset="0"/>
              <GradientStop Color="#21284B" Offset="1"/>
            </LinearGradientBrush>
          </Border.Background>
          <DockPanel>
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
              <Image x:Name="ImgTitleBonsai" Width="22" Height="22" Margin="0,0,8,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
              <TextBlock x:Name="TxtTitleBar" Text="Pixelzen - Fondos &amp; Widgets" Foreground="#F6F2E8" FontSize="13" FontWeight="Bold" VerticalAlignment="Center">
                <TextBlock.Effect>
                  <DropShadowEffect Color="#0A0D19" ShadowDepth="1.5" BlurRadius="0" Direction="315"/>
                </TextBlock.Effect>
              </TextBlock>
              <Border x:Name="BadgeMotor" Background="#12302A" BorderBrush="#399C7A" BorderThickness="1.2" CornerRadius="4" Padding="7,1.5" Margin="12,0,0,0" VerticalAlignment="Center">
                <TextBlock x:Name="TxtMotorBadge" Text="● MOTOR NATIVO" Foreground="#72E6AE" FontSize="9.5" FontWeight="Bold"/>
              </Border>
              <TextBlock x:Name="TxtMonInfo" Text="" Foreground="#8FA7CE" FontSize="10.5" Margin="10,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>

            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" HorizontalAlignment="Right" VerticalAlignment="Center">
              <Button x:Name="BtnMiniTray" Content="▾ Bandeja" Style="{StaticResource PillBtn}" Padding="8,2" FontSize="10.5" Margin="0,0,6,0"/>
              <Button x:Name="BtnWinMin" Content="_" Style="{StaticResource WinCtrlBtn}" ToolTip="Minimizar"/>
              <Button x:Name="BtnWinMax" Content="□" Style="{StaticResource WinCtrlBtn}" ToolTip="Maximizar / Restaurar"/>
              <Button x:Name="BtnSalirTotal" Content="✕" Style="{StaticResource WinCtrlBtn}" Background="#C83F4C" BorderBrush="#F07B86" ToolTip="Cerrar / Enviar a bandeja"/>
            </StackPanel>
          </DockPanel>
        </Border>

        <!-- Separador oscuro título -->
        <Border Grid.Row="1" Background="#0A0D19"/>

        <!-- Cuerpo Principal: Barra Lateral Izquierda | Contenido -->
        <Grid Grid.Row="2">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="188"/>
            <ColumnDefinition Width="3"/>
            <ColumnDefinition Width="*"/>
          </Grid.ColumnDefinitions>

          <!-- BARRA LATERAL IZQUIERDA (Bonsái arriba, iconos nav, bonsái abajo) -->
          <Border Grid.Column="0" Background="#19203C">
            <DockPanel>
              <!-- Logo Bonsái + Título -->
              <StackPanel DockPanel.Dock="Top" HorizontalAlignment="Center" Margin="0,16,0,10">
                <Border Background="#0A0D19" CornerRadius="46" Padding="3" HorizontalAlignment="Center">
                  <Image x:Name="ImgSideBonsaiTop" Width="82" Height="82" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                </Border>
                <TextBlock Text="Pixelzen" Foreground="#F6F2E8" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,6,0,2">
                  <TextBlock.Effect>
                    <DropShadowEffect Color="#0A0D19" ShadowDepth="2" BlurRadius="0" Direction="315"/>
                  </TextBlock.Effect>
                </TextBlock>
              </StackPanel>

              <!-- Navegación Lateral -->
              <StackPanel DockPanel.Dock="Top" Margin="0,4,0,4">
                <Button x:Name="NavHub" Style="{StaticResource SideNavBtn}">
                  <StackPanel Orientation="Horizontal">
                    <Image x:Name="ImgNavHome" Width="22" Height="22" Margin="0,0,12,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                    <TextBlock Text="Inicio" VerticalAlignment="Center"/>
                  </StackPanel>
                </Button>
                <Button x:Name="NavMundos" Style="{StaticResource SideNavBtn}">
                  <StackPanel Orientation="Horizontal">
                    <Image x:Name="ImgNavMonitors" Width="22" Height="22" Margin="0,0,12,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                    <TextBlock Text="Mundos" VerticalAlignment="Center"/>
                  </StackPanel>
                </Button>
                <Button x:Name="NavPantallas" Style="{StaticResource SideNavBtn}">
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="🖥" FontSize="15" Width="22" TextAlignment="Center" Foreground="#7CF6EE" Margin="0,0,12,0"/>
                    <TextBlock Text="Pantallas" VerticalAlignment="Center"/>
                  </StackPanel>
                </Button>
                <Button x:Name="NavHud" Style="{StaticResource SideNavBtn}">
                  <StackPanel Orientation="Horizontal">
                    <Image x:Name="ImgNavSave" Width="22" Height="22" Margin="0,0,12,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                    <TextBlock Text="Widgets" VerticalAlignment="Center"/>
                  </StackPanel>
                </Button>
                <Button x:Name="NavSistema" Style="{StaticResource SideNavBtn}">
                  <StackPanel Orientation="Horizontal">
                    <Image x:Name="ImgNavGear" Width="20" Height="20" Margin="1,0,13,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                    <TextBlock Text="Ajustes" VerticalAlignment="Center"/>
                  </StackPanel>
                </Button>
              </StackPanel>

              <!-- Ilustración Bonsái inferior + resumen discreto -->
              <StackPanel DockPanel.Dock="Bottom" VerticalAlignment="Bottom" Margin="10,4,10,8">
                <Image x:Name="ImgSideBonsaiBottom" Width="116" Height="102" HorizontalAlignment="Center" RenderOptions.BitmapScalingMode="NearestNeighbor" Margin="0,0,0,4"/>
                <Border Background="#11172D" BorderBrush="#2A3A66" BorderThickness="1.2" CornerRadius="6" Padding="8,5">
                  <TextBlock x:Name="TxtResumen" Text="" Foreground="#B4C6E4" FontSize="10" TextWrapping="Wrap" LineHeight="13.5"/>
                </Border>
              </StackPanel>
            </DockPanel>
          </Border>

          <!-- Separador vertical lateral -->
          <Border Grid.Column="1" Background="#0A0D19"/>

          <!-- ÁREA CENTRAL: Hub / Subpáginas + Estudio Derecho + Barra Inferior -->
          <Grid Grid.Column="2" Background="#141A32">
            <Grid.RowDefinitions>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <Grid Grid.Row="0" Margin="12,10,12,6">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition x:Name="ColPreviewGap" Width="0"/>
                <ColumnDefinition x:Name="ColPreviewStudio" Width="0"/>
              </Grid.ColumnDefinitions>

              <!-- COLUMNA IZQUIERDA / PRINCIPAL -->
              <Grid Grid.Column="0">
                <Grid.RowDefinitions>
                  <RowDefinition Height="Auto"/>
                  <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <!-- Barra volver cuando estamos en subpágina -->
                <Border x:Name="BarDetalleTop" Grid.Row="0" Visibility="Collapsed" Background="#1B2547" BorderBrush="#3C528A" BorderThickness="1.5" CornerRadius="8" Padding="10,7" Margin="0,0,0,10">
                  <DockPanel>
                    <Button x:Name="BtnVolverHub" Content="← Volver al Menú Principal" Style="{StaticResource PillBtn}" DockPanel.Dock="Left" Background="#2E4C80" BorderBrush="#6BA3F0"/>
                    <TextBlock x:Name="TxtDetalleTitle" Text="Explorar Mundos" Foreground="#F6F2E8" FontSize="14.5" FontWeight="Bold" VerticalAlignment="Center" Margin="14,0,0,0"/>
                  </DockPanel>
                </Border>

                <Grid Grid.Row="1">
                  <!-- ============================================================ -->
                  <!-- PÁGINA 0: HUB 2x2 IDÉNTICO A LA FOTO DE REFERENCIA            -->
                  <!-- ============================================================ -->
                  <Grid x:Name="PageHub" Margin="2,10,2,2">
                    <Grid.RowDefinitions>
                      <RowDefinition Height="*"/>
                      <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                      <ColumnDefinition Width="*"/>
                      <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>

                    <!-- TARJETA 1 (ARRIBA IZQUIERDA): ELEGIR TEMA -->
                    <Grid Grid.Row="0" Grid.Column="0" Margin="8,14,8,8">
                      <Border Background="#0A0D19" CornerRadius="14" Padding="3">
                        <Border BorderBrush="#498CC8" BorderThickness="2.5" CornerRadius="11" Padding="10,24,10,8">
                          <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                              <GradientStop Color="#203B6B" Offset="0"/>
                              <GradientStop Color="#162A4F" Offset="1"/>
                            </LinearGradientBrush>
                          </Border.Background>
                          <DockPanel>
                            <TextBlock x:Name="TxtHubTemasLista" DockPanel.Dock="Bottom" Text="Temas: Fittoa, Konoha, Jujutsu, Night City..." Foreground="#E8F0FF" FontSize="11.5" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,7,0,0" Cursor="Hand" TextTrimming="CharacterEllipsis"/>
                            <Grid>
                              <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="26"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="26"/>
                              </Grid.ColumnDefinitions>

                              <Button x:Name="BtnHubPrevTema" Grid.Column="0" Content="◀" Style="{StaticResource PillBtn}" Padding="0" Width="22" Height="36" FontSize="10" Background="#172A4E" BorderBrush="#4570B0" ToolTip="Temas anteriores"/>

                              <UniformGrid Grid.Column="1" Columns="3" Margin="4,0">
                                <!-- Slot 1 -->
                                <Border x:Name="HubTemaCard1" Background="#0A0D19" CornerRadius="7" Padding="2" Margin="3,0" Cursor="Hand">
                                  <Border x:Name="HubTemaBevel1" BorderBrush="#4C74B2" BorderThickness="2" CornerRadius="5" Background="#0E1830" ClipToBounds="True">
                                    <Grid>
                                      <Image x:Name="ImgHubTema1" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                      <Border VerticalAlignment="Bottom" Background="#C4080D1B" Padding="2,2.5">
                                        <TextBlock x:Name="TxtHubTema1" Text="Fittoa" Foreground="#F6F2E8" FontSize="9" FontWeight="Bold" HorizontalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                                      </Border>
                                    </Grid>
                                  </Border>
                                </Border>
                                <!-- Slot 2 -->
                                <Border x:Name="HubTemaCard2" Background="#0A0D19" CornerRadius="7" Padding="2" Margin="3,0" Cursor="Hand">
                                  <Border x:Name="HubTemaBevel2" BorderBrush="#4C74B2" BorderThickness="2" CornerRadius="5" Background="#0E1830" ClipToBounds="True">
                                    <Grid>
                                      <Image x:Name="ImgHubTema2" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                      <Border VerticalAlignment="Bottom" Background="#C4080D1B" Padding="2,2.5">
                                        <TextBlock x:Name="TxtHubTema2" Text="Jujutsu" Foreground="#F6F2E8" FontSize="9" FontWeight="Bold" HorizontalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                                      </Border>
                                    </Grid>
                                  </Border>
                                </Border>
                                <!-- Slot 3 -->
                                <Border x:Name="HubTemaCard3" Background="#0A0D19" CornerRadius="7" Padding="2" Margin="3,0" Cursor="Hand">
                                  <Border x:Name="HubTemaBevel3" BorderBrush="#4C74B2" BorderThickness="2" CornerRadius="5" Background="#0E1830" ClipToBounds="True">
                                    <Grid>
                                      <Image x:Name="ImgHubTema3" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                      <Border VerticalAlignment="Bottom" Background="#C4080D1B" Padding="2,2.5">
                                        <TextBlock x:Name="TxtHubTema3" Text="One Piece" Foreground="#F6F2E8" FontSize="9" FontWeight="Bold" HorizontalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                                      </Border>
                                    </Grid>
                                  </Border>
                                </Border>
                              </UniformGrid>

                              <Button x:Name="BtnHubNextTema" Grid.Column="2" Content="▶" Style="{StaticResource PillBtn}" Padding="0" Width="22" Height="36" FontSize="10" Background="#172A4E" BorderBrush="#4570B0" ToolTip="Siguientes temas"/>
                            </Grid>
                          </DockPanel>
                        </Border>
                      </Border>

                      <!-- Cabecera flotante ELEGIR TEMA -->
                      <Border HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,-14,0,0" Background="#0A0D19" CornerRadius="9" Padding="2.5">
                        <Border Background="#31679E" BorderBrush="#67A9E6" BorderThickness="1.5" CornerRadius="7" Padding="22,3">
                          <TextBlock Text="ELEGIR TEMA" Foreground="#FFFFFF" FontSize="15.5" FontWeight="Bold">
                            <TextBlock.Effect>
                              <DropShadowEffect Color="#0A0D19" ShadowDepth="2" BlurRadius="0" Direction="315"/>
                            </TextBlock.Effect>
                          </TextBlock>
                        </Border>
                      </Border>

                      <!-- Estrella abrir todos los mundos -->
                      <Button x:Name="BtnHubIrMundos" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,9,11,0" Background="Transparent" BorderThickness="0" Padding="2" Cursor="Hand" ToolTip="Ver los 15 mundos">
                        <Image x:Name="ImgHubStar1" Width="19" Height="17" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                      </Button>
                    </Grid>

                    <!-- TARJETA 2 (ARRIBA DERECHA): PANTALLAS -->
                    <Grid Grid.Row="0" Grid.Column="1" Margin="8,14,8,8">
                      <Border Background="#0A0D19" CornerRadius="14" Padding="3">
                        <Border BorderBrush="#48AD74" BorderThickness="2.5" CornerRadius="11" Padding="12,24,12,8">
                          <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                              <GradientStop Color="#194B3E" Offset="0"/>
                              <GradientStop Color="#12382F" Offset="1"/>
                            </LinearGradientBrush>
                          </Border.Background>
                          <Grid>
                            <Grid.RowDefinitions>
                              <RowDefinition Height="*"/>
                              <RowDefinition Height="Auto"/>
                            </Grid.RowDefinitions>

                            <UniformGrid Grid.Row="0" Columns="2" Margin="2,0">
                              <!-- Izquierda: ANIMADOS -->
                              <Border x:Name="HubCardAnimados" Cursor="Hand" Margin="0,0,6,0" Background="Transparent">
                                <DockPanel>
                                  <StackPanel DockPanel.Dock="Bottom" Margin="0,4,0,0">
                                    <TextBlock Text="ANIMADOS" Foreground="#F6C84C" FontSize="12.5" FontWeight="Bold" HorizontalAlignment="Center"/>
                                    <TextBlock x:Name="TxtHubAnimSub" Text="2 Pantallas" Foreground="#B2E2C9" FontSize="9.5" HorizontalAlignment="Center"/>
                                  </StackPanel>
                                  <Border Background="#0A0D19" CornerRadius="6" Padding="2">
                                    <Border BorderBrush="#5EB984" BorderThickness="1.5" CornerRadius="4.5" Background="#071316" ClipToBounds="True">
                                      <Image x:Name="ImgHubAnimados" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                    </Border>
                                  </Border>
                                </DockPanel>
                              </Border>

                              <!-- Derecha: ESTÁTICOS / BLOQUEO -->
                              <Border x:Name="HubCardEstaticos" Cursor="Hand" Margin="6,0,0,0" Background="Transparent">
                                <DockPanel>
                                  <StackPanel DockPanel.Dock="Bottom" Margin="0,4,0,0">
                                    <TextBlock Text="ESTÁTICOS" Foreground="#F4F0E4" FontSize="12.5" FontWeight="Bold" HorizontalAlignment="Center"/>
                                    <TextBlock x:Name="TxtHubEstSub" Text="Noche / Bloqueo" Foreground="#C4DCD2" FontSize="9.5" HorizontalAlignment="Center"/>
                                  </StackPanel>
                                  <Border Background="#0A0D19" CornerRadius="6" Padding="2">
                                    <Border BorderBrush="#6B8E82" BorderThickness="1.5" CornerRadius="4.5" Background="#050812" ClipToBounds="True">
                                      <Image x:Name="ImgHubEstaticos" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                    </Border>
                                  </Border>
                                </DockPanel>
                              </Border>
                            </UniformGrid>

                            <!-- Fila inferior: Plantita | Botón Explorar | Flor -->
                            <Grid Grid.Row="1" Margin="0,6,0,0">
                              <Image x:Name="ImgPlantLeft" Width="26" Height="22" HorizontalAlignment="Left" VerticalAlignment="Bottom" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                              <Button x:Name="BtnHubExplorarPantallas" Content="Explorar" Style="{StaticResource PillBtn}" Background="#36895B" BorderBrush="#6FD498" Foreground="#FFFFFF" Padding="24,5" HorizontalAlignment="Center" FontSize="12.5"/>
                              <Image x:Name="ImgFlowerRight" Width="26" Height="20" HorizontalAlignment="Right" VerticalAlignment="Bottom" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                            </Grid>
                          </Grid>
                        </Border>
                      </Border>

                      <!-- Cabecera flotante PANTALLAS -->
                      <Border HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,-14,0,0" Background="#0A0D19" CornerRadius="9" Padding="2.5">
                        <Border Background="#35865A" BorderBrush="#6CD096" BorderThickness="1.5" CornerRadius="7" Padding="24,3">
                          <TextBlock Text="PANTALLAS" Foreground="#FFFFFF" FontSize="15.5" FontWeight="Bold">
                            <TextBlock.Effect>
                              <DropShadowEffect Color="#0A0D19" ShadowDepth="2" BlurRadius="0" Direction="315"/>
                            </TextBlock.Effect>
                          </TextBlock>
                        </Border>
                      </Border>

                      <Button x:Name="BtnHubStar2" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,9,11,0" Background="Transparent" BorderThickness="0" Padding="2" Cursor="Hand" ToolTip="Configurar pantallas y ciclos">
                        <Image x:Name="ImgHubStar2" Width="19" Height="17" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                      </Button>
                    </Grid>

                    <!-- TARJETA 3 (ABAJO IZQUIERDA): WIDGETS -->
                    <Grid Grid.Row="1" Grid.Column="0" Margin="8,14,8,8">
                      <Border Background="#0A0D19" CornerRadius="14" Padding="3">
                        <Border BorderBrush="#B44D92" BorderThickness="2.5" CornerRadius="11" Padding="12,24,12,8">
                          <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                              <GradientStop Color="#471E54" Offset="0"/>
                              <GradientStop Color="#31143B" Offset="1"/>
                            </LinearGradientBrush>
                          </Border.Background>
                          <DockPanel>
                            <TextBlock x:Name="BtnHubIrWidgets" DockPanel.Dock="Bottom" Text="Relojes, Clima, Mascotas y más" Foreground="#F6E8F8" FontSize="12" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,7,0,0" Cursor="Hand"/>

                            <UniformGrid Columns="3" Margin="2,4" VerticalAlignment="Center">
                              <!-- Mosaico 1: Monitor Reloj Digital -->
                              <Border x:Name="HubTileClock" Margin="5" Background="Transparent" VerticalAlignment="Center" Cursor="Hand" ToolTip="Clic para activar o desactivar widgets HUD">
                                <StackPanel VerticalAlignment="Center">
                                  <Border Background="#0A0D19" CornerRadius="9" Padding="2.5">
                                    <Border Background="#747DA4" BorderBrush="#A6B0DA" BorderThickness="2" CornerRadius="7" Padding="6">
                                      <Border Background="#111A2B" BorderBrush="#0A0D19" BorderThickness="2" CornerRadius="4.5" Padding="4,12">
                                        <StackPanel>
                                          <TextBlock x:Name="TxtHubClock" Text="12:34" Foreground="#66F4EA" FontFamily="Consolas" FontSize="22" FontWeight="Bold" HorizontalAlignment="Center"/>
                                          <TextBlock x:Name="TxtHubClockStatus" Text="HUD ON" Foreground="#98B8D8" FontFamily="Consolas" FontSize="8.5" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,3,0,0"/>
                                        </StackPanel>
                                      </Border>
                                    </Border>
                                  </Border>
                                  <!-- Pie monitor reloj -->
                                  <Border Width="28" Height="4" Background="#464E6E" BorderBrush="#0A0D19" BorderThickness="1,0,1,0" HorizontalAlignment="Center"/>
                                  <Border Width="54" Height="5" Background="#5A6388" BorderBrush="#0A0D19" BorderThickness="1.5" CornerRadius="2" HorizontalAlignment="Center"/>
                                </StackPanel>
                              </Border>

                              <!-- Mosaico 2: Clima 21°C -->
                              <Border x:Name="HubTileWeather" Margin="5" Height="118" Background="#0A0D19" CornerRadius="9" Padding="2.5" Cursor="Hand" ToolTip="Clic para cambiar el clima atmosférico">
                                <Border BorderBrush="#88D2FA" BorderThickness="2" CornerRadius="7" Padding="4">
                                  <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                      <GradientStop Color="#4DA6DF" Offset="0"/>
                                      <GradientStop Color="#3279B4" Offset="1"/>
                                    </LinearGradientBrush>
                                  </Border.Background>
                                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                                    <Image x:Name="ImgHubWeather" Width="62" Height="38" RenderOptions.BitmapScalingMode="NearestNeighbor" Margin="0,0,0,4"/>
                                    <TextBlock x:Name="TxtHubWeather" Text="21°C" Foreground="#FFFFFF" FontSize="19" FontWeight="Bold" HorizontalAlignment="Center">
                                      <TextBlock.Effect>
                                        <DropShadowEffect Color="#143252" ShadowDepth="1.5" BlurRadius="0" Direction="315"/>
                                      </TextBlock.Effect>
                                    </TextBlock>
                                    <TextBlock x:Name="TxtHubWeatherSub" Text="DESPEJADO" Foreground="#D8F2FF" FontSize="8.5" FontWeight="Bold" HorizontalAlignment="Center" TextTrimming="CharacterEllipsis" MaxWidth="102"/>
                                  </StackPanel>
                                </Border>
                              </Border>

                              <!-- Mosaico 3: Gato / Tarjetas HUD -->
                              <Border x:Name="HubTileCat" Margin="5" Height="118" Background="#0A0D19" CornerRadius="9" Padding="2.5" Cursor="Hand" ToolTip="Clic para personalizar las 9 tarjetas HUD">
                                <Border Background="#5E2964" BorderBrush="#A652AC" BorderThickness="2" CornerRadius="7" Padding="4">
                                  <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                                    <Image x:Name="ImgHubCat" Width="60" Height="54" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                                    <TextBlock x:Name="TxtHubCatBadge" Text="9 TARJETAS" Foreground="#F6DDF8" FontSize="8.5" FontWeight="Bold" HorizontalAlignment="Center" Margin="0,4,0,0"/>
                                  </StackPanel>
                                </Border>
                              </Border>
                            </UniformGrid>
                          </DockPanel>
                        </Border>
                      </Border>

                      <!-- Brote esquina sup izq -->
                      <Image x:Name="ImgSprout" Width="16" Height="14" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="14,10,0,0" RenderOptions.BitmapScalingMode="NearestNeighbor"/>

                      <!-- Cabecera flotante WIDGETS -->
                      <Border HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,-14,0,0" Background="#0A0D19" CornerRadius="9" Padding="2.5">
                        <Border Background="#8E326F" BorderBrush="#CE67A8" BorderThickness="1.5" CornerRadius="7" Padding="26,3">
                          <TextBlock Text="WIDGETS" Foreground="#FFFFFF" FontSize="15.5" FontWeight="Bold">
                            <TextBlock.Effect>
                              <DropShadowEffect Color="#0A0D19" ShadowDepth="2" BlurRadius="0" Direction="315"/>
                            </TextBlock.Effect>
                          </TextBlock>
                        </Border>
                      </Border>

                      <Button x:Name="BtnHubStar3" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,9,11,0" Background="Transparent" BorderThickness="0" Padding="2" Cursor="Hand" ToolTip="Personalizar widgets HUD">
                        <Image x:Name="ImgHubStar3" Width="19" Height="17" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                      </Button>
                    </Grid>

                    <!-- TARJETA 4 (ABAJO DERECHA): AJUSTES -->
                    <Grid Grid.Row="1" Grid.Column="1" Margin="8,14,8,8">
                      <Border Background="#0A0D19" CornerRadius="14" Padding="3">
                        <Border BorderBrush="#3B90C2" BorderThickness="2.5" CornerRadius="11" Padding="12,24,12,8">
                          <Border.Background>
                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                              <GradientStop Color="#1B3960" Offset="0"/>
                              <GradientStop Color="#132846" Offset="1"/>
                            </LinearGradientBrush>
                          </Border.Background>
                          <Grid>
                            <Grid.ColumnDefinitions>
                              <ColumnDefinition Width="120"/>
                              <ColumnDefinition Width="10"/>
                              <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <!-- Columna Izquierda: Engranaje + Botón Ajustes -->
                            <DockPanel Grid.Column="0" Margin="0,4,0,2">
                              <Button x:Name="BtnHubIrAjustes" DockPanel.Dock="Bottom" Content="Ajustes" Style="{StaticResource PillBtn}" Background="#4A5A88" BorderBrush="#7B90C8" Padding="16,5" HorizontalAlignment="Center"/>
                              <Image x:Name="ImgHubGear" Width="78" Height="74" VerticalAlignment="Center" HorizontalAlignment="Center" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                            </DockPanel>

                            <!-- Columna Derecha: 3 barras + slider pixelado [-][===][+] -->
                            <Grid Grid.Column="2" Margin="0,4,2,2">
                              <Grid.RowDefinitions>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="Auto"/>
                                <RowDefinition Height="*"/>
                              </Grid.RowDefinitions>

                              <!-- Fila General -->
                              <Border x:Name="BtnHubGen" Grid.Row="0" Background="#10213D" BorderBrush="#284B7A" BorderThickness="1.5" CornerRadius="6" Padding="10,6" Margin="0,0,0,7" Cursor="Hand">
                                <DockPanel>
                                  <TextBlock x:Name="TxtHubGenVal" DockPanel.Dock="Right" Text="Ciclo 90m" Foreground="#54DED4" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
                                  <TextBlock Text="General" Foreground="#F4F0E4" FontSize="12.5" FontWeight="Bold" VerticalAlignment="Center"/>
                                </DockPanel>
                              </Border>

                              <!-- Fila Rendimiento -->
                              <Border x:Name="BtnHubRend" Grid.Row="1" Background="#10213D" BorderBrush="#284B7A" BorderThickness="1.5" CornerRadius="6" Padding="10,6" Margin="0,0,0,7" Cursor="Hand">
                                <DockPanel>
                                  <TextBlock x:Name="TxtHubRendVal" DockPanel.Dock="Right" Text="Pausa Auto ON" Foreground="#72E6AE" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
                                  <TextBlock Text="Rendimiento" Foreground="#F4F0E4" FontSize="12.5" FontWeight="Bold" VerticalAlignment="Center"/>
                                </DockPanel>
                              </Border>

                              <!-- Fila Atajos -->
                              <Border x:Name="BtnHubAtajos" Grid.Row="2" Background="#10213D" BorderBrush="#284B7A" BorderThickness="1.5" CornerRadius="6" Padding="10,6" Margin="0,0,0,6" Cursor="Hand">
                                <DockPanel>
                                  <TextBlock x:Name="TxtHubAtajosVal" DockPanel.Dock="Right" Text="Ctrl+Alt ON" Foreground="#F6C84C" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/>
                                  <TextBlock Text="Atajos" Foreground="#F4F0E4" FontSize="12.5" FontWeight="Bold" VerticalAlignment="Center"/>
                                </DockPanel>
                              </Border>

                              <!-- Control [-][slider][+] -->
                              <Grid Grid.Row="3" VerticalAlignment="Bottom">
                                <Grid.ColumnDefinitions>
                                  <ColumnDefinition Width="26"/>
                                  <ColumnDefinition Width="*"/>
                                  <ColumnDefinition Width="26"/>
                                </Grid.ColumnDefinitions>
                                <Button x:Name="BtnHubSldMenos" Grid.Column="0" Content="-" Style="{StaticResource PillBtn}" Padding="0" Width="24" Height="24" Background="#465684" BorderBrush="#7286BA"/>
                                <Slider x:Name="SldHubHora" Grid.Column="1" Minimum="0" Maximum="23.75" TickFrequency="0.25" IsSnapToTickEnabled="True" Value="21.5" Margin="6,0"/>
                                <Button x:Name="BtnHubSldMas" Grid.Column="2" Content="+" Style="{StaticResource PillBtn}" Padding="0" Width="24" Height="24" Background="#465684" BorderBrush="#7286BA"/>
                              </Grid>
                            </Grid>
                          </Grid>
                        </Border>
                      </Border>

                      <!-- Cabecera flotante AJUSTES -->
                      <Border HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,-14,0,0" Background="#0A0D19" CornerRadius="9" Padding="2.5">
                        <Border Background="#2A7AA6" BorderBrush="#61B7E6" BorderThickness="1.5" CornerRadius="7" Padding="26,3">
                          <TextBlock Text="AJUSTES" Foreground="#FFFFFF" FontSize="15.5" FontWeight="Bold">
                            <TextBlock.Effect>
                              <DropShadowEffect Color="#0A0D19" ShadowDepth="2" BlurRadius="0" Direction="315"/>
                            </TextBlock.Effect>
                          </TextBlock>
                        </Border>
                      </Border>

                      <Button x:Name="BtnHubStar4" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,9,11,0" Background="Transparent" BorderThickness="0" Padding="2" Cursor="Hand" ToolTip="Ajustes del sistema">
                        <Image x:Name="ImgHubStar4" Width="19" Height="17" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                      </Button>
                    </Grid>
                  </Grid>

                  <!-- ============================================================ -->
                  <!-- PÁGINA 1: SERIES -> TEMAS -> IMÁGENES POR PANTALLA            -->
                  <!-- ============================================================ -->
                  <ScrollViewer x:Name="PageMundos" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Margin="0,0,6,0">
                      <StackPanel x:Name="PanelSeries">
                        <TextBlock Text="Elige tu Serie o Universo" Foreground="#F4F0E4" FontSize="17" FontWeight="Bold"/>
                        <TextBlock Text="Selecciona un anime o universo. Si incluye varios escenarios podrás elegir mundo; si solo tiene uno pasarás directo a asignar escenas." Foreground="#96ACC8" FontSize="12" Margin="0,4,0,14" TextWrapping="Wrap" LineHeight="17"/>
                        <StackPanel x:Name="ListaSeries"/>
                      </StackPanel>

                      <StackPanel x:Name="PanelTemasSerie" Visibility="Collapsed">
                        <DockPanel Margin="0,0,0,12">
                          <Button x:Name="BtnVolverASeries" Content="← Series" Style="{StaticResource PillBtn}" DockPanel.Dock="Left" Margin="0,0,12,0"/>
                          <TextBlock x:Name="TxtSerieTitulo" Text="Mushoku Tensei" Foreground="#F4F0E4" FontSize="17" FontWeight="Bold" VerticalAlignment="Center"/>
                        </DockPanel>
                        <TextBlock Text="Esta serie cuenta con varios escenarios pixel art. Pulsa el que quieras personalizar:" Foreground="#96ACC8" FontSize="12" Margin="0,0,0,14" TextWrapping="Wrap"/>
                        <StackPanel x:Name="ListaTarjetasMundos"/>
                      </StackPanel>

                      <StackPanel x:Name="PanelImagenesTema" Visibility="Collapsed">
                        <DockPanel Margin="0,0,0,10">
                          <Button x:Name="BtnVolverDeImagenes" Content="← Volver" Style="{StaticResource PillBtn}" DockPanel.Dock="Left" Margin="0,0,12,0"/>
                          <TextBlock x:Name="TxtTemaImagenesTitulo" Text="Región de Fittoa" Foreground="#F4F0E4" FontSize="16.5" FontWeight="Bold" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                        </DockPanel>
                        <TextBlock Text="Asigna libremente cualquiera de las 3 escenas a cada monitor y a la pantalla de bloqueo:" Foreground="#96ACC8" FontSize="12" Margin="0,0,0,10" TextWrapping="Wrap"/>

                        <WrapPanel Margin="0,0,0,12">
                          <Button x:Name="BtnPresetClasico" Content="✦ Clásica (1·2·3)" Style="{StaticResource PillBtn}" Foreground="#7CF6EE" BorderBrush="#397D88" Margin="0,0,6,6" FontSize="11"/>
                          <Button x:Name="BtnRepetirPrincipal" Content="✨ Usar Escena 1 en todas" Style="{StaticResource PillBtn}" Margin="0,0,6,6" FontSize="11"/>
                          <Button x:Name="BtnRepetirSecundaria" Content="✨ Usar Escena 2 en todas" Style="{StaticResource PillBtn}" Margin="0,0,6,6" FontSize="11"/>
                          <Button x:Name="BtnRepetirBloqueo" Content="✨ Usar Escena 3 en todas" Style="{StaticResource PillBtn}" Margin="0,0,0,6" FontSize="11"/>
                        </WrapPanel>

                        <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="12" Margin="0,0,0,10">
                          <StackPanel>
                            <TextBlock Text="🖥️ MONITOR PRINCIPAL" Foreground="#54DED4" FontSize="11.5" FontWeight="Bold" Margin="0,0,0,8"/>
                            <UniformGrid x:Name="GridPickerM1" Columns="3"/>
                          </StackPanel>
                        </Border>

                        <Border x:Name="PanelPickerM2" Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="12" Margin="0,0,0,10">
                          <StackPanel>
                            <TextBlock Text="🖥️ MONITOR SECUNDARIO" Foreground="#F6C84C" FontSize="11.5" FontWeight="Bold" Margin="0,0,0,8"/>
                            <UniformGrid x:Name="GridPickerM2" Columns="3"/>
                          </StackPanel>
                        </Border>

                        <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="12" Margin="0,0,0,12">
                          <StackPanel>
                            <DockPanel Margin="0,0,0,8">
                              <CheckBox x:Name="ChkBloqueoMenu" Content="🔒 PANTALLA DE BLOQUEO DE WINDOWS" FontSize="11.5" FontWeight="Bold" Foreground="#88C8FF" Margin="0"/>
                            </DockPanel>
                            <UniformGrid x:Name="GridPickerBloq" Columns="3"/>
                          </StackPanel>
                        </Border>

                        <Button x:Name="BtnIrAPantallasLuz" Content="⚙️ Ajustar monitores y ciclo horario de luz →" Style="{StaticResource PillBtn}" HorizontalAlignment="Left" Margin="0,2,0,4"/>
                      </StackPanel>
                    </StackPanel>
                  </ScrollViewer>

                  <!-- ============================================================ -->
                  <!-- PÁGINA 2: PANTALLAS Y LUZ                                     -->
                  <!-- ============================================================ -->
                  <ScrollViewer x:Name="PagePantallas" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Margin="0,0,6,0">
                      <TextBlock Text="Disposición de Pantallas" Foreground="#F4F0E4" FontSize="17" FontWeight="Bold"/>
                      <TextBlock Text="En modo 2 pantallas, tu monitor principal muestra la escena base y el segundo continúa la historia sin repetirse." Foreground="#96ACC8" FontSize="12" Margin="0,4,0,12" TextWrapping="Wrap"/>

                      <Border x:Name="CardMon1" Background="#111C38" BorderBrush="#2F4678" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,8" Cursor="Hand">
                        <StackPanel>
                          <RadioButton x:Name="RbMon1" GroupName="Mon" Content="Solo 1 Pantalla (Únicamente monitor principal)" FontWeight="SemiBold"/>
                          <TextBlock Text="Ideal para portátiles o si prefieres animar un único escritorio." Foreground="#96ACC8" FontSize="11.5" Margin="28,3,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                      </Border>

                      <Border x:Name="CardMon2" Background="#111C38" BorderBrush="#2F4678" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,16" Cursor="Hand">
                        <StackPanel>
                          <RadioButton x:Name="RbMon2" GroupName="Mon" Content="2 Pantallas (Principal + Continuación extendida)" FontWeight="SemiBold"/>
                          <TextBlock x:Name="TxtMon2Detalle" Text="Detectando pantallas..." Foreground="#54DED4" FontSize="11.5" Margin="28,3,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                      </Border>

                      <TextBlock Text="Escena por Pantalla y Bloqueo" Foreground="#F4F0E4" FontSize="16" FontWeight="Bold" Margin="0,2,0,4"/>
                      <TextBlock Text="Cada mundo tiene 3 escenas independientes (Principal, Secundaria y Bloqueo)." Foreground="#96ACC8" FontSize="12" Margin="0,0,0,10" TextWrapping="Wrap"/>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,16">
                        <StackPanel>
                          <TextBlock Text="🖥️ Pantalla Principal" Foreground="#54DED4" FontSize="12" FontWeight="Bold" Margin="0,0,0,5"/>
                          <ComboBox x:Name="CmbFondoPrincipal" FontSize="12" Height="34" Margin="0,0,0,12">
                            <ComboBoxItem Content="Principal" Tag="principal"/>
                            <ComboBoxItem Content="Secundaria" Tag="secundaria"/>
                            <ComboBoxItem Content="Bloqueo" Tag="bloqueo"/>
                          </ComboBox>

                          <StackPanel x:Name="PanelComboSec">
                            <TextBlock Text="🖥️ Pantalla Secundaria" Foreground="#F6C84C" FontSize="12" FontWeight="Bold" Margin="0,0,0,5"/>
                            <ComboBox x:Name="CmbFondoSecundaria" FontSize="12" Height="34" Margin="0,0,0,10">
                              <ComboBoxItem Content="Principal" Tag="principal"/>
                              <ComboBoxItem Content="Secundaria" Tag="secundaria"/>
                              <ComboBoxItem Content="Bloqueo" Tag="bloqueo"/>
                            </ComboBox>
                            <TextBlock Text="🌍 Mundo independiente en Monitor 2 (opcional)" Foreground="#A8B8CF" FontSize="11.5" Margin="0,0,0,4"/>
                            <ComboBox x:Name="CmbTemaSec" FontSize="12" Height="34" Margin="0,0,0,12"/>
                          </StackPanel>

                          <CheckBox x:Name="ChkBloqueo" Content="🔒 Aplicar también fondo a la Pantalla de Bloqueo de Windows" FontWeight="SemiBold" Margin="0,2,0,8"/>
                          <StackPanel x:Name="PanelComboBloq">
                            <ComboBox x:Name="CmbFondoBloqueo" FontSize="12" Height="34" Margin="0,0,0,0">
                              <ComboBoxItem Content="Principal" Tag="principal"/>
                              <ComboBoxItem Content="Secundaria" Tag="secundaria"/>
                              <ComboBoxItem Content="Bloqueo" Tag="bloqueo"/>
                            </ComboBox>
                          </StackPanel>
                        </StackPanel>
                      </Border>

                      <TextBlock Text="Ciclo de Luz del Cielo" Foreground="#F4F0E4" FontSize="16" FontWeight="Bold" Margin="0,2,0,4"/>
                      <TextBlock Text="Controla cómo evoluciona la escena entre Día, Atardecer Dorado y Noche estrellada." Foreground="#96ACC8" FontSize="12" Margin="0,0,0,10" TextWrapping="Wrap"/>

                      <ComboBox x:Name="CmbModo" FontSize="12.5" Height="36" Margin="0,0,0,10">
                        <ComboBoxItem Content="🌗 Ciclo suave — Día y noche cada 90 min (Recomendado)" Tag="90m"/>
                        <ComboBoxItem Content="🕒 Hora real — Igual que el reloj de tu Windows" Tag="real"/>
                        <ComboBoxItem Content="⚡ Paseo rápido — Cambia en 90 segundos para probar" Tag="demo"/>
                        <ComboBoxItem Content="🔒 Momento fijo — Elige tú Día, Atardecer o Noche" Tag="fija"/>
                      </ComboBox>

                      <Border x:Name="PanelHora" Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,2,0,0">
                        <StackPanel>
                          <TextBlock Text="Elige el momento fijo que prefieras:" Foreground="#F6C84C" FontSize="12" FontWeight="Bold" Margin="0,0,0,10"/>
                          <StackPanel Orientation="Horizontal" Margin="0,0,0,12">
                            <Button x:Name="BtnFijarDia" Content="☀️ Día (13:00)" Style="{StaticResource PillBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="BtnFijarDor" Content="🌅 Atardecer (18:30)" Style="{StaticResource PillBtn}" Margin="0,0,6,0"/>
                            <Button x:Name="BtnFijarNoc" Content="🌙 Noche (22:00)" Style="{StaticResource PillBtn}"/>
                          </StackPanel>
                          <DockPanel>
                            <TextBlock x:Name="TxtHoraVal" Text="21:30" Foreground="#54DED4" FontFamily="Consolas" FontSize="14" FontWeight="Bold" DockPanel.Dock="Right" Width="56" TextAlignment="Right" VerticalAlignment="Center"/>
                            <Slider x:Name="SldHora" Minimum="0" Maximum="23.75" TickFrequency="0.25" IsSnapToTickEnabled="True" Value="21.5"/>
                          </DockPanel>
                        </StackPanel>
                      </Border>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,12,0,0">
                        <StackPanel>
                          <TextBlock Text="Clima Dinámico &amp; Rotación Automática" Foreground="#54DED4" FontSize="13.5" FontWeight="Bold" Margin="0,0,0,8"/>
                          <TextBlock Text="🌦️ Clima atmosférico sobre el escenario" Foreground="#A8B8CF" FontSize="11.5" Margin="0,0,0,4"/>
                          <ComboBox x:Name="CmbClima" FontSize="12" Height="34" Margin="0,0,0,12">
                            <ComboBoxItem Content="✨ Despejado (Original del mundo)" Tag="normal"/>
                            <ComboBoxItem Content="🌧️ Lluvia suave en tiempo real" Tag="lluvia"/>
                            <ComboBoxItem Content="⛈️ Tormenta con relámpagos" Tag="tormenta"/>
                            <ComboBoxItem Content="❄️ Nevadas suaves de invierno" Tag="nieve"/>
                            <ComboBoxItem Content="🌫️ Niebla nocturna misteriosa" Tag="niebla"/>
                            <ComboBoxItem Content="🌋 Ceniza volcánica / brasas" Tag="ceniza"/>
                            <ComboBoxItem Content="🤖 Automático por universo y hora" Tag="auto"/>
                          </ComboBox>
                          <TextBlock Text="🔀 Playlist — Cambio automático de mundo" Foreground="#A8B8CF" FontSize="11.5" Margin="0,0,0,4"/>
                          <ComboBox x:Name="CmbRotacion" FontSize="12" Height="34">
                            <ComboBoxItem Content="🔒 Desactivado — Mantener mundo elegido" Tag="0"/>
                            <ComboBoxItem Content="⏱️ Rotar cada 5 minutos" Tag="5"/>
                            <ComboBoxItem Content="⏱️ Rotar cada 15 minutos" Tag="15"/>
                            <ComboBoxItem Content="⏱️ Rotar cada 30 minutos" Tag="30"/>
                            <ComboBoxItem Content="🕒 Rotar cada hora" Tag="60"/>
                          </ComboBox>
                        </StackPanel>
                      </Border>
                    </StackPanel>
                  </ScrollViewer>

                  <!-- ============================================================ -->
                  <!-- PÁGINA 3: WIDGETS / CAJITAS DEL ESCRITORIO (HUD)              -->
                  <!-- ============================================================ -->
                  <ScrollViewer x:Name="PageHud" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Margin="0,0,6,0">
                      <DockPanel Margin="0,0,0,4">
                        <TextBlock Text="Tarjetas Flotantes (HUD)" Foreground="#F4F0E4" FontSize="17" FontWeight="Bold" VerticalAlignment="Center"/>
                        <CheckBox x:Name="ChkHudMaster" Content="Activadas" DockPanel.Dock="Right" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#54DED4" Margin="0"/>
                      </DockPanel>
                      <TextBlock Text="Transparentes al ratón: puedes hacer clic a través de ellas en tu escritorio. Mira su distribución en el estudio a la derecha." Foreground="#96ACC8" FontSize="12" Margin="0,2,0,12" TextWrapping="Wrap"/>

                      <Border x:Name="CardSoloWidgets" Background="#16264C" BorderBrush="#54DED4" BorderThickness="1.5" CornerRadius="10" Padding="12,10" Margin="0,0,0,12">
                        <DockPanel>
                          <Button x:Name="BtnActivarSoloWidgets" DockPanel.Dock="Right" Content="⚡ Activar Solo Widgets" Style="{StaticResource PillBtn}" Foreground="#061217" Background="#54DED4" BorderBrush="#88FFF4" FontWeight="Bold" VerticalAlignment="Center" Margin="10,0,0,0" Padding="12,6"/>
                          <StackPanel>
                            <CheckBox x:Name="ChkSoloWidgets" Content="🧩 Modo Solo Widgets (Usar con Wallpaper Engine o mi propio fondo)" FontWeight="Bold" Foreground="#7CF6EE" Margin="0,0,0,3"/>
                            <TextBlock Text="Superpone las tarjetas HUD sobre tu fondo actual sin cambiar el fondo de Windows ni iniciar el motor de escenas de PixelZen." Foreground="#B8CBE8" FontSize="11" Margin="28,0,0,0" TextWrapping="Wrap"/>
                          </StackPanel>
                        </DockPanel>
                      </Border>

                      <WrapPanel Margin="0,0,0,10">
                        <Button x:Name="BtnHudTodas" Content="✦ Mostrar todas (9)" Style="{StaticResource PillBtn}" Margin="0,0,6,6"/>
                        <Button x:Name="BtnHudMinimo" Content="Modo limpio (Reloj + Frase)" Style="{StaticResource PillBtn}" Margin="0,0,6,6"/>
                        <Button x:Name="BtnHudSoloReloj" Content="Solo Reloj" Style="{StaticResource PillBtn}" Margin="0,0,0,6"/>
                      </WrapPanel>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="11" Margin="0,0,0,12">
                        <StackPanel>
                          <CheckBox x:Name="ChkCompactoHud" Content="🗜️ Modo HUD compacto + paleta adaptada al mundo" FontWeight="SemiBold" Margin="0,0,0,4"/>
                          <CheckBox x:Name="ChkAudioReactivo" Content="🎵 Pulsar efectos visuales de combate/partículas con audio" FontWeight="SemiBold" Margin="0"/>
                        </StackPanel>
                      </Border>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkTiempo" Content="🕒 Reloj, fecha y nombre del mundo" FontWeight="SemiBold"/>
                          <TextBlock Text="Muestra la hora grande, la fecha en español y el escenario activo." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkClima" Content="☀️ Órbita solar y fase lumínica" FontWeight="SemiBold"/>
                          <TextBlock Text="Elevación del sol, azimut y fase atmosférica actual del mundo." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkSistema" Content="💻 Rendimiento del PC (CPU, RAM, Disco, Batería)" FontWeight="SemiBold"/>
                          <TextBlock Text="Barras visuales en tiempo real para controlar la carga del equipo." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkGpu" Content="🎮 GPU y motor gráfico" FontWeight="SemiBold"/>
                          <TextBlock Text="Tarjeta gráfica detectada, FPS activos y carga visual del motor." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkRed" Content="🌐 Conexión e Internet (Wi-Fi / IP / Velocidad)" FontWeight="SemiBold"/>
                          <TextBlock Text="Muestra tu red activa, IP local y tráfico de subida/bajada." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkAudio" Content="🎵 Música y banda sonora del mundo" FontWeight="SemiBold"/>
                          <TextBlock Text="Tema BSO acorde al universo elegido o reproductor activo." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkDev" Content="🛠️ Información técnica / Programador" FontWeight="SemiBold"/>
                          <TextBlock Text="Nombre del equipo, rama Git actual y entorno detectado." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13" Margin="0,0,0,9">
                        <StackPanel>
                          <CheckBox x:Name="ChkFoco" Content="⏱️ Temporizador Zen / Sesión (Pomodoro)" FontWeight="SemiBold"/>
                          <TextBlock Text="Cuenta atrás de 25 minutos por ciclos y tiempo de sesión activa." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="13">
                        <StackPanel>
                          <CheckBox x:Name="ChkGrimorio" Content="📖 Frase del universo (Grimorio)" FontWeight="SemiBold"/>
                          <TextBlock Text="Citas icónicas de la serie que rotan automáticamente." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,0"/>
                        </StackPanel>
                      </Border>
                    </StackPanel>
                  </ScrollViewer>

                  <!-- ============================================================ -->
                  <!-- PÁGINA 4: AJUSTES E INICIO                                    -->
                  <!-- ============================================================ -->
                  <ScrollViewer x:Name="PageSistema" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Margin="0,0,6,0">
                      <TextBlock Text="Comodidad e Inicio Automático" Foreground="#F4F0E4" FontSize="17" FontWeight="Bold"/>
                      <TextBlock Text="Deja PixelZen listo para iniciarse sin consolas al encender Windows." Foreground="#96ACC8" FontSize="12" Margin="0,4,0,14" TextWrapping="Wrap"/>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,10">
                        <StackPanel>
                          <TextBlock Text="Acceso directo en el Escritorio" Foreground="#F6C84C" FontSize="13.5" FontWeight="Bold" Margin="0,0,0,4"/>
                          <TextBlock Text="Crea un icono en tu Escritorio para abrir este estudio con un doble clic." Foreground="#96ACC8" FontSize="11.5" Margin="0,0,0,10" TextWrapping="Wrap"/>
                          <Button x:Name="BtnAccesoDirecto" Content="📌 Crear acceso directo en mi Escritorio" Style="{StaticResource PillBtn}" HorizontalAlignment="Left" Foreground="#54DED4" BorderBrush="#3C8D96"/>
                        </StackPanel>
                      </Border>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,10">
                        <StackPanel>
                          <CheckBox x:Name="ChkAutoInicio" Content="🚀 Aplicar fondos e iniciar en bandeja al encender Windows" FontWeight="SemiBold"/>
                          <TextBlock Text="Restaura automáticamente tus fondos animados y tarjetas al iniciar sesión." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,10" TextWrapping="Wrap"/>
                          <CheckBox x:Name="ChkTrayCerrar" Content="📌 Al pulsar cerrar (X), minimizar junto al reloj en vez de salir" FontWeight="SemiBold"/>
                          <TextBlock Text="Permite cambiar de mundo o activar el HUD en un clic desde la bandeja." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,10" TextWrapping="Wrap"/>
                          <CheckBox x:Name="ChkPausaJuego" Content="🎮 Pausar motor (0% CPU) con juegos/apps a pantalla completa o batería baja" FontWeight="SemiBold"/>
                          <TextBlock Text="Detiene el renderizado mientras juegas o ves vídeos a pantalla completa y ahorra batería." Foreground="#96ACC8" FontSize="11.5" Margin="48,0,0,10" TextWrapping="Wrap"/>
                          <CheckBox x:Name="ChkHotkeys" Content="⌨️ Atajos globales (Ctrl+Alt + W: Mundo · H: HUD · F: Clima · P: Pausa · E: Evento)" FontWeight="SemiBold"/>
                        </StackPanel>
                      </Border>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14" Margin="0,0,0,10">
                        <StackPanel>
                          <TextBlock Text="Eventos Épicos en Tiempo Real" Foreground="#F6C84C" FontSize="13.5" FontWeight="Bold" Margin="0,0,0,4"/>
                          <TextBlock Text="Dispara un cometa, círculo de invocación o anomalía dimensional sobre tu escritorio." Foreground="#96ACC8" FontSize="11.5" Margin="0,0,0,10" TextWrapping="Wrap"/>
                          <Button x:Name="BtnEventoAhora" Content="✦ Disparar evento épico ahora" Style="{StaticResource PillBtn}" HorizontalAlignment="Left" Foreground="#F6C86E" BorderBrush="#E6B45A"/>
                        </StackPanel>
                      </Border>

                      <Border Background="#111C38" BorderBrush="#2B4270" BorderThickness="1.5" CornerRadius="10" Padding="14">
                        <StackPanel>
                          <TextBlock Text="Estado del sistema y actualizaciones" Foreground="#F6C84C" FontSize="13.5" FontWeight="Bold" Margin="0,0,0,8"/>
                          <TextBlock x:Name="TxtDiag" Text="" Foreground="#C4D2E6" FontSize="12" TextWrapping="Wrap" LineHeight="20" Margin="0,0,0,12"/>
                          <StackPanel Orientation="Horizontal">
                            <Button x:Name="BtnBuscarUpdate" Content="⬆️ Actualizar" Visibility="Collapsed" Style="{StaticResource PillBtn}" Foreground="#54DED4" BorderBrush="#3C8D96" Margin="0,0,8,0"/>
                            <Button x:Name="BtnRestaurar" Content="Restablecer recomendados" Style="{StaticResource PillBtn}"/>
                          </StackPanel>
                        </StackPanel>
                      </Border>
                    </StackPanel>
                  </ScrollViewer>
                </Grid>
              </Grid>

              <!-- ESTUDIO EN VIVO (Columna Derecha en subpáginas) -->
              <Border x:Name="ColPreviewBorder" Grid.Column="2" Visibility="Collapsed" Background="#10172F" BorderBrush="#2B3E6E" BorderThickness="1.5" CornerRadius="10" Padding="12">
                <DockPanel>
                  <DockPanel DockPanel.Dock="Top" Margin="0,0,0,8">
                    <TextBlock Text="ESCRITORIO EN VIVO" Foreground="#54DED4" FontSize="11.5" FontWeight="Bold" VerticalAlignment="Center"/>
                    <Border DockPanel.Dock="Right" HorizontalAlignment="Right" Background="#080D1B" BorderBrush="#283B66" BorderThickness="1" CornerRadius="7" Padding="2">
                      <StackPanel Orientation="Horizontal">
                        <Button x:Name="BtnPrevDia" Content="☀️ Día" Style="{StaticResource PillBtn}" Padding="6,2" FontSize="10" Margin="0,0,2,0"/>
                        <Button x:Name="BtnPrevDor" Content="🌅 Dorado" Style="{StaticResource PillBtn}" Padding="6,2" FontSize="10" Margin="0,0,2,0"/>
                        <Button x:Name="BtnPrevNoc" Content="🌙 Noche" Style="{StaticResource PillBtn}" Padding="6,2" FontSize="10"/>
                      </StackPanel>
                    </Border>
                  </DockPanel>

                  <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="0,0,2,0">
                      <DockPanel Margin="0,0,0,4">
                        <TextBlock x:Name="TxtPrev1Title" Text="PANTALLA 1" Foreground="#F6C84C" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                        <Border DockPanel.Dock="Right" HorizontalAlignment="Right" Background="#12303D" CornerRadius="4" Padding="6,1" Margin="6,0,0,0">
                          <TextBlock Text="PRINCIPAL" Foreground="#54DED4" FontSize="9" FontWeight="Bold"/>
                        </Border>
                      </DockPanel>
                      <Border BorderBrush="#49C8C0" BorderThickness="1.5" CornerRadius="7" Background="#040711" Height="142" Margin="0,0,0,7" ClipToBounds="True">
                        <Grid>
                          <Image x:Name="ImgPrev1" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                          <StackPanel x:Name="MockHudPanel" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,5,6,0" Width="104">
                            <Border x:Name="MockTiempo" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1.5" Margin="0,0,0,1.5">
                              <StackPanel>
                                <TextBlock Text="21:34" Foreground="#F4F0E4" FontFamily="Consolas" FontSize="8" FontWeight="Bold"/>
                                <TextBlock x:Name="TxtMockMundo" Text="Fittoa" Foreground="#E6C06E" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                              </StackPanel>
                            </Border>
                            <Border x:Name="MockClima" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="☀ SOL +18° DÍA" Foreground="#E6C06E" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockSistema" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="❖ CPU 12% RAM 48%" Foreground="#72C48C" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockGpu" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="▣ GTX 1650 · 44°C" Foreground="#66DCE0" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockRed" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="◈ ETH 192.168.1.38" Foreground="#54DED4" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockAudio" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="♪ SPOTIFY EN VIVO" Foreground="#72C48C" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockDev" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="⚔ DEV · main" Foreground="#A8B8CF" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockFoco" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1" Margin="0,0,0,1.5">
                              <TextBlock Text="⧖ ZEN 25:00" Foreground="#54DED4" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                            <Border x:Name="MockGrimorio" Background="#D8090F20" BorderBrush="#8A6E44" BorderThickness="1" CornerRadius="3" Padding="4,1">
                              <TextBlock Text="«Frase del mundo...»" Foreground="#E6C06E" FontFamily="Consolas" FontSize="5.5" TextTrimming="CharacterEllipsis"/>
                            </Border>
                          </StackPanel>
                          <Border VerticalAlignment="Bottom" Height="6" Background="#90070B16">
                            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                              <Border Width="4" Height="2.5" Background="#54DED4" Margin="2,0"/>
                              <Border Width="4" Height="2.5" Background="#A8B8CF" Margin="2,0"/>
                              <Border Width="4" Height="2.5" Background="#E6B45A" Margin="2,0"/>
                            </StackPanel>
                          </Border>
                        </Grid>
                      </Border>

                      <StackPanel x:Name="PanelPrev2" Margin="0,0,0,7">
                        <DockPanel Margin="0,0,0,4">
                          <TextBlock x:Name="TxtPrev2Title" Text="PANTALLA 2 · HISTORIA EXTENDIDA" Foreground="#F6C84C" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                          <Border DockPanel.Dock="Right" HorizontalAlignment="Right" Background="#2B2112" CornerRadius="4" Padding="6,1" Margin="6,0,0,0">
                            <TextBlock Text="MONITOR 2" Foreground="#E6B45A" FontSize="9" FontWeight="Bold"/>
                          </Border>
                        </DockPanel>
                        <Border BorderBrush="#8A6E44" BorderThickness="1.5" CornerRadius="7" Background="#040711" Height="110" ClipToBounds="True">
                          <Image x:Name="ImgPrev2" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                        </Border>
                        <TextBlock x:Name="TxtM2Sub" Visibility="Collapsed" Text=""/>
                      </StackPanel>

                      <StackPanel x:Name="PanelPrevBloqueo">
                        <DockPanel Margin="0,0,0,4">
                          <TextBlock x:Name="TxtPrevBloqTitle" Text="🔒 PANTALLA DE BLOQUEO" Foreground="#88C8FF" FontSize="10.5" FontWeight="Bold" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                          <Border DockPanel.Dock="Right" HorizontalAlignment="Right" Background="#132440" CornerRadius="4" Padding="6,1" Margin="6,0,0,0">
                            <TextBlock Text="WINDOWS LOCK" Foreground="#88C8FF" FontSize="9" FontWeight="Bold"/>
                          </Border>
                        </DockPanel>
                        <Border BorderBrush="#4C6FA8" BorderThickness="1.5" CornerRadius="7" Background="#040711" Height="88" ClipToBounds="True">
                          <Grid>
                            <Image x:Name="ImgPrevBloqueo" Stretch="UniformToFill" RenderOptions.BitmapScalingMode="NearestNeighbor"/>
                            <Border Background="#38040814"/>
                            <StackPanel HorizontalAlignment="Center" VerticalAlignment="Top" Margin="0,8,0,0">
                              <TextBlock Text="21:34" Foreground="#F6F4EA" FontSize="18" FontWeight="Bold" HorizontalAlignment="Center"/>
                              <TextBlock Text="Pantalla de bloqueo de Windows" Foreground="#D4E2F6" FontSize="8.5" HorizontalAlignment="Center"/>
                            </StackPanel>
                          </Grid>
                        </Border>
                        <TextBlock x:Name="TxtBloqSub" Visibility="Collapsed" Text=""/>
                      </StackPanel>
                    </StackPanel>
                  </ScrollViewer>
                </DockPanel>
              </Border>
            </Grid>

            <!-- Barra Inferior de Acciones Pixelzen -->
            <Border Grid.Row="1" Background="#1A2240" BorderBrush="#0A0D19" BorderThickness="0,3,0,0" Padding="14,8">
              <DockPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Left" VerticalAlignment="Center">
                  <Button x:Name="BtnWeb" Content="🎬 Visor Web" Style="{StaticResource PillBtn}" Foreground="#54DED4" BorderBrush="#397D88" Margin="0,0,6,0" Padding="10,5"/>
                  <Button x:Name="BtnToggleHudNow" Content="👁️ Ocultar HUD" Style="{StaticResource PillBtn}" Margin="0,0,6,0" Padding="10,5"/>
                  <Button x:Name="BtnSoloWidgetsBar" Content="🧩 Solo Widgets" Style="{StaticResource PillBtn}" Foreground="#7CF6EE" BorderBrush="#3C8D96" Margin="0,0,8,0" Padding="10,5" ToolTip="Poner solo los widgets por encima de Wallpaper Engine o tu fondo actual"/>
                  <TextBlock x:Name="TxtEstado" Text="Listo — Elige un tema y pulsa Aplicar." Foreground="#72E6AE" FontSize="11.5" VerticalAlignment="Center" MaxWidth="300" TextTrimming="CharacterEllipsis"/>
                </StackPanel>

                <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" HorizontalAlignment="Right" VerticalAlignment="Center">
                  <Button x:Name="BtnSoloGuardar" Content="💾 Guardar" Style="{StaticResource PillBtn}" Margin="0,0,8,0" Padding="12,5"/>
                  <Button x:Name="BtnAplicar" Content="✦ APLICAR A MI ESCRITORIO" Padding="18,6" FontSize="12.5" FontWeight="Bold" Foreground="#061217" Cursor="Hand">
                    <Button.Template>
                      <ControlTemplate TargetType="Button">
                        <Border Background="#0A0D19" CornerRadius="8" Padding="1.5">
                          <Border x:Name="CtaBd" CornerRadius="6.5" BorderBrush="#88FFF4" BorderThickness="1.5" Padding="{TemplateBinding Padding}">
                            <Border.Background>
                              <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                <GradientStop Color="#47DBD0" Offset="0"/>
                                <GradientStop Color="#6CF7EE" Offset="1"/>
                              </LinearGradientBrush>
                            </Border.Background>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                          </Border>
                        </Border>
                        <ControlTemplate.Triggers>
                          <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="CtaBd" Property="Background">
                              <Setter.Value>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                  <GradientStop Color="#6BF2E8" Offset="0"/>
                                  <GradientStop Color="#A2FFF9" Offset="1"/>
                                </LinearGradientBrush>
                              </Setter.Value>
                            </Setter>
                          </Trigger>
                          <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="CtaBd" Property="Opacity" Value="0.88"/>
                          </Trigger>
                        </ControlTemplate.Triggers>
                      </ControlTemplate>
                    </Button.Template>
                  </Button>
                </StackPanel>
              </DockPanel>
            </Border>
          </Grid>
        </Grid>
      </Grid>
    </Border>
  </Border>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$win = [System.Windows.Markup.XamlReader]::Load($reader)
if (Test-Path $IconPath) {
    try { $win.Icon = [System.Windows.Media.Imaging.BitmapFrame]::Create((New-Object Uri($IconPath))) } catch {}
}

# Barra de título oscura nativa en Windows 11/10
$dwmCode = @'
using System;
using System.Runtime.InteropServices;
public static class PzWinTheme {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public static void SendMediaKey(byte vk) {
        keybd_event(vk, 0, 0, UIntPtr.Zero);
        keybd_event(vk, 0, 2, UIntPtr.Zero);
    }
    public static void ApplyDarkTitlebar(IntPtr hwnd) {
        if (hwnd == IntPtr.Zero) return;
        int dark = 1;
        DwmSetWindowAttribute(hwnd, 20, ref dark, 4);
        int captionColor = 0x00130906; // BGR de #060913
        DwmSetWindowAttribute(hwnd, 35, ref captionColor, 4);
        int textColor = 0x00D6EAF3; // BGR de #F3EAD6
        DwmSetWindowAttribute(hwnd, 36, ref textColor, 4);
    }
}
'@
Add-Type -TypeDefinition $dwmCode -ErrorAction SilentlyContinue
$win.Add_SourceInitialized({
    try {
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($win)).Handle
        [PzWinTheme]::ApplyDarkTitlebar($hwnd)
    } catch {}
})

$el = @{}
foreach ($n in 'TitleBarBorder','TxtTitleBar','ImgTitleBonsai','BtnWinMin','BtnWinMax','ImgSideBonsaiTop','ImgSideBonsaiBottom','ImgNavHome','ImgNavMonitors','ImgNavSave','ImgNavGear','NavHub','ColPreviewGap','ColPreviewStudio','ColPreviewBorder','BarDetalleTop','BtnVolverHub','TxtDetalleTitle','PageHub','TxtHubTemasLista','BtnHubPrevTema','BtnHubNextTema','HubTemaCard1','HubTemaBevel1','ImgHubTema1','TxtHubTema1','HubTemaCard2','HubTemaBevel2','ImgHubTema2','TxtHubTema2','HubTemaCard3','HubTemaBevel3','ImgHubTema3','TxtHubTema3','BtnHubIrMundos','ImgHubStar1','HubCardAnimados','ImgHubAnimados','TxtHubAnimSub','HubCardEstaticos','ImgHubEstaticos','TxtHubEstSub','ImgPlantLeft','BtnHubExplorarPantallas','ImgFlowerRight','BtnHubStar2','ImgHubStar2','BtnHubIrWidgets','HubTileClock','TxtHubClock','TxtHubClockStatus','HubTileWeather','ImgHubWeather','TxtHubWeather','TxtHubWeatherSub','HubTileCat','ImgHubCat','TxtHubCatBadge','ImgSprout','BtnHubStar3','ImgHubStar3','BtnHubIrAjustes','ImgHubGear','BtnHubGen','TxtHubGenVal','BtnHubRend','TxtHubRendVal','BtnHubAtajos','TxtHubAtajosVal','BtnHubSldMenos','SldHubHora','BtnHubSldMas','BtnHubStar4','ImgHubStar4','TxtMonInfo','BadgeMotor','TxtMotorBadge','BtnMiniTray','BtnSalirTotal','NavMundos','NavPantallas','NavHud','NavSistema','TxtResumen','PageMundos','PagePantallas','PageHud','PageSistema','PanelSeries','ListaSeries','PanelTemasSerie','BtnVolverASeries','TxtSerieTitulo','PanelImagenesTema','BtnVolverDeImagenes','TxtTemaImagenesTitulo','BtnPresetClasico','BtnRepetirPrincipal','BtnRepetirSecundaria','BtnRepetirBloqueo','GridPickerM1','PanelPickerM2','GridPickerM2','ChkBloqueoMenu','GridPickerBloq','BtnIrAPantallasLuz','ListaTarjetasMundos','CardMon1','CardMon2','RbMon1','RbMon2','TxtMon2Detalle','CmbFondoPrincipal','PanelComboSec','CmbFondoSecundaria','CmbTemaSec','ChkBloqueo','PanelComboBloq','CmbFondoBloqueo','CmbModo','PanelHora','BtnFijarDia','BtnFijarDor','BtnFijarNoc','TxtHoraVal','SldHora','CmbClima','CmbRotacion','ChkHudMaster','CardSoloWidgets','ChkSoloWidgets','BtnActivarSoloWidgets','BtnHudTodas','BtnHudMinimo','BtnHudSoloReloj','ChkCompactoHud','ChkAudioReactivo','ChkTiempo','ChkClima','ChkSistema','ChkGpu','ChkRed','ChkAudio','ChkDev','ChkFoco','ChkGrimorio','BtnAccesoDirecto','ChkAutoInicio','ChkTrayCerrar','ChkPausaJuego','ChkHotkeys','BtnEventoAhora','TxtDiag','BtnBuscarUpdate','BtnRestaurar','BtnPrevDia','BtnPrevDor','BtnPrevNoc','TxtPrev1Title','ImgPrev1','MockHudPanel','MockClima','MockGpu','MockAudio','MockFoco','MockTiempo','TxtMockMundo','MockSistema','MockRed','MockDev','MockGrimorio','PanelPrev2','TxtPrev2Title','ImgPrev2','TxtM2Sub','PanelPrevBloqueo','TxtPrevBloqTitle','ImgPrevBloqueo','TxtBloqSub','TxtEstado','BtnWeb','BtnToggleHudNow','BtnSoloWidgetsBar','BtnSoloGuardar','BtnAplicar') {
    $el[$n] = $win.FindName($n)
}

# Asignar sprites pixel-art de la interfaz
$el.ImgTitleBonsai.Source     = $menuSprites.bonsai_circle
$el.ImgSideBonsaiTop.Source   = $menuSprites.bonsai_circle
$el.ImgSideBonsaiBottom.Source = $menuSprites.bonsai_pot
$el.ImgNavHome.Source         = $menuSprites.nav_home
$el.ImgNavMonitors.Source     = $menuSprites.nav_monitors
$el.ImgNavSave.Source         = $menuSprites.nav_save
$el.ImgNavGear.Source         = $menuSprites.gear
$el.ImgHubGear.Source         = $menuSprites.gear
$el.ImgHubStar1.Source        = $menuSprites.star
$el.ImgHubStar2.Source        = $menuSprites.star
$el.ImgHubStar3.Source        = $menuSprites.star
$el.ImgHubStar4.Source        = $menuSprites.star
$el.ImgPlantLeft.Source       = $menuSprites.plant_left
$el.ImgFlowerRight.Source     = $menuSprites.flower_right
$el.ImgSprout.Source          = $menuSprites.sprout
$el.ImgHubWeather.Source      = $menuSprites.weather
$el.ImgHubCat.Source          = $menuSprites.cat
$el.TxtTitleBar.Text          = "Pixelzen - Fondos & Widgets v$VersionActual"
$win.Title                    = "Pixelzen - Fondos & Widgets v$VersionActual"

$el.TitleBarBorder.Add_MouseLeftButtonDown({
    param($s, $e)
    if ($e.ClickCount -eq 2) {
        $win.WindowState = if ($win.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
    } else {
        try { $win.DragMove() } catch {}
    }
})
$el.BtnWinMin.Add_Click({ $win.WindowState = 'Minimized' })
$el.BtnWinMax.Add_Click({
    $win.WindowState = if ($win.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }
})

$el.TxtMonInfo.Text = $monSummary
if ($screens.Count -ge 2) {
    $el.TxtMon2Detalle.Text = "¡Genial! Hemos detectado $($screens.Count) pantallas listas para la historia doble."
} else {
    $el.TxtMon2Detalle.Text = "Ahora solo hay 1 pantalla conectada, pero si conectas una segunda se activará la continuación."
}

function Cargar-Bitmap($ruta) {
    if (-not (Test-Path $ruta)) { return $null }
    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
    $bmp.BeginInit()
    $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bmp.UriSource = New-Object Uri($ruta)
    $bmp.EndInit()
    return $bmp
}

$cfg = Cargar-Config
$script:selectedTema = if ($cfg.tema) { $cfg.tema } else { 'fittoa' }
$initTemaObj = $temas | Where-Object { $_.id -eq $script:selectedTema } | Select-Object -First 1
$script:selectedSerie = if ($initTemaObj) { $initTemaObj.serie } else { $seriesList[0] }
$script:previewFase = Detectar-Fase $cfg.modo $cfg.horaFija
$script:mundoVista = 'series'
$script:syncingCombos = $false
$script:hubSlotIds = @('', '', '')
$initIdx = [Array]::IndexOf(@($temas | ForEach-Object { $_.id }), $script:selectedTema)
$script:hubPageIdx = if ($initIdx -ge 0) { [math]::Floor($initIdx / 3) } else { 0 }
$script:seriesCards = @{}
$script:seriesBadges = @{}
$script:worldCards = @{}
$script:worldBadges = @{}
$script:worldSeries = @{}
$script:pickerItems = @()

function New-CardBadge {
    $bc = [System.Windows.Media.BrushConverter]::new()
    $badge = New-Object System.Windows.Controls.Border
    $badge.Background = $bc.ConvertFromString('#183E46')
    $badge.BorderBrush = $bc.ConvertFromString('#54DED4')
    $badge.BorderThickness = [System.Windows.Thickness]::new(1)
    $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $badge.Padding = [System.Windows.Thickness]::new(5, 1, 5, 1)
    $badge.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    [System.Windows.Controls.DockPanel]::SetDock($badge, [System.Windows.Controls.Dock]::Right)
    $bTxt = New-Object System.Windows.Controls.TextBlock
    $bTxt.Text = 'ACTIVO'
    $bTxt.FontSize = 9
    $bTxt.FontWeight = [System.Windows.FontWeights]::Bold
    $bTxt.Foreground = $bc.ConvertFromString('#54DED4')
    $badge.Child = $bTxt
    return $badge
}

function New-CardThumb([string]$thumbPath, [int]$width = 108, [int]$height = 68) {
    $imgWrap = New-Object System.Windows.Controls.Border
    $imgWrap.CornerRadius = [System.Windows.CornerRadius]::new(5)
    $imgWrap.Height = $height
    if ($width -gt 0) { $imgWrap.Width = $width }
    $imgWrap.ClipToBounds = $true
    $imgWrap.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#060916')
    $thumb = New-Object System.Windows.Controls.Image
    $thumb.Stretch = [System.Windows.Media.Stretch]::UniformToFill
    [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($thumb, [System.Windows.Media.BitmapScalingMode]::NearestNeighbor)
    if ($thumbPath) { $thumb.Source = Cargar-Bitmap $thumbPath }
    $imgWrap.Child = $thumb
    return $imgWrap
}

function Attach-CardHover($bd) {
    $bd.Add_MouseEnter({
        param($s, $e)
        if (-not $s.IsHitTestVisible) { return }
        $bc = [System.Windows.Media.BrushConverter]::new()
        $s.Opacity = 1.0
        $s.BorderBrush = $bc.ConvertFromString('#7CF6EE')
    })
    $bd.Add_MouseLeave({
        param($s, $e)
        Actualiza-Vista
    })
}

# Paso 1: Construir tarjetas visuales por Serie
foreach ($sName in $seriesList) {
    $sTemas = $seriesByName[$sName]
    $repTema = $sTemas | Where-Object { $_.id -eq $script:selectedTema } | Select-Object -First 1
    if (-not $repTema) { $repTema = $sTemas[0] }

    $bdS = New-Object System.Windows.Controls.Border
    $bdS.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0E1730')
    $bdS.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $bdS.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $bdS.Padding = [System.Windows.Thickness]::new(11)
    $bdS.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    $bdS.Cursor = [System.Windows.Input.Cursors]::Hand

    $gS = New-Object System.Windows.Controls.Grid
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(142)
    $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::new(12)
    $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $null = $gS.ColumnDefinitions.Add($c1); $null = $gS.ColumnDefinitions.Add($c2); $null = $gS.ColumnDefinitions.Add($c3)

    $thumbPath = Resolver-Preview $repTema.id 'dorado' 'principal'
    if (-not $thumbPath) { $thumbPath = Resolver-Preview $repTema.id 'noche' 'principal' }
    $imgWrap = New-CardThumb $thumbPath 142 88
    [System.Windows.Controls.Grid]::SetColumn($imgWrap, 0)
    $null = $gS.Children.Add($imgWrap)

    $info = New-Object System.Windows.Controls.StackPanel
    $info.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $topRow = New-Object System.Windows.Controls.DockPanel
    $lblTitle = New-Object System.Windows.Controls.TextBlock
    $lblTitle.Text = $sName
    $lblTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F3EAD6')
    $lblTitle.FontSize = 15
    $lblTitle.FontWeight = [System.Windows.FontWeights]::Bold
    $null = $topRow.Children.Add($lblTitle)

    $badgeS = New-CardBadge
    $null = $topRow.Children.Add($badgeS)

    $lblSub = New-Object System.Windows.Controls.TextBlock
    if ($sTemas.Count -gt 1) {
        $titulos = ($sTemas | ForEach-Object { $_.titulo }) -join ' · '
        $lblSub.Text = "$($sTemas.Count) escenarios: $titulos"
    } else {
        $lblSub.Text = "Escenario único: $($sTemas[0].titulo)"
    }
    $lblSub.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#A6B9D6')
    $lblSub.FontSize = 12
    $lblSub.Margin = [System.Windows.Thickness]::new(0, 5, 0, 4)
    $lblSub.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

    $lblHint = New-Object System.Windows.Controls.TextBlock
    $lblHint.Text = if ($sTemas.Count -gt 1) { 'Explorar los mundos de esta serie →' } else { 'Elegir escenas de pantallas y bloqueo →' }
    $lblHint.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E6B45A')
    $lblHint.FontSize = 11
    $lblHint.FontWeight = [System.Windows.FontWeights]::SemiBold

    $null = $info.Children.Add($topRow)
    $null = $info.Children.Add($lblSub)
    $null = $info.Children.Add($lblHint)
    [System.Windows.Controls.Grid]::SetColumn($info, 2)
    $null = $gS.Children.Add($info)

    $bdS.Child = $gS
    $bdS.Tag = $sName
    $bdS.Add_MouseLeftButtonUp({
        param($sender, $e)
        $sNameClick = [string]$sender.Tag
        $script:selectedSerie = $sNameClick
        $listaS = $seriesByName[$sNameClick]
        if ($listaS.Count -gt 1) {
            if (-not ($listaS | Where-Object { $_.id -eq $script:selectedTema })) {
                $script:selectedTema = $listaS[0].id
            }
            Cambia-VistaMundo 'temas'
        } else {
            $script:selectedTema = $listaS[0].id
            Cambia-VistaMundo 'imagenes'
        }
        Actualiza-Vista
    })
    Attach-CardHover $bdS
    $script:seriesCards[$sName] = $bdS
    $script:seriesBadges[$sName] = $badgeS
    $null = $el.ListaSeries.Children.Add($bdS)
}

# Paso 2: Construir tarjetas visuales de mundos (filtradas por Serie)
foreach ($t in $temas) {
    $tid = $t.id
    $bd = New-Object System.Windows.Controls.Border
    $bd.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#0E1730')
    $bd.BorderThickness = [System.Windows.Thickness]::new(1.5)
    $bd.CornerRadius = [System.Windows.CornerRadius]::new(10)
    $bd.Padding = [System.Windows.Thickness]::new(11)
    $bd.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
    $bd.Cursor = [System.Windows.Input.Cursors]::Hand

    $g = New-Object System.Windows.Controls.Grid
    $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(142)
    $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::new(12)
    $c3 = New-Object System.Windows.Controls.ColumnDefinition; $c3.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $null = $g.ColumnDefinitions.Add($c1); $null = $g.ColumnDefinitions.Add($c2); $null = $g.ColumnDefinitions.Add($c3)

    $thumbPath = Resolver-Preview $tid 'dorado' 'principal'
    if (-not $thumbPath) { $thumbPath = Resolver-Preview $tid 'noche' 'principal' }
    $imgWrap = New-CardThumb $thumbPath 142 88
    [System.Windows.Controls.Grid]::SetColumn($imgWrap, 0)
    $null = $g.Children.Add($imgWrap)

    $info = New-Object System.Windows.Controls.StackPanel
    $info.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $topRow = New-Object System.Windows.Controls.DockPanel
    $lblTitle = New-Object System.Windows.Controls.TextBlock
    $lblTitle.Text = $t.titulo
    $lblTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#F3EAD6')
    $lblTitle.FontSize = 14.5
    $lblTitle.FontWeight = [System.Windows.FontWeights]::Bold
    $null = $topRow.Children.Add($lblTitle)

    $badge = New-CardBadge
    $null = $topRow.Children.Add($badge)

    $lblM1 = New-Object System.Windows.Controls.TextBlock
    $lblM1.Text = "1 · $($t.m1)"
    $lblM1.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#A6B9D6')
    $lblM1.FontSize = 11.5
    $lblM1.Margin = [System.Windows.Thickness]::new(0, 4, 0, 2)
    $lblM1.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

    $lblM2 = New-Object System.Windows.Controls.TextBlock
    $lblM2.Text = "2 · $($t.m2)"
    $lblM2.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#E6B45A')
    $lblM2.FontSize = 11.5
    $lblM2.Margin = [System.Windows.Thickness]::new(0, 0, 0, 2)
    $lblM2.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

    $lblM3 = New-Object System.Windows.Controls.TextBlock
    $lblM3.Text = "3 · Bloqueo: $($t.m3)"
    $lblM3.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#88C8FF')
    $lblM3.FontSize = 11
    $lblM3.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis

    $null = $info.Children.Add($topRow)
    $null = $info.Children.Add($lblM1)
    $null = $info.Children.Add($lblM2)
    $null = $info.Children.Add($lblM3)
    [System.Windows.Controls.Grid]::SetColumn($info, 2)
    $null = $g.Children.Add($info)

    $bd.Child = $g
    $bd.Tag = $tid
    $bd.Add_MouseLeftButtonUp({
        param($sender, $e)
        $tidClick = [string]$sender.Tag
        $script:selectedTema = $tidClick
        $script:selectedSerie = $script:worldSeries[$tidClick]
        Cambia-VistaMundo 'imagenes'
        Actualiza-Vista
    })
    Attach-CardHover $bd
    $script:worldCards[$tid] = $bd
    $script:worldBadges[$tid] = $badge
    $script:worldSeries[$tid] = $t.serie
    $null = $el.ListaTarjetasMundos.Children.Add($bd)
}

# Paso 3: Construir selector visual de las 3 imágenes para Monitor Principal, Secundario y Bloqueo
function Build-PickerRow($grid, [string]$rol) {
    $bc = [System.Windows.Media.BrushConverter]::new()
    foreach ($esc in @('principal', 'secundaria', 'bloqueo')) {
        $card = New-Object System.Windows.Controls.Border
        $card.Background = $bc.ConvertFromString('#091024')
        $card.BorderBrush = $bc.ConvertFromString('#24365C')
        $card.BorderThickness = [System.Windows.Thickness]::new(1.5)
        $card.CornerRadius = [System.Windows.CornerRadius]::new(8)
        $card.Padding = [System.Windows.Thickness]::new(5)
        $card.Margin = [System.Windows.Thickness]::new(4)
        $card.Cursor = [System.Windows.Input.Cursors]::Hand

        $sp = New-Object System.Windows.Controls.StackPanel
        $imgWrap = New-Object System.Windows.Controls.Border
        $imgWrap.CornerRadius = [System.Windows.CornerRadius]::new(5)
        $imgWrap.Height = 68
        $imgWrap.ClipToBounds = $true
        $imgWrap.Background = $bc.ConvertFromString('#050814')

        $imgGrid = New-Object System.Windows.Controls.Grid
        $img = New-Object System.Windows.Controls.Image
        $img.Stretch = [System.Windows.Media.Stretch]::UniformToFill
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::NearestNeighbor)
        $null = $imgGrid.Children.Add($img)

        $checkBadge = New-Object System.Windows.Controls.Border
        $checkBadge.Background = $bc.ConvertFromString('#54DED4')
        $checkBadge.CornerRadius = [System.Windows.CornerRadius]::new(9)
        $checkBadge.Width = 18
        $checkBadge.Height = 18
        $checkBadge.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
        $checkBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Top
        $checkBadge.Margin = [System.Windows.Thickness]::new(0, 4, 4, 0)
        $checkBadge.Visibility = 'Collapsed'
        $chkTxt = New-Object System.Windows.Controls.TextBlock
        $chkTxt.Text = '✓'
        $chkTxt.Foreground = $bc.ConvertFromString('#061217')
        $chkTxt.FontSize = 10
        $chkTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $chkTxt.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $chkTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $checkBadge.Child = $chkTxt
        $null = $imgGrid.Children.Add($checkBadge)

        $imgWrap.Child = $imgGrid

        $lbl = New-Object System.Windows.Controls.TextBlock
        $lbl.Foreground = $bc.ConvertFromString('#DCE6F5')
        $lbl.FontSize = 11
        $lbl.FontWeight = [System.Windows.FontWeights]::SemiBold
        $lbl.Margin = [System.Windows.Thickness]::new(2, 5, 2, 1)
        $lbl.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $lbl.TextAlignment = [System.Windows.TextAlignment]::Center

        $null = $sp.Children.Add($imgWrap)
        $null = $sp.Children.Add($lbl)
        $card.Child = $sp
        $card.Tag = @{ rol = $rol; escena = $esc }
        $card.Add_MouseLeftButtonUp({
            param($sender, $e)
            $info = $sender.Tag
            if ($info.rol -eq 'bloqueo') { $el.ChkBloqueo.IsChecked = $true }
            $cmbMap = @{
                'principal'  = $el.CmbFondoPrincipal
                'secundaria' = $el.CmbFondoSecundaria
                'bloqueo'    = $el.CmbFondoBloqueo
            }
            Set-ComboByTag $cmbMap[$info.rol] $info.escena 0
            Actualiza-Vista
        })
        Attach-CardHover $card
        $null = $grid.Children.Add($card)
        $script:pickerItems += @{ rol = $rol; escena = $esc; card = $card; img = $img; lbl = $lbl; chk = $checkBadge }
    }
}

Build-PickerRow $el.GridPickerM1 'principal'
Build-PickerRow $el.GridPickerM2 'secundaria'
Build-PickerRow $el.GridPickerBloq 'bloqueo'

# Inicializar valores desde config.json
$el.RbMon1.IsChecked = ($cfg.monitores -le 1)
$el.RbMon2.IsChecked = ($cfg.monitores -ge 2)
$el.ChkHudMaster.IsChecked = [bool]$cfg.hud
$el.ChkSoloWidgets.IsChecked = [bool]$cfg.soloWidgets
$el.ChkTiempo.IsChecked = [bool]$cfg.stats.tiempo
$el.ChkClima.IsChecked = [bool]$cfg.stats.clima
$el.ChkSistema.IsChecked = [bool]$cfg.stats.sistema
$el.ChkGpu.IsChecked = [bool]$cfg.stats.gpu
$el.ChkRed.IsChecked = [bool]$cfg.stats.red
$el.ChkAudio.IsChecked = [bool]$cfg.stats.audio
$el.ChkDev.IsChecked = [bool]$cfg.stats.dev
$el.ChkFoco.IsChecked = [bool]$cfg.stats.foco
$el.ChkGrimorio.IsChecked = [bool]$cfg.stats.grimorio
$el.SldHora.Value = [double]$cfg.horaFija
$el.ChkTrayCerrar.IsChecked = [bool]$cfg.trayAlCerrar
$el.ChkAutoInicio.IsChecked = AutoInicio-Activo

for ($i = 0; $i -lt $el.CmbModo.Items.Count; $i++) {
    if ($el.CmbModo.Items[$i].Tag -eq $cfg.modo) { $el.CmbModo.SelectedIndex = $i; break }
}
if ($el.CmbModo.SelectedIndex -lt 0) { $el.CmbModo.SelectedIndex = 0 }

function Set-ComboByTag($cmb, [string]$tag, [int]$defIdx = 0) {
    $found = -1
    for ($i = 0; $i -lt $cmb.Items.Count; $i++) {
        if ($cmb.Items[$i].Tag -eq $tag) { $found = $i; break }
    }
    $cmb.SelectedIndex = if ($found -ge 0) { $found } else { $defIdx }
}

$el.ChkBloqueo.IsChecked = [bool]$cfg.usarBloqueo
$el.ChkBloqueoMenu.IsChecked = [bool]$cfg.usarBloqueo
Set-ComboByTag $el.CmbFondoPrincipal ([string]$cfg.fondoPrincipal) 0
Set-ComboByTag $el.CmbFondoSecundaria ([string]$cfg.fondoSecundario) 1
Set-ComboByTag $el.CmbFondoBloqueo ([string]$cfg.fondoBloqueo) 2

$script:eventoSeq = [int]($cfg.eventoSeq)
$itSame = New-Object System.Windows.Controls.ComboBoxItem
$itSame.Content = '🔗 Mismo mundo que Monitor 1 (continuación)'
$itSame.Tag = 'igual'
$null = $el.CmbTemaSec.Items.Add($itSame)
foreach ($tm in $temas) {
    $itSec = New-Object System.Windows.Controls.ComboBoxItem
    $itSec.Content = "$($tm.anime) · $($tm.titulo)"
    $itSec.Tag = $tm.id
    $null = $el.CmbTemaSec.Items.Add($itSec)
}
Set-ComboByTag $el.CmbTemaSec ([string]$cfg.temaSecundario) 0
Set-ComboByTag $el.CmbClima ([string]$cfg.clima) 0
Set-ComboByTag $el.CmbRotacion ([string]$cfg.rotacionMinutos) 0
$el.ChkCompactoHud.IsChecked = [bool]$cfg.compactoHud
$el.ChkAudioReactivo.IsChecked = [bool]$cfg.audioReactivo
$el.ChkPausaJuego.IsChecked = [bool]$cfg.pausaJuego
$el.ChkHotkeys.IsChecked = [bool]$cfg.hotkeys

# Diagnóstico sencillo
$pyPath = Resolver-Python
$pyMsg = if ($pyPath) { "✅ Animación solar automática y vista web listas (Python detectado)." } else { "✅ Animación solar nativa activa (no requiere Python)." }
$deskLnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'PixelZen Worlds.lnk'
$lnkMsg = if (Test-Path $deskLnk) { "✅ Acceso directo ya creado en tu Escritorio." } else { "ℹ️ Aún no tienes acceso directo en el Escritorio (puedes crearlo arriba)." }
$el.TxtDiag.Text = "ℹ️ Versión instalada: v$VersionActual`n✅ $($screens.Count) pantalla(s) detectadas.`n✅ $($temas.Count) mundos con continuación de historia listos.`n$pyMsg`n$lnkMsg"

function Lee-FormConfig {
    $fp = if ($el.CmbFondoPrincipal.SelectedItem) { [string]$el.CmbFondoPrincipal.SelectedItem.Tag } else { 'principal' }
    $fs = if ($el.CmbFondoSecundaria.SelectedItem) { [string]$el.CmbFondoSecundaria.SelectedItem.Tag } else { 'secundaria' }
    $fb = if ($el.CmbFondoBloqueo.SelectedItem) { [string]$el.CmbFondoBloqueo.SelectedItem.Tag } else { 'bloqueo' }
    $ts = if ($el.CmbTemaSec.SelectedItem) { [string]$el.CmbTemaSec.SelectedItem.Tag } else { 'igual' }
    $cl = if ($el.CmbClima.SelectedItem) { [string]$el.CmbClima.SelectedItem.Tag } else { 'normal' }
    $rot = if ($el.CmbRotacion.SelectedItem) { [int]$el.CmbRotacion.SelectedItem.Tag } else { 0 }
    return [ordered]@{
        tema = $script:selectedTema
        temaSecundario = $ts
        monitores = if ($el.RbMon2.IsChecked) { 2 } else { 1 }
        modo = $el.CmbModo.SelectedItem.Tag
        horaFija = [double]$el.SldHora.Value
        fps = $(if ($null -ne $script:cfg -and $null -ne $script:cfg.fps -and [int]$script:cfg.fps -ge 4) { [int]$script:cfg.fps } else { 16 })
        hud = [bool]$el.ChkHudMaster.IsChecked
        soloWidgets = [bool]$el.ChkSoloWidgets.IsChecked
        compactoHud = [bool]$el.ChkCompactoHud.IsChecked
        clima = $cl
        rotacionMinutos = $rot
        pausaJuego = [bool]$el.ChkPausaJuego.IsChecked
        audioReactivo = [bool]$el.ChkAudioReactivo.IsChecked
        hotkeys = [bool]$el.ChkHotkeys.IsChecked
        eventoSeq = [int]$script:eventoSeq
        eventoTipo = ''
        trayAlCerrar = [bool]$el.ChkTrayCerrar.IsChecked
        usarBloqueo = [bool]$el.ChkBloqueo.IsChecked
        fondoPrincipal = $fp
        fondoSecundario = $fs
        fondoBloqueo = $fb
        stats = [ordered]@{
            tiempo = [bool]$el.ChkTiempo.IsChecked
            clima = [bool]$el.ChkClima.IsChecked
            sistema = [bool]$el.ChkSistema.IsChecked
            gpu = [bool]$el.ChkGpu.IsChecked
            red = [bool]$el.ChkRed.IsChecked
            audio = [bool]$el.ChkAudio.IsChecked
            dev = [bool]$el.ChkDev.IsChecked
            foco = [bool]$el.ChkFoco.IsChecked
            grimorio = [bool]$el.ChkGrimorio.IsChecked
        }
    }
}

function Cambia-VistaMundo([string]$vista) {
    $script:mundoVista = $vista
    $el.PanelSeries.Visibility       = if ($vista -eq 'series')   { 'Visible' } else { 'Collapsed' }
    $el.PanelTemasSerie.Visibility   = if ($vista -eq 'temas')    { 'Visible' } else { 'Collapsed' }
    $el.PanelImagenesTema.Visibility = if ($vista -eq 'imagenes') { 'Visible' } else { 'Collapsed' }

    if ($vista -eq 'temas') {
        $el.TxtSerieTitulo.Text = $script:selectedSerie
        foreach ($k in $script:worldCards.Keys) {
            $script:worldCards[$k].Visibility = if ($script:worldSeries[$k] -eq $script:selectedSerie) { 'Visible' } else { 'Collapsed' }
        }
    } elseif ($vista -eq 'imagenes') {
        $tmeta = $temas | Where-Object { $_.id -eq $script:selectedTema } | Select-Object -First 1
        if ($tmeta) { $el.TxtTemaImagenesTitulo.Text = "$($tmeta.serie) · $($tmeta.titulo)" }
    }
    $el.PageMundos.ScrollToHome()
}

function Cambia-Pestana($cual) {
    $pages = @{ 'hub' = $el.PageHub; 'mundos' = $el.PageMundos; 'pantallas' = $el.PagePantallas; 'hud' = $el.PageHud; 'sistema' = $el.PageSistema }
    $navs = @{ 'hub' = $el.NavHub; 'mundos' = $el.NavMundos; 'pantallas' = $el.NavPantallas; 'hud' = $el.NavHud; 'sistema' = $el.NavSistema }
    $titles = @{ 'mundos' = 'Explorar Mundos y Escenas (15 Universos)'; 'pantallas' = 'Disposición de Pantallas, Bloqueo y Luz'; 'hud' = 'Widgets y Tarjetas Flotantes (HUD)'; 'sistema' = 'Ajustes del Sistema y Eventos' }
    $bc = [System.Windows.Media.BrushConverter]::new()
    foreach ($k in $pages.Keys) {
        if ($k -eq $cual) {
            $pages[$k].Visibility = 'Visible'
            $navs[$k].Background = $bc.ConvertFromString('#243966')
            $navs[$k].BorderBrush = $bc.ConvertFromString('#4F7ED4')
            $navs[$k].Foreground = $bc.ConvertFromString('#FFFFFF')
        } else {
            $pages[$k].Visibility = 'Collapsed'
            $navs[$k].Background = [System.Windows.Media.Brushes]::Transparent
            $navs[$k].BorderBrush = [System.Windows.Media.Brushes]::Transparent
            $navs[$k].Foreground = $bc.ConvertFromString('#B8C7E2')
        }
    }
    if ($cual -eq 'hub') {
        $el.BarDetalleTop.Visibility = 'Collapsed'
        $el.ColPreviewBorder.Visibility = 'Collapsed'
        $el.ColPreviewGap.Width = [System.Windows.GridLength]::new(0)
        $el.ColPreviewStudio.Width = [System.Windows.GridLength]::new(0)
    } else {
        $el.BarDetalleTop.Visibility = 'Visible'
        $el.TxtDetalleTitle.Text = $titles[$cual]
        $el.ColPreviewBorder.Visibility = 'Visible'
        $el.ColPreviewGap.Width = [System.Windows.GridLength]::new(12)
        $el.ColPreviewStudio.Width = [System.Windows.GridLength]::new(396)
    }
}

function Aplicar-EscenaTodas([string]$escena) {
    $script:syncingCombos = $true
    $el.ChkBloqueo.IsChecked = $true
    $el.ChkBloqueoMenu.IsChecked = $true
    Set-ComboByTag $el.CmbFondoPrincipal $escena 0
    Set-ComboByTag $el.CmbFondoSecundaria $escena 0
    Set-ComboByTag $el.CmbFondoBloqueo $escena 0
    $script:syncingCombos = $false
    Actualiza-Vista
}

function Actualiza-Vista {
    $bc = [System.Windows.Media.BrushConverter]::new()
    $tid = $script:selectedTema
    $tmeta = $temas | Where-Object { $_.id -eq $tid } | Select-Object -First 1
    $activeSerie = if ($tmeta) { $tmeta.serie } else { $script:selectedSerie }

    # Resaltar serie activa
    foreach ($sK in $script:seriesCards.Keys) {
        if ($sK -eq $activeSerie) {
            $script:seriesCards[$sK].BorderBrush = $bc.ConvertFromString('#54DED4')
            $script:seriesCards[$sK].Background = $bc.ConvertFromString('#152346')
            $script:seriesBadges[$sK].Visibility = 'Visible'
        } else {
            $script:seriesCards[$sK].BorderBrush = $bc.ConvertFromString('#263759')
            $script:seriesCards[$sK].Background = $bc.ConvertFromString('#101832')
            $script:seriesBadges[$sK].Visibility = 'Collapsed'
        }
    }

    # Resaltar tarjeta de mundo elegida
    foreach ($k in $script:worldCards.Keys) {
        if ($k -eq $tid) {
            $script:worldCards[$k].BorderBrush = $bc.ConvertFromString('#54DED4')
            $script:worldCards[$k].Background = $bc.ConvertFromString('#152346')
            $script:worldBadges[$k].Visibility = 'Visible'
        } else {
            $script:worldCards[$k].BorderBrush = $bc.ConvertFromString('#263759')
            $script:worldCards[$k].Background = $bc.ConvertFromString('#101832')
            $script:worldBadges[$k].Visibility = 'Collapsed'
        }
    }

    # Resaltar tarjetas de 1 o 2 monitores
    $dosMon = [bool]$el.RbMon2.IsChecked
    $el.CardMon1.BorderBrush = $bc.ConvertFromString($(if (-not $dosMon) { '#54DED4' } else { '#2A3C64' }))
    $el.CardMon2.BorderBrush = $bc.ConvertFromString($(if ($dosMon) { '#54DED4' } else { '#2A3C64' }))

    $usarBloq = [bool]$el.ChkBloqueo.IsChecked
    # Nombres de escenas del mundo en los selectores por pantalla
    $script:syncingCombos = $true
    $el.ChkBloqueoMenu.IsChecked = $usarBloq
    foreach ($cmb in @($el.CmbFondoPrincipal, $el.CmbFondoSecundaria, $el.CmbFondoBloqueo)) {
        foreach ($item in $cmb.Items) {
            switch ([string]$item.Tag) {
                'principal'  { $item.Content = "Principal · $($tmeta.m1)" }
                'secundaria' { $item.Content = "Secundaria · $($tmeta.m2)" }
                'bloqueo'    { $item.Content = "Bloqueo · $($tmeta.m3)" }
            }
        }
    }
    $script:syncingCombos = $false

    $fpTag = if ($el.CmbFondoPrincipal.SelectedItem) { [string]$el.CmbFondoPrincipal.SelectedItem.Tag } else { 'principal' }
    $fsTag = if ($el.CmbFondoSecundaria.SelectedItem) { [string]$el.CmbFondoSecundaria.SelectedItem.Tag } else { 'secundaria' }
    $fbTag = if ($el.CmbFondoBloqueo.SelectedItem) { [string]$el.CmbFondoBloqueo.SelectedItem.Tag } else { 'bloqueo' }
    $el.PanelComboSec.Visibility = if ($dosMon) { 'Visible' } else { 'Collapsed' }
    $el.PanelPickerM2.Visibility = if ($dosMon) { 'Visible' } else { 'Collapsed' }
    $el.PanelComboBloq.Visibility = if ($usarBloq) { 'Visible' } else { 'Collapsed' }
    $el.GridPickerBloq.Opacity = if ($usarBloq) { 1.0 } else { 0.45 }

    function Cortar-SeriePrefijo([string]$txt) {
        if (-not $txt) { return '' }
        if ($txt -match '^[^·]+·\s*(.+)$') { return $Matches[1].Trim() }
        return $txt.Trim()
    }
    function Nombre-EscenaVariante([string]$tag) {
        switch ($tag) {
            'secundaria' { return (Cortar-SeriePrefijo $tmeta.m2) }
            'bloqueo'    { return (Cortar-SeriePrefijo $tmeta.m3) }
            default      { return (Cortar-SeriePrefijo $tmeta.m1) }
        }
    }

    # Actualizar encabezados e imágenes del Paso 3 (Selector visual por pantalla)
    $el.TxtTemaImagenesTitulo.Text = "$($tmeta.serie) · $($tmeta.titulo)"
    $el.BtnRepetirPrincipal.Content  = "✨ Todas: $(Nombre-EscenaVariante 'principal')"
    $el.BtnRepetirSecundaria.Content = "✨ Todas: $(Nombre-EscenaVariante 'secundaria')"
    $el.BtnRepetirBloqueo.Content    = "✨ Todas: $(Nombre-EscenaVariante 'bloqueo')"

    $prevCache = @{
        'principal'  = Cargar-Bitmap (Resolver-Preview $tid $script:previewFase 'principal')
        'secundaria' = Cargar-Bitmap (Resolver-Preview $tid $script:previewFase 'secundaria')
        'bloqueo'    = Cargar-Bitmap (Resolver-Preview $tid $script:previewFase 'bloqueo')
    }
    $selMap = @{ 'principal' = $fpTag; 'secundaria' = $fsTag; 'bloqueo' = $fbTag }
    foreach ($pi in $script:pickerItems) {
        $pi.img.Source = $prevCache[$pi.escena]
        $pi.lbl.Text = Nombre-EscenaVariante $pi.escena
        $esSel = ($selMap[$pi.rol] -eq $pi.escena) -and ($pi.rol -ne 'bloqueo' -or $usarBloq)
        if ($esSel) {
            $pi.card.BorderBrush = $bc.ConvertFromString('#54DED4')
            $pi.card.Background  = $bc.ConvertFromString('#15284F')
            $pi.lbl.Foreground   = $bc.ConvertFromString('#7CF6EE')
            $pi.chk.Visibility   = 'Visible'
        } else {
            $pi.card.BorderBrush = $bc.ConvertFromString('#24365C')
            $pi.card.Background  = $bc.ConvertFromString('#091024')
            $pi.lbl.Foreground   = $bc.ConvertFromString('#DCE6F5')
            $pi.chk.Visibility   = 'Collapsed'
        }
    }

    # Imágenes de vista previa M1, M2 y Bloqueo
    $tsTag = if ($el.CmbTemaSec -and $el.CmbTemaSec.SelectedItem) { [string]$el.CmbTemaSec.SelectedItem.Tag } else { 'igual' }
    $tidSec = if ($tsTag -and $tsTag -ne 'igual' -and $tsTag -ne $tid) { $tsTag } else { $tid }
    $el.ImgPrev1.Source = $prevCache[$fpTag]
    $el.ImgPrev2.Source = if ($tidSec -ne $tid) { Cargar-Bitmap (Resolver-Preview $tidSec $script:previewFase $fsTag) } else { $prevCache[$fsTag] }
    $el.ImgPrevBloqueo.Source = $prevCache[$fbTag]
    $el.TxtPrev1Title.Text = "PANTALLA 1 · $(Nombre-EscenaVariante $fpTag)"
    $tSecMeta = if ($tidSec -ne $tid) { $temas | Where-Object { $_.id -eq $tidSec } | Select-Object -First 1 } else { $null }
    $el.TxtPrev2Title.Text = if ($tSecMeta) { "PANTALLA 2 · $($tSecMeta.titulo)" } else { "PANTALLA 2 · $(Nombre-EscenaVariante $fsTag)" }
    $el.PanelPrev2.Visibility = if ($dosMon) { 'Visible' } else { 'Collapsed' }
    $el.TxtM2Sub.Text = if ($tSecMeta) { "Mundo independiente: $($tSecMeta.anime) ($fsTag)" } else { "En tu 2.º monitor: $(Nombre-EscenaVariante $fsTag)" }
    $el.TxtPrevBloqTitle.Text = "🔒 BLOQUEO · $(Nombre-EscenaVariante $fbTag)"
    $el.PanelPrevBloqueo.Visibility = if ($usarBloq) { 'Visible' } else { 'Collapsed' }
    $el.TxtBloqSub.Text = "Bloqueo de Windows: $(Nombre-EscenaVariante $fbTag)"

    # Modo horario
    $modo = $el.CmbModo.SelectedItem.Tag
    $el.PanelHora.Visibility = if ($modo -eq 'fija') { 'Visible' } else { 'Collapsed' }
    $hv = [double]$el.SldHora.Value
    $hh = [math]::Floor($hv); $mm = [math]::Round(($hv - $hh) * 60)
    $el.TxtHoraVal.Text = "{0:00}:{1:00}" -f [int]$hh, [int]$mm

    # Simulación en vivo de cajitas HUD sobre Monitor 1
    $hudOn = [bool]$el.ChkHudMaster.IsChecked
    $soloW = [bool]$el.ChkSoloWidgets.IsChecked
    $el.MockHudPanel.Visibility = if ($hudOn) { 'Visible' } else { 'Collapsed' }
    $el.TxtMockMundo.Text = if ($soloW) { 'FONDO EXTERNO' } else { $tmeta.titulo }
    $el.MockTiempo.Visibility   = if ($el.ChkTiempo.IsChecked)   { 'Visible' } else { 'Collapsed' }
    $el.MockClima.Visibility    = if ($el.ChkClima.IsChecked)    { 'Visible' } else { 'Collapsed' }
    $el.MockSistema.Visibility  = if ($el.ChkSistema.IsChecked)  { 'Visible' } else { 'Collapsed' }
    $el.MockGpu.Visibility      = if ($el.ChkGpu.IsChecked)      { 'Visible' } else { 'Collapsed' }
    $el.MockRed.Visibility      = if ($el.ChkRed.IsChecked)      { 'Visible' } else { 'Collapsed' }
    $el.MockAudio.Visibility    = if ($el.ChkAudio.IsChecked)    { 'Visible' } else { 'Collapsed' }
    $el.MockDev.Visibility      = if ($el.ChkDev.IsChecked)      { 'Visible' } else { 'Collapsed' }
    $el.MockFoco.Visibility     = if ($el.ChkFoco.IsChecked)     { 'Visible' } else { 'Collapsed' }
    $el.MockGrimorio.Visibility = if ($el.ChkGrimorio.IsChecked -and -not $soloW) { 'Visible' } else { 'Collapsed' }

    # Habilitar/atenuar checkboxes individuales según interruptor maestro
    $allHudChks = @($el.ChkTiempo, $el.ChkClima, $el.ChkSistema, $el.ChkGpu, $el.ChkRed, $el.ChkAudio, $el.ChkDev, $el.ChkFoco, $el.ChkGrimorio)
    foreach ($cb in $allHudChks) {
        $cb.IsEnabled = $hudOn
    }
    $el.ChkGrimorio.IsEnabled = ($hudOn -and -not $soloW)

    # Botón toggle HUD actual y Modo Solo Widgets
    $el.BtnToggleHudNow.Content = if (Hay-HudActivo) { '👁️ Ocultar HUD' } else { '👁️ Mostrar HUD' }
    if ($soloW) {
        $el.BtnSoloWidgetsBar.Background = $bc.ConvertFromString('#193B48')
        $el.BtnSoloWidgetsBar.BorderBrush = $bc.ConvertFromString('#54DED4')
        $el.BtnSoloWidgetsBar.Content = '🧩 Solo Widgets ON'
        $el.BtnAplicar.Content = '✦ APLICAR SOLO WIDGETS'
    } else {
        $el.BtnSoloWidgetsBar.Background = $bc.ConvertFromString('#243056')
        $el.BtnSoloWidgetsBar.BorderBrush = $bc.ConvertFromString('#3C8D96')
        $el.BtnSoloWidgetsBar.Content = '🧩 Solo Widgets'
        $el.BtnAplicar.Content = '✦ APLICAR A MI ESCRITORIO'
    }

    # Estado motor nativo en cabecera
    if ($soloW) {
        $el.BadgeMotor.Background = $bc.ConvertFromString('#122A38')
        $el.BadgeMotor.BorderBrush = $bc.ConvertFromString('#54DED4')
        $el.TxtMotorBadge.Text = '● MODO SOLO WIDGETS'
        $el.TxtMotorBadge.Foreground = $bc.ConvertFromString('#7CF6EE')
    } elseif (Motor-NativoActivo) {
        $el.BadgeMotor.Background = $bc.ConvertFromString('#102924')
        $el.BadgeMotor.BorderBrush = $bc.ConvertFromString('#2E8B6B')
        $el.TxtMotorBadge.Text = '● MOTOR NATIVO ACTIVO'
        $el.TxtMotorBadge.Foreground = $bc.ConvertFromString('#72E6AE')
    } else {
        $el.BadgeMotor.Background = $bc.ConvertFromString('#261E12')
        $el.BadgeMotor.BorderBrush = $bc.ConvertFromString('#7D6230')
        $el.TxtMotorBadge.Text = '● EN ESPERA'
        $el.TxtMotorBadge.Foreground = $bc.ConvertFromString('#E6B45A')
    }

    # Botones de vista previa fase (segmentados)
    foreach ($pair in @(@($el.BtnPrevDia,'dia'), @($el.BtnPrevDor,'dorado'), @($el.BtnPrevNoc,'noche'))) {
        $activoF = ($script:previewFase -eq $pair[1])
        $pair[0].Background  = $bc.ConvertFromString($(if ($activoF) { '#163549' } else { 'Transparent' }))
        $pair[0].BorderBrush = $bc.ConvertFromString($(if ($activoF) { '#54DED4' } else { 'Transparent' }))
        $pair[0].Foreground  = $bc.ConvertFromString($(if ($activoF) { '#7CF6EE' } else { '#9AB0CE' }))
    }

    # Resumen lateral estructurado
    $modoTxt = switch ($modo) { 'real' { 'Hora real' } 'demo' { 'Pase rápido 90s' } 'fija' { "Fija $($el.TxtHoraVal.Text)" } default { 'Suave 90m' } }
    $nStats = @($allHudChks | Where-Object { $_.IsChecked }).Count
    $hudTxt = if ($hudOn) { "$nStats activas" } else { 'Desactivado' }
    $bloqTxt = if ($usarBloq) { Nombre-EscenaVariante $fbTag } else { 'Desactivado' }
    $el.TxtResumen.Text = if ($soloW) { "Modo Solo Widgets`nFondo externo activo · HUD: $hudTxt" } else { "$($tmeta.titulo)`n$(if ($dosMon) { '2 pant.' } else { '1 pant.' }) · $modoTxt · HUD: $hudTxt" }

    # Sincronizar Tarjetas del Hub 2x2
    $totalPages = [math]::Max(1, [int][math]::Ceiling($temas.Count / 3.0))
    if ($script:hubPageIdx -lt 0) { $script:hubPageIdx = $totalPages - 1 }
    if ($script:hubPageIdx -ge $totalPages) { $script:hubPageIdx = 0 }
    $startIdx = ($script:hubPageIdx * 3)
    $slotUI = @(
        @{ card = $el.HubTemaCard1; bev = $el.HubTemaBevel1; img = $el.ImgHubTema1; txt = $el.TxtHubTema1 },
        @{ card = $el.HubTemaCard2; bev = $el.HubTemaBevel2; img = $el.ImgHubTema2; txt = $el.TxtHubTema2 },
        @{ card = $el.HubTemaCard3; bev = $el.HubTemaBevel3; img = $el.ImgHubTema3; txt = $el.TxtHubTema3 }
    )
    $visNames = @()
    for ($si = 0; $si -lt 3; $si++) {
        $tmIdx = ($startIdx + $si) % $temas.Count
        $tmItem = $temas[$tmIdx]
        $script:hubSlotIds[$si] = $tmItem.id
        $visNames += $tmItem.serie
        $pPath = Resolver-Preview $tmItem.id $script:previewFase 'principal'
        if (-not $pPath) { $pPath = Resolver-Preview $tmItem.id 'noche' 'principal' }
        $slotUI[$si].img.Source = Cargar-Bitmap $pPath
        $slotUI[$si].txt.Text = $tmItem.titulo
        if ($tmItem.id -eq $tid) {
            $slotUI[$si].card.Background = $bc.ConvertFromString('#F6C84C')
            $slotUI[$si].bev.BorderBrush = $bc.ConvertFromString('#FFE896')
            $slotUI[$si].txt.Foreground = $bc.ConvertFromString('#FFE688')
        } else {
            $slotUI[$si].card.Background = $bc.ConvertFromString('#0A0D19')
            $slotUI[$si].bev.BorderBrush = $bc.ConvertFromString('#4C74B2')
            $slotUI[$si].txt.Foreground = $bc.ConvertFromString('#F6F2E8')
        }
    }
    $el.TxtHubTemasLista.Text = "Temas: $($visNames -join ', ')  ($($script:hubPageIdx + 1)/$totalPages)"

    # Tarjeta Pantallas
    $el.ImgHubAnimados.Source = $prevCache[$fpTag]
    $el.TxtHubAnimSub.Text = if ($dosMon) { "2 Pantallas · $($tmeta.titulo)" } else { "1 Pantalla · $($tmeta.titulo)" }
    $estPath = Resolver-Preview $tid 'noche' $(if ($usarBloq) { $fbTag } else { $fpTag })
    $el.ImgHubEstaticos.Source = Cargar-Bitmap $estPath
    $faseNombre = switch ($script:previewFase) { 'dia' { 'Día' } 'dorado' { 'Dorado' } default { 'Noche' } }
    $el.TxtHubEstSub.Text = "Fase: $faseNombre · $(if ($usarBloq) { 'Bloqueo ON' } else { 'Solo Escritorio' })"

    # Tarjeta Widgets
    $el.TxtHubClock.Text = (Get-Date).ToString('HH:mm')
    $el.TxtHubClockStatus.Text = if (-not $hudOn) { 'HUD OFF' } elseif ($soloW) { 'SOLO WIDGETS' } else { "HUD ON ($nStats)" }
    $el.HubTileClock.Opacity = if ($hudOn) { 1.0 } else { 0.65 }
    $clTag = if ($el.CmbClima.SelectedItem) { [string]$el.CmbClima.SelectedItem.Tag } else { 'normal' }
    $clReal = Obtener-ClimaRealMenu
    $clModoLbl = switch ($clTag) {
        'lluvia'   { 'LLUVIA' }
        'tormenta' { 'TORMENTA' }
        'nieve'    { 'NIEVE' }
        'niebla'   { 'NIEBLA' }
        'ceniza'   { 'CENIZA' }
        'auto'     { if ($clReal -and $clReal.desc) { ([string]$clReal.desc).ToUpper() } else { 'AUTO' } }
        default    { if ($clReal -and $clReal.desc) { ([string]$clReal.desc).ToUpper() } else { 'DESPEJADO' } }
    }
    if ($clReal -and $clReal.ok) {
        $el.TxtHubWeather.Text = "$([int][Math]::Round([double]$clReal.temp))°C"
        $el.TxtHubWeatherSub.Text = "$(([string]$clReal.city).ToUpper()) · $clModoLbl"
    } else {
        $el.TxtHubWeather.Text = '--°C'
        $el.TxtHubWeatherSub.Text = $clModoLbl
    }
    $el.TxtHubCatBadge.Text = if ($el.ChkCompactoHud.IsChecked) { 'COMPACTO' } else { "$nStats TARJETAS" }

    # Tarjeta Ajustes
    $el.TxtHubGenVal.Text = $modoTxt
    $el.TxtHubRendVal.Text = if ($el.ChkPausaJuego.IsChecked) { 'Pausa Auto ON' } else { 'Libre 16 FPS' }
    $el.TxtHubAtajosVal.Text = if ($el.ChkHotkeys.IsChecked) { 'Ctrl+Alt ON' } else { 'Atajos OFF' }
    $script:syncingCombos = $true
    $el.SldHubHora.Value = $hv
    $script:syncingCombos = $false
}

# Eventos de navegación y controles
$el.NavHub.Add_Click({ Cambia-Pestana 'hub' })
$el.BtnVolverHub.Add_Click({ Cambia-Pestana 'hub' })
$el.NavMundos.Add_Click({ Cambia-Pestana 'mundos'; Cambia-VistaMundo 'series' })

# Eventos del Hub 2x2
$el.BtnHubPrevTema.Add_Click({ $script:hubPageIdx--; Actualiza-Vista })
$el.BtnHubNextTema.Add_Click({ $script:hubPageIdx++; Actualiza-Vista })
$doApply = {
    $c = Lee-FormConfig
    $fase = Aplicar-Todo $c
    $script:previewFase = $fase
    Start-Sleep -Milliseconds 250
    Actualiza-Vista
    $tmeta = $temas | Where-Object { $_.id -eq $c.tema } | Select-Object -First 1
    $bloqSuf = if ($c.usarBloqueo -and $script:bloqueoOk) { ' + bloqueo' } else { '' }
    if ($c.soloWidgets -or $script:modoMotor -eq 'solo-widgets') {
        $el.TxtEstado.Text = "✨ ¡Listo! Widgets activos por encima de tu fondo actual (modo Wallpaper Engine / externo)."
    } elseif ($script:modoMotor -eq 'nativo') {
        $el.TxtEstado.Text = "✨ ¡Listo! '$($tmeta.titulo)' animado en vivo de forma nativa ($($c.monitores) pantalla(s)$bloqSuf)."
    } else {
        $el.TxtEstado.Text = "✅ ¡Listo! Aplicado '$($tmeta.titulo)' en $($c.monitores) pantalla(s)$bloqSuf (fase $fase)."
    }
}

$doApplySoloWidgets = {
    $script:syncingCombos = $true
    $el.ChkSoloWidgets.IsChecked = $true
    $el.ChkHudMaster.IsChecked = $true
    $script:syncingCombos = $false
    & $doApply
}

$hubSelectSlot = {
    param([int]$slot)
    $tidPick = $script:hubSlotIds[$slot]
    if ($tidPick) {
        $script:selectedTema = $tidPick
        $script:selectedSerie = $script:worldSeries[$tidPick]
        $script:syncingCombos = $true
        $el.ChkSoloWidgets.IsChecked = $false
        $script:syncingCombos = $false
        & $doApply
    }
}
$el.HubTemaCard1.Add_MouseLeftButtonUp({ & $hubSelectSlot 0 })
$el.HubTemaCard2.Add_MouseLeftButtonUp({ & $hubSelectSlot 1 })
$el.HubTemaCard3.Add_MouseLeftButtonUp({ & $hubSelectSlot 2 })
$el.BtnHubIrMundos.Add_Click({ Cambia-Pestana 'mundos'; Cambia-VistaMundo 'series' })
$el.TxtHubTemasLista.Add_MouseLeftButtonUp({ Cambia-Pestana 'mundos'; Cambia-VistaMundo 'series' })

$el.HubCardAnimados.Add_MouseLeftButtonUp({
    if ($el.RbMon2.IsChecked) { $el.RbMon1.IsChecked = $true } else { $el.RbMon2.IsChecked = $true }
    & $doApply
})
$el.HubCardEstaticos.Add_MouseLeftButtonUp({
    $fases = @('dia', 'dorado', 'noche')
    $cur = [Array]::IndexOf($fases, $script:previewFase)
    $script:previewFase = $fases[($cur + 1) % 3]
    Actualiza-Vista
    & $doApply
})
$el.BtnHubExplorarPantallas.Add_Click({ Cambia-Pestana 'mundos'; Cambia-VistaMundo 'imagenes' })
$el.BtnHubStar2.Add_Click({ Cambia-Pestana 'pantallas' })

$el.HubTileClock.Add_MouseLeftButtonUp({
    $el.BtnToggleHudNow.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
})
$el.HubTileWeather.Add_MouseLeftButtonUp({
    $curCl = if ($el.CmbClima.SelectedItem) { [string]$el.CmbClima.SelectedItem.Tag } else { 'normal' }
    $clOrder = @('normal', 'lluvia', 'tormenta', 'nieve', 'niebla', 'ceniza', 'auto')
    $idxCl = [Array]::IndexOf($clOrder, $curCl)
    $nextCl = $clOrder[($idxCl + 1) % $clOrder.Count]
    Set-ComboByTag $el.CmbClima $nextCl 0
    $c = Lee-FormConfig; Guardar-Config $c
    Actualiza-Vista
    $el.TxtEstado.Text = "🌦️ Clima cambiado a: $nextCl"
})
$el.HubTileCat.Add_MouseLeftButtonUp({ Cambia-Pestana 'hud' })
$el.BtnHubIrWidgets.Add_MouseLeftButtonUp({ Cambia-Pestana 'hud' })
$el.BtnHubStar3.Add_Click({ Cambia-Pestana 'hud' })

$el.BtnHubIrAjustes.Add_Click({ Cambia-Pestana 'sistema' })
$el.BtnHubStar4.Add_Click({ Cambia-Pestana 'sistema' })
$el.BtnHubGen.Add_MouseLeftButtonUp({
    $idxM = ($el.CmbModo.SelectedIndex + 1) % $el.CmbModo.Items.Count
    $el.CmbModo.SelectedIndex = $idxM
    Actualiza-Vista
})
$el.BtnHubRend.Add_MouseLeftButtonUp({
    $el.ChkPausaJuego.IsChecked = -not [bool]$el.ChkPausaJuego.IsChecked
    $c = Lee-FormConfig; Guardar-Config $c
    Actualiza-Vista
})
$el.BtnHubAtajos.Add_MouseLeftButtonUp({
    $el.ChkHotkeys.IsChecked = -not [bool]$el.ChkHotkeys.IsChecked
    $c = Lee-FormConfig; Guardar-Config $c
    Actualiza-Vista
})
$el.SldHubHora.Add_ValueChanged({
    if ($script:syncingCombos) { return }
    $script:syncingCombos = $true
    $el.SldHora.Value = $el.SldHubHora.Value
    Set-ComboByTag $el.CmbModo 'fija' 3
    $script:previewFase = Detectar-Fase 'fija' $el.SldHubHora.Value
    $script:syncingCombos = $false
    Actualiza-Vista
})
$el.BtnHubSldMenos.Add_Click({
    $el.SldHubHora.Value = [math]::Max(0, $el.SldHubHora.Value - 1.5)
})
$el.BtnHubSldMas.Add_Click({
    $el.SldHubHora.Value = [math]::Min(23.75, $el.SldHubHora.Value + 1.5)
})
$el.BtnVolverASeries.Add_Click({ Cambia-VistaMundo 'series' })
$el.BtnVolverDeImagenes.Add_Click({
    $listaS = $seriesByName[$script:selectedSerie]
    if ($listaS -and $listaS.Count -gt 1) { Cambia-VistaMundo 'temas' } else { Cambia-VistaMundo 'series' }
})
$el.BtnPresetClasico.Add_Click({
    $script:syncingCombos = $true
    $el.ChkBloqueo.IsChecked = $true
    $el.ChkBloqueoMenu.IsChecked = $true
    Set-ComboByTag $el.CmbFondoPrincipal 'principal' 0
    Set-ComboByTag $el.CmbFondoSecundaria 'secundaria' 1
    Set-ComboByTag $el.CmbFondoBloqueo 'bloqueo' 2
    $script:syncingCombos = $false
    Actualiza-Vista
})
$el.BtnRepetirPrincipal.Add_Click({ Aplicar-EscenaTodas 'principal' })
$el.BtnRepetirSecundaria.Add_Click({ Aplicar-EscenaTodas 'secundaria' })
$el.BtnRepetirBloqueo.Add_Click({ Aplicar-EscenaTodas 'bloqueo' })
$el.BtnIrAPantallasLuz.Add_Click({ Cambia-Pestana 'pantallas' })

$el.NavPantallas.Add_Click({ Cambia-Pestana 'pantallas' })
$el.NavHud.Add_Click({ Cambia-Pestana 'hud' })
$el.NavSistema.Add_Click({ Cambia-Pestana 'sistema' })

$el.CardMon1.Add_MouseLeftButtonUp({ $el.RbMon1.IsChecked = $true; Actualiza-Vista })
$el.CardMon2.Add_MouseLeftButtonUp({ $el.RbMon2.IsChecked = $true; Actualiza-Vista })
$el.RbMon1.Add_Checked({ Actualiza-Vista })
$el.RbMon2.Add_Checked({ Actualiza-Vista })
foreach ($cmbV in $el.CmbFondoPrincipal, $el.CmbFondoSecundaria, $el.CmbFondoBloqueo) {
    $cmbV.Add_SelectionChanged({ if (-not $script:syncingCombos) { Actualiza-Vista } })
}
$el.ChkBloqueo.Add_Checked({ if (-not $script:syncingCombos) { Actualiza-Vista } })
$el.ChkBloqueo.Add_Unchecked({ if (-not $script:syncingCombos) { Actualiza-Vista } })
$el.ChkBloqueoMenu.Add_Checked({
    if (-not $script:syncingCombos) {
        $script:syncingCombos = $true; $el.ChkBloqueo.IsChecked = $true; $script:syncingCombos = $false
        Actualiza-Vista
    }
})
$el.ChkBloqueoMenu.Add_Unchecked({
    if (-not $script:syncingCombos) {
        $script:syncingCombos = $true; $el.ChkBloqueo.IsChecked = $false; $script:syncingCombos = $false
        Actualiza-Vista
    }
})
$el.CmbModo.Add_SelectionChanged({
    if ($el.CmbModo.SelectedItem.Tag -eq 'fija') {
        $script:previewFase = Detectar-Fase 'fija' $el.SldHora.Value
    }
    Actualiza-Vista
})
$el.SldHora.Add_ValueChanged({
    $script:previewFase = Detectar-Fase 'fija' $el.SldHora.Value
    Actualiza-Vista
})
$el.BtnFijarDia.Add_Click({ $el.SldHora.Value = 13.0; $script:previewFase = 'dia'; Actualiza-Vista })
$el.BtnFijarDor.Add_Click({ $el.SldHora.Value = 18.5; $script:previewFase = 'dorado'; Actualiza-Vista })
$el.BtnFijarNoc.Add_Click({ $el.SldHora.Value = 22.0; $script:previewFase = 'noche'; Actualiza-Vista })

$el.BtnPrevDia.Add_Click({ $script:previewFase = 'dia'; Actualiza-Vista })
$el.BtnPrevDor.Add_Click({ $script:previewFase = 'dorado'; Actualiza-Vista })
$el.BtnPrevNoc.Add_Click({ $script:previewFase = 'noche'; Actualiza-Vista })

foreach ($cb in $el.ChkHudMaster, $el.ChkTiempo, $el.ChkClima, $el.ChkSistema, $el.ChkGpu, $el.ChkRed, $el.ChkAudio, $el.ChkDev, $el.ChkFoco, $el.ChkGrimorio) {
    $cb.Add_Checked({ Actualiza-Vista })
    $cb.Add_Unchecked({ Actualiza-Vista })
}
$el.BtnHudTodas.Add_Click({
    $el.ChkHudMaster.IsChecked = $true
    foreach ($cb in $el.ChkTiempo, $el.ChkClima, $el.ChkSistema, $el.ChkGpu, $el.ChkRed, $el.ChkAudio, $el.ChkDev, $el.ChkFoco, $el.ChkGrimorio) { $cb.IsChecked = $true }
    Actualiza-Vista
})
$el.BtnHudMinimo.Add_Click({
    $el.ChkHudMaster.IsChecked = $true
    $el.ChkTiempo.IsChecked = $true; $el.ChkGrimorio.IsChecked = $true
    foreach ($cb in $el.ChkClima, $el.ChkSistema, $el.ChkGpu, $el.ChkRed, $el.ChkAudio, $el.ChkDev, $el.ChkFoco) { $cb.IsChecked = $false }
    Actualiza-Vista
})
$el.BtnHudSoloReloj.Add_Click({
    $el.ChkHudMaster.IsChecked = $true
    $el.ChkTiempo.IsChecked = $true
    foreach ($cb in $el.ChkClima, $el.ChkSistema, $el.ChkGpu, $el.ChkRed, $el.ChkAudio, $el.ChkDev, $el.ChkFoco, $el.ChkGrimorio) { $cb.IsChecked = $false }
    Actualiza-Vista
})

$el.BtnAccesoDirecto.Add_Click({
    $rutaLnk = Crear-AccesoDirecto
    $el.TxtEstado.Text = "✅ Acceso directo creado en tu Escritorio: PixelZen Worlds.lnk"
})
$el.BtnEventoAhora.Add_Click({
    $script:eventoSeq++
    $c = Lee-FormConfig
    $c.eventoSeq = $script:eventoSeq
    Guardar-Config $c
    $el.TxtEstado.Text = "✦ Evento épico enviado al fondo de escritorio."
})
$el.CmbTemaSec.Add_SelectionChanged({ if (-not $script:syncingCombos) { Actualiza-Vista } })
foreach ($cbx in @($el.CmbClima, $el.CmbRotacion, $el.ChkCompactoHud, $el.ChkAudioReactivo, $el.ChkPausaJuego, $el.ChkHotkeys)) {
    if ($cbx -is [System.Windows.Controls.ComboBox]) {
        $cbx.Add_SelectionChanged({ if (-not $script:syncingCombos) { $c = Lee-FormConfig; Guardar-Config $c } })
    } else {
        $cbx.Add_Click({ if (-not $script:syncingCombos) { $c = Lee-FormConfig; Guardar-Config $c } })
    }
}
$el.ChkAutoInicio.Add_Checked({ Set-AutoInicio $true; $el.TxtEstado.Text = "✅ PixelZen se aplicará automáticamente al iniciar Windows." })
$el.ChkAutoInicio.Add_Unchecked({ Set-AutoInicio $false; $el.TxtEstado.Text = "Auto-inicio con Windows desactivado." })
$el.BtnBuscarUpdate.Add_Click({
    $el.TxtEstado.Text = "🔄 Buscando actualizaciones en GitHub Releases..."
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/davidlpizano/pixelzen-worlds/releases/latest' -Headers @{ 'User-Agent' = 'PixelZenWorlds' } -TimeoutSec 10
        $remTag = ([string]$rel.tag_name).TrimStart('v', 'V')
        if ([version]$remTag -le [version]$VersionActual) {
            $el.TxtEstado.Text = "✅ Ya tienes la última versión (v$VersionActual)."
            return
        }
        $assetZip = $rel.assets | Where-Object { $_.name -eq 'PixelZenWorlds-Windows.zip' } | Select-Object -First 1
        $assetExe = $rel.assets | Where-Object { $_.name -eq 'PixelZenWorlds-Setup.exe' } | Select-Object -First 1
        $asset = if ($assetZip) { $assetZip } else { $assetExe }
        if (-not $asset) {
            $el.TxtEstado.Text = "✨ Nueva versión v$remTag disponible en GitHub Releases."
            Start-Process ([string]$rel.html_url)
            return
        }
        $resp = [System.Windows.MessageBox]::Show(
            "Hay una versión nueva disponible (v$remTag, actual v$VersionActual).`n¿Quieres descargarla e instalarla ahora? Tus ajustes se conservarán.",
            "Actualización · PixelZen Worlds",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        if ($resp -ne [System.Windows.MessageBoxResult]::Yes) {
            $el.TxtEstado.Text = "Actualización pospuesta (disponible v$remTag)."
            return
        }
        if ($assetZip) {
            $updDir = Join-Path $env:TEMP ('pz_upd_' + [Guid]::NewGuid().ToString('N'))
            New-Item -Path $updDir -ItemType Directory -Force | Out-Null
            $tmpZip = Join-Path $updDir 'PixelZenWorlds-Windows.zip'
            Invoke-WebRequest -Uri $assetZip.browser_download_url -OutFile $tmpZip -UseBasicParsing
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($tmpZip, $updDir)
            $instPs = Join-Path $updDir 'Instalar.ps1'
            Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$instPs`""
        } else {
            $tmpSetup = Join-Path $env:TEMP 'PixelZenWorlds-Setup.exe'
            Invoke-WebRequest -Uri $assetExe.browser_download_url -OutFile $tmpSetup -UseBasicParsing
            Start-Process -FilePath $tmpSetup
        }
        $script:realClose = $true
        $win.Close()
    } catch {
        $el.TxtEstado.Text = "⚠️ No se pudo consultar GitHub automáticamente. Abriendo página de Releases..."
        Start-Process 'https://github.com/davidlpizano/pixelzen-worlds/releases'
    }
})

$el.BtnRestaurar.Add_Click({
    $script:selectedTema = 'fittoa'
    $script:selectedSerie = 'Mushoku Tensei'
    $el.RbMon2.IsChecked = $true
    $el.ChkBloqueo.IsChecked = $true
    Set-ComboByTag $el.CmbFondoPrincipal 'principal' 0
    Set-ComboByTag $el.CmbFondoSecundaria 'secundaria' 1
    Set-ComboByTag $el.CmbFondoBloqueo 'bloqueo' 2
    $el.CmbModo.SelectedIndex = 0
    $el.ChkHudMaster.IsChecked = $true
    foreach ($cb in $el.ChkTiempo, $el.ChkSistema, $el.ChkRed, $el.ChkDev, $el.ChkGrimorio) { $cb.IsChecked = $true }
    Actualiza-Vista
    $el.TxtEstado.Text = "Valores recomendados cargados. Pulsa Aplicar a mi escritorio si quieres guardarlos."
})

$el.BtnToggleHudNow.Add_Click({
    if (Hay-HudActivo) {
        Detener-Hud
        $el.ChkHudMaster.IsChecked = $false
        $c = Lee-FormConfig; Guardar-Config $c
        $el.TxtEstado.Text = "Cajitas ocultadas del escritorio."
    } else {
        $el.ChkHudMaster.IsChecked = $true
        $c = Lee-FormConfig; Guardar-Config $c
        Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$(Join-Path $Aqui 'PixelZenHud.ps1')`"" -WindowStyle Hidden
        Start-Sleep -Milliseconds 350
        $el.TxtEstado.Text = "✅ Cajitas mostradas en tu pantalla principal."
    }
    Actualiza-Vista
})

$el.BtnActivarSoloWidgets.Add_Click({ & $doApplySoloWidgets })

$el.ChkSoloWidgets.Add_Click({
    if ($script:syncingCombos) { return }
    if ($el.ChkSoloWidgets.IsChecked) {
        $script:syncingCombos = $true
        $el.ChkHudMaster.IsChecked = $true
        $script:syncingCombos = $false
    }
    $c = Lee-FormConfig; Guardar-Config $c
    Actualiza-Vista
    $el.TxtEstado.Text = if ($el.ChkSoloWidgets.IsChecked) { "🧩 Modo Solo Widgets seleccionado. Pulsa Activar o Aplicar para mantener tu fondo actual." } else { "Modo fondo PixelZen restaurado." }
})

$el.BtnSoloWidgetsBar.Add_Click({
    if (-not [bool]$el.ChkSoloWidgets.IsChecked -or -not (Hay-HudActivo)) {
        & $doApplySoloWidgets
    } else {
        $script:syncingCombos = $true
        $el.ChkSoloWidgets.IsChecked = $false
        $script:syncingCombos = $false
        $c = Lee-FormConfig; Guardar-Config $c
        Actualiza-Vista
        $el.TxtEstado.Text = "Modo Solo Widgets desactivado. Pulsa Aplicar si quieres poner un fondo de PixelZen."
    }
})

$el.BtnSoloGuardar.Add_Click({
    $c = Lee-FormConfig
    Guardar-Config $c
    $el.TxtEstado.Text = "💾 Opciones guardadas en configuración."
})

$el.BtnAplicar.Add_Click({ & $doApply })

$el.BtnWeb.Add_Click({
    $c = Lee-FormConfig
    Guardar-Config $c
    $py = Resolver-Python
    if (-not $py) {
        $el.TxtEstado.Text = "⚠️ Se necesita Python instalado para abrir el visor animado del navegador."
        return
    }
    $srvPidFile = Join-Path $env:TEMP 'pixelzen_srv.pid'
    $yaCorre = $false
    if (Test-Path $srvPidFile) {
        $sp = Get-Content $srvPidFile -ErrorAction SilentlyContinue
        if ($sp -and (Get-Process -Id ([int]$sp) -ErrorAction SilentlyContinue)) { $yaCorre = $true }
    }
    if (-not $yaCorre) {
        $proc = Start-Process -FilePath $py -ArgumentList "`"$(Join-Path $Aqui 'pixelzen_win.py')`" --servidor --puerto 8765" -WindowStyle Hidden -PassThru
        if ($proc) { Set-Content -Path $srvPidFile -Value $proc.Id -Encoding ASCII }
        Start-Sleep -Milliseconds 600
    }
    $activas = @($c.stats.Keys | Where-Object { $c.stats[$_] }) -join ','
    $hudFlag = if ($c.hud) { '1' } else { '0' }
    Start-Process "http://127.0.0.1:8765/?tema=$($c.tema)&pantalla=principal&modo=$($c.modo)&hora=$($c.horaFija)&hud=$hudFlag&stats=$activas"
    if ($c.monitores -ge 2) {
        Start-Process "http://127.0.0.1:8765/?tema=$($c.tema)&pantalla=secundaria&modo=$($c.modo)&hora=$($c.horaFija)&hud=0"
    }
    $el.TxtEstado.Text = "🎬 Vista animada abierta en tu navegador."
})

# Bandeja del sistema (NotifyIcon junto al reloj)
$script:realClose = $false
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
if (Test-Path $IconPath) { $trayIcon.Icon = New-Object System.Drawing.Icon($IconPath) }
else { $trayIcon.Icon = [System.Drawing.SystemIcons]::Application }
$trayIcon.Text = 'PixelZen Worlds'
$trayIcon.Visible = $true

$ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$miAbrir = $ctxMenu.Items.Add('Abrir PixelZen Worlds')
$miAbrir.Add_Click({
    $win.Show()
    $win.WindowState = 'Normal'
    $null = $win.Activate()
})

$miMundos = New-Object System.Windows.Forms.ToolStripMenuItem('Cambiar mundo rápido')
foreach ($t in $temas) {
    $sub = New-Object System.Windows.Forms.ToolStripMenuItem("$($t.anime) · $($t.titulo)")
    $sub.Tag = $t.id
    $sub.Add_Click({
        param($s, $e)
        $script:selectedTema = $s.Tag
        $script:selectedSerie = $script:worldSeries[$s.Tag]
        $c = Lee-FormConfig
        $c.tema = $s.Tag
        $fase = Aplicar-Todo $c
        $script:previewFase = $fase
        Actualiza-Vista
        $el.TxtEstado.Text = "✅ Mundo cambiado desde la bandeja."
    })
    $null = $miMundos.DropDownItems.Add($sub)
}
$null = $ctxMenu.Items.Add($miMundos)

$miSiguiente = $ctxMenu.Items.Add('🔀 Siguiente mundo')
$miSiguiente.Add_Click({
    $ids = @($temas | ForEach-Object { $_.id })
    if ($ids.Count -ge 2) {
        $idx = [Array]::IndexOf($ids, $script:selectedTema)
        $sig = $ids[($idx + 1) % $ids.Count]
        $script:selectedTema = $sig
        $script:selectedSerie = $script:worldSeries[$sig]
        $c = Lee-FormConfig; $c.tema = $sig
        $script:previewFase = Aplicar-Todo $c
        Actualiza-Vista
    }
})

$miClima = New-Object System.Windows.Forms.ToolStripMenuItem('🌦️ Clima dinámico')
foreach ($clPair in @(
    @('✨ Normal (Original)', 'normal'),
    @('🌧️ Lluvia suave', 'lluvia'),
    @('⛈️ Tormenta', 'tormenta'),
    @('❄️ Nieve', 'nieve'),
    @('🌫️ Niebla', 'niebla'),
    @('🌋 Ceniza / Brasas', 'ceniza'),
    @('🤖 Automático', 'auto')
)) {
    $subCl = New-Object System.Windows.Forms.ToolStripMenuItem($clPair[0])
    $subCl.Tag = $clPair[1]
    $subCl.Add_Click({
        param($s, $e)
        $script:syncingCombos = $true
        Set-ComboByTag $el.CmbClima ([string]$s.Tag) 0
        $script:syncingCombos = $false
        $c = Lee-FormConfig; $c.clima = [string]$s.Tag
        Guardar-Config $c
        $el.TxtEstado.Text = "🌦️ Clima cambiado a $($s.Tag)."
    })
    $null = $miClima.DropDownItems.Add($subCl)
}
$null = $ctxMenu.Items.Add($miClima)

$miMedia = New-Object System.Windows.Forms.ToolStripMenuItem('🎵 Control multimedia')
$mPlay = New-Object System.Windows.Forms.ToolStripMenuItem('⏯ Play / Pausa')
$mPlay.Add_Click({ [PzWinTheme]::SendMediaKey(0xB3) })
$mNext = New-Object System.Windows.Forms.ToolStripMenuItem('⏭ Siguiente pista')
$mNext.Add_Click({ [PzWinTheme]::SendMediaKey(0xB0) })
$mPrev = New-Object System.Windows.Forms.ToolStripMenuItem('⏮ Pista anterior')
$mPrev.Add_Click({ [PzWinTheme]::SendMediaKey(0xB1) })
$null = $miMedia.DropDownItems.AddRange(@($mPlay, $mNext, $mPrev))
$null = $ctxMenu.Items.Add($miMedia)

$miEvento = $ctxMenu.Items.Add('✦ Disparar evento épico')
$miEvento.Add_Click({
    $script:eventoSeq++
    $c = Lee-FormConfig; $c.eventoSeq = $script:eventoSeq
    Guardar-Config $c
})

$miHud = $ctxMenu.Items.Add('Mostrar / Ocultar cajitas HUD')
$miHud.Add_Click({ $el.BtnToggleHudNow.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent))) })

$miSoloW = $ctxMenu.Items.Add('🧩 Modo Solo Widgets (Wallpaper Engine)')
$miSoloW.Add_Click({ & $doApplySoloWidgets })

$null = $ctxMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$miSalir = $ctxMenu.Items.Add('Cerrar por completo')
$miSalir.Add_Click({
    $script:realClose = $true
    $win.Close()
})

$trayIcon.ContextMenuStrip = $ctxMenu
$trayIcon.Add_DoubleClick({
    $win.Show()
    $win.WindowState = 'Normal'
    $null = $win.Activate()
})

$el.BtnMiniTray.Add_Click({
    $win.Hide()
    $trayIcon.ShowBalloonTip(2500, 'PixelZen Worlds', 'Seguimos activos junto al reloj. Haz doble clic aquí para volver.', [System.Windows.Forms.ToolTipIcon]::Info)
})
$el.BtnSalirTotal.Add_Click({
    $script:realClose = $true
    $win.Close()
})

$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(20)
$clockTimer.Add_Tick({
    if ($el.TxtHubClock) { $el.TxtHubClock.Text = (Get-Date).ToString('HH:mm') }
})
$clockTimer.Start()

$win.Add_Closing({
    param($sender, $e)
    if (-not $script:realClose -and $el.ChkTrayCerrar.IsChecked) {
        $e.Cancel = $true
        $win.Hide()
    } else {
        if ($clockTimer) { $clockTimer.Stop() }
        $trayIcon.Visible = $false
        $trayIcon.Dispose()
    }
})

Cambia-Pestana 'hub'
Cambia-VistaMundo 'series'
Actualiza-Vista

$script:updCheckTimer = New-Object System.Windows.Threading.DispatcherTimer
$script:updCheckTimer.Interval = [TimeSpan]::FromMilliseconds(1400)
$script:updCheckTimer.Add_Tick({
    $script:updCheckTimer.Stop()
    try {
        $script:updPs = [powershell]::Create().AddScript({
            param($verLocal)
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/davidlpizano/pixelzen-worlds/releases/latest' -Headers @{ 'User-Agent' = 'PixelZenWorlds' } -TimeoutSec 8
                $remTag = ([string]$rel.tag_name).TrimStart('v', 'V')
                if ($remTag -and ([version]$remTag -gt [version]$verLocal)) { return $remTag }
            } catch {}
            return ''
        }).AddArgument($VersionActual)
        $script:updIar = $script:updPs.BeginInvoke()
        $script:updPoll = New-Object System.Windows.Threading.DispatcherTimer
        $script:updPoll.Interval = [TimeSpan]::FromMilliseconds(350)
        $script:updPoll.Add_Tick({
            if (-not $script:updIar.IsCompleted) { return }
            $script:updPoll.Stop()
            try {
                $resTag = ($script:updPs.EndInvoke($script:updIar) | Select-Object -First 1)
                if ($resTag) {
                    $el.BtnBuscarUpdate.Content = "⬆️ Actualizar a v$resTag"
                    $el.BtnBuscarUpdate.Visibility = 'Visible'
                }
            } catch {} finally {
                try { $script:updPs.Dispose() } catch {}
            }
        })
        $script:updPoll.Start()
    } catch {}
})
$script:updCheckTimer.Start()

if ($Tray) {
    $c = Cargar-Config
    $null = Aplicar-Todo $c
    $win.WindowState = 'Minimized'
    $win.ShowInTaskbar = $false
    $win.Add_Loaded({ $win.Hide(); $win.ShowInTaskbar = $true })
}

$null = $win.ShowDialog()
