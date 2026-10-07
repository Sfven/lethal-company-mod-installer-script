#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[Error] script failed at line $LINENO." >&2' ERR

die() {
  echo "[Error] $1"
  exit "${2:-1}" # 2nd arg passed to die() or 1 if null
}

# Temp dir for downloads, removed on EXIT
tmpDir="$(mktemp -d)"
trap 'rm -rf "$tmpDir"' EXIT
zip="$tmpDir/tmp.zip"

# Download zip, failing on HTTP errors, retrying otherwise
fetch() {
  curl --retry 3 -Sfso "$zip" "$1"
}

installMod() {
  fetch "$1" || return
  local entries dest="$pluginsDir"
  # Newline-padded listing (no pipe, avoids SIGPIPE under pipefail) anchors matches to entry starts
  entries=$'\n'"$(unzip -Z1 "$zip")" || return
  if [[ $entries == *$'\n'BepInEx/* ]]; then
    dest="$gameDir"
  elif [[ $entries == *$'\n'config/* || $entries == *$'\n'core/* || $entries == *$'\n'patchers/* || $entries == *$'\n'plugins/* ]]; then
    dest="$gameDir/BepInEx"
  fi
  mkdir -p "$dest"
  unzip -oq "$zip" -d "$dest"
  rm -rf "$dest/CHANGELOG.md" "$dest/icon.png" "$dest/LICENSE" "$dest/manifest.json" "$dest/README.md"
}

echo "Lethal Company mod installer/updater script, by Sfven."
echo "-------------------------------------------------------"

# Verify packages exist
missing=()
for i in curl unzip mktemp; do
  command -v "$i" >/dev/null 2>&1 || missing+=("$i")
done
(( ${#missing[@]} == 0 )) || die "Missing required packages: ${missing[*]}. Please install them using your package manager of choice." 2

echo ""
echo "Tip: To copy a folder's location, right click the folder and press 'Copy as path.'"
echo "Other tip: To paste that in here, use ctrl+shift+v."
echo ""

defaultDir="$HOME/.steam/steam/steamapps/common/Lethal Company"

urls=(
  "https://ccdn.thunderstore.io/live/repository/packages/Bingle-MinecraftCaveSounds-1.0.0.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Clementinise-CustomSounds-2.3.2.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Electric131-OuijaBoard-1.5.5.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-HookGenPatcher-0.0.5.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-LethalLib-1.1.1.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-LethalThings-0.10.13.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/FlipMods-TooManyEmotes-2.3.17.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/HGG-JigglePhysicsPlugin-1.1.2.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/JunLethalCompany-GamblingMachineAtTheCompany-1.3.5.zip"
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
  "https://ccdn.thunderstore.io/live/repository/packages/no00ob-LCSoundTool-1.5.1.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/notnotnotswipez-MoreCompany-1.14.0.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/sunnobunno-LandMineFartReverb-1.0.3.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/x753-More_Suits-1.5.4.zip"
)

# Modloader, installed if missing
bepinEx="https://ccdn.thunderstore.io/live/repository/packages/BepInEx-BepInExPack-5.4.2305.zip"

# Query game directory, default otherwise
read -r -p "Enter path of your Lethal Company installation (Leave blank for default: '$defaultDir'): " gameDir
gameDir="${gameDir:-$defaultDir}" # gameDir or defaultDir if null
gameDir="${gameDir//\"/}" # strip quotes
gameDir="${gameDir%/}" # remove trailing /
pluginsDir="$gameDir/BepInEx/plugins"

[[ -e "$gameDir" ]] || die "Path '$gameDir' not found."

# If 'BepInEx/' exists rm it
if [[ -e "$gameDir/BepInEx" ]]; then
  echo "[Info] Detected existing mod loader folder. Removing..."
  rm -rf "$gameDir/BepInEx" 'winhttp.dll' 'doorstop_config.ini'
  echo "[Info] Installing $bepinEx"
  fetch "$bepinEx"
  unzip -oq "$zip" -d "$tmpDir/bepinex"
  cp -a "$tmpDir/bepinex/BepInExPack/." "$gameDir/"
fi

# Download mods
for i in "${urls[@]}"; do
  echo "[Info] Installing $i"
  installMod "$i" || echo "[Warn] Failed to install $i."
done

echo "[Done]"