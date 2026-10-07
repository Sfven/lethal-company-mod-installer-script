#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

# tmpDir stores downloads & gets rm'd in in finally{}
$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tmpDir | Out-Null
$zip = Join-Path $tmpDir 'tmp.zip'

# Download zip, retrying up to 3 times, throw HTTP errors
function Get-Zip($Url) {
  for ($try = 1; ; $try++) {
    try {
      Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing
      return
    } catch {
      if ($try -ge 3) {
        throw
      }
      Start-Sleep -Seconds 1
    }
  }
}

function Install-Mod($Url) {
  Get-Zip $Url
  # Get top level folder names in the zip
  $archive = [IO.Compression.ZipFile]::OpenRead($zip)
  try {
    $dirs = @($archive.Entries.FullName -replace '\\', '/' |
      Where-Object { $_ -like '*/*' } |
      ForEach-Object { ($_ -split '/')[0] })
  } finally {
    $archive.Dispose()
  }

  $dest = $pluginsDir
  if ($dirs -contains 'BepInEx') {
    $dest = $gameDir
  } elseif ('config', 'core', 'patchers', 'plugins' | Where-Object { $dirs -contains $_ }) {
    $dest = Join-Path $gameDir 'BepInEx'
  }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  Expand-Archive -LiteralPath $zip -DestinationPath $dest -Force
  foreach ($f in 'CHANGELOG.md', 'icon.png', 'LICENSE', 'manifest.json', 'README.md') {
    Remove-Item -LiteralPath (Join-Path $dest $f) -Recurse -Force -ErrorAction SilentlyContinue
  }
}

$exitCode = 0
try {
  Write-Host "Lethal Company mod installer/updater script, by Sfven."
  Write-Host "-------------------------------------------------------"

  Write-Host ""
  Write-Host "Tip: To copy a folder's location, shift+right-click the folder and press 'Copy as path.'"
  Write-Host "Other tip: To paste that in here, right-click in the terminal or use ctrl+v."
  Write-Host ""

  if ($env:OS -eq 'Windows_NT') {
    $defaultDir = Join-Path ${env:ProgramFiles(x86)} 'Steam\steamapps\common\Lethal Company'
  } else {
    $defaultDir = Join-Path $HOME '.steam/steam/steamapps/common/Lethal Company'
  }

  $urls = @(
    "https://ccdn.thunderstore.io/live/repository/packages/Bingle-MinecraftCaveSounds-1.0.0.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Clementinise-CustomSounds-2.3.2.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Electric131-OuijaBoard-1.5.5.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-HookGenPatcher-0.0.5.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-LethalLib-1.2.0.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-LethalThings-0.10.13.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/FlipMods-TooManyEmotes-2.3.17.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/HGG-JigglePhysicsPlugin-1.1.2.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-Dont_Touch_Me-1.2.8.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-Herobrine-1.3.12.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-NavMeshInCompany-1.0.3.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/KlippKlubben-DraculaFlowBug-1.2.0.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/KoderTeh-Boombox_Controller-1.2.7.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Kolton12O-OpenTheNoor-1.1.7.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Mhz-MoreHead-1.2.6.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/MonoDetour-MonoDetour-0.7.16.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/MonoDetour-MonoDetour_BepInEx_5-0.7.16.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Rune580-LethalCompany_InputUtils-0.7.10.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/Spantle-BidenSoda-1.1.3.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/TopraksuK-FreeBirdTotemRemixJester-1.0.1.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/anormaltwig-LateCompany-1.0.18.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/mrgrm7-LethalCasino-1.1.3.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/no00ob-LCSoundTool-1.5.1.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/notnotnotswipez-MoreCompany-1.14.0.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/sunnobunno-LandMineFartReverb-1.0.3.zip"
    "https://ccdn.thunderstore.io/live/repository/packages/x753-More_Suits-1.5.4.zip"
  )

  # Modloader, always reinstalled
  $bepinEx = "https://ccdn.thunderstore.io/live/repository/packages/BepInEx-BepInExPack-5.4.2305.zip"

  # Query game directory, default otherwise
  $gameDir = Read-Host "Enter path of your Lethal Company installation (Leave blank for default: '$defaultDir')"
  if ([string]::IsNullOrEmpty($gameDir)) {
    $gameDir = $defaultDir # default if blank
  }
  $gameDir = $gameDir -replace '"', '' # strip quotes
  $gameDir = $gameDir.TrimEnd('\', '/') # remove trailing slash
  $pluginsDir = Join-Path $gameDir 'BepInEx/plugins'

  if (-not (Test-Path -LiteralPath $gameDir)) {
    throw "Path '$gameDir' not found."
  }

  # In case 'BepInEx/' exists rm it & its components - we want a fresh install with no old tainted mods
  Write-Host "[Info] Installing $bepinEx"
  foreach ($i in 'BepInEx', 'winhttp.dll', 'doorstop_config.ini', '.doorstop_version') {
    Remove-Item -LiteralPath (Join-Path $gameDir $i) -Recurse -Force -ErrorAction SilentlyContinue
  }
  Get-Zip $bepinEx
  Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmpDir 'bepinex') -Force
  Get-ChildItem -LiteralPath (Join-Path $tmpDir 'bepinex/BepInExPack') -Force | Copy-Item -Destination $gameDir -Recurse -Force

  # Download mods
  foreach ($i in $urls) {
    Write-Host "[Info] Installing $i"
    try {
      Install-Mod $i
    } catch {
      Write-Host "[Warn] Failed to install $i. ($($_.Exception.Message))" -ForegroundColor Yellow
    }
  }

  Write-Host "[Done]"
} catch {
  Write-Host "[Error] $($_.Exception.Message) (script line $($_.InvocationInfo.ScriptLineNumber))" -ForegroundColor Red
  $exitCode = 1
} finally {
  Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}
exit $exitCode