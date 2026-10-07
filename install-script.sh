#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[Error] script failed at line $LINENO." >&2' ERR

# 1 char, echo off, disabled backslash, assigned to '_'
pause() {
  echo "Press any key to continue..."
  read -n 1 -s -r _
}

die() {
  echo "[Error] $1"
  pause
  exit "${2:-1}" # Second arg passed to die() or 1 if null
}

# Download zip, failing on HTTP errors, retrying otherwise, & extract it to $2
fetch() {
  curl --fail --retry 3 -sSo "$zip" "$1" && unzip -oq "$zip" -d "$2"
}

echo "Lethal Company mod installer/updater script, by Sfven."
echo "------------------------------------------------------"

# Verify packages exist
missing=()
for cmd in curl unzip mktemp mv cp rm mkdir; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
(( ${#missing[@]} == 0 )) || die "Missing required packages: ${missing[*]}. Please install them using your package manager of choice." 2

echo "Tip: To copy a folder's location, right click the folder and press 'Copy as path.'"
echo "Other tip: To paste that in here, use ctrl+shift+v."
echo ""

defaultDir="$HOME/.steam/steam/steamapps/common/Lethal Company/"

# Temp dir for downloads, removed on EXIT
tmpDir="$(mktemp -d)"
trap 'rm -rf "$tmpDir"' EXIT
zip="$tmpDir/tmp.zip"

urls=(
  "https://ccdn.thunderstore.io/live/repository/packages/Bingle-MinecraftCaveSounds-1.0.0.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Electric131-OuijaBoard-1.5.5.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-HookGenPatcher-0.0.5.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Evaisa-LethalLib-1.1.1.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/FlipMods-TooManyEmotes-2.3.17.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/HGG-JigglePhysicsPlugin-1.1.2.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/JunLethalCompany-GamblingMachineAtTheCompany-1.3.5.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-Dont_Touch_Me-1.2.8.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-Herobrine-1.3.12.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Kittenji-NavMeshInCompany-1.0.3.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/KoderTeh-Boombox_Controller-1.2.7.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Kolton12O-OpenTheNoor-1.1.7.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Mhz-MoreHead-1.2.6.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/MonoDetour-MonoDetour-0.7.16.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/MonoDetour-MonoDetour_BepInEx_5-0.7.16.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Rune580-LethalCompany_InputUtils-0.7.10.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/Spantle-BidenSoda-1.1.3.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/TopraksuK-FreeBirdTotemRemixJester-1.0.1.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/anormaltwig-LateCompany-1.0.18.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/notnotnotswipez-MoreCompany-1.14.0.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/sunnobunno-LandMineFartReverb-1.0.3.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/sunnobunno-YippeeMod-1.2.4.zip"
  "https://ccdn.thunderstore.io/live/repository/packages/x753-More_Suits-1.5.4.zip"
)

# Modloader, installed if missing
bepinEx="https://ccdn.thunderstore.io/live/repository/packages/BepInEx-BepInExPack-5.4.2305.zip"

# Query game directory, default otherwise
read -r -p "Enter path of your Lethal Company installation (Leave blank for default: '$defaultDir'): " gameDir
gameDir="${gameDir:-$defaultDir}" # gameDir or defaultDir if null
gameDir="${gameDir//\"/}"   # strip quotes from 'Copy as path'
pluginsDir="$gameDir/BepInEx/plugins"

[[ -e "$gameDir" ]] || die "Path '$gameDir' not found."

# If 'plugins/' exists
if [[ -e "$pluginsDir" ]]; then
  echo "[Warn] Detected existing plugins folder."
  echo "1) Overwrite the contents (default)"
  echo "2) Create a backup, then overwrite"
  echo "3) Abort"
  while :; do
    read -r -p "Choose an option [1-3]: " choice
    case "${choice:-1}" in
      1)
        rm -r "$pluginsDir"
        ;;
      2)
        rm -rf "$pluginsDir.bak"
        mv "$pluginsDir" "$pluginsDir.bak"
        ;;
      3)
        echo "Aborted. No changes were made."
        pause
        exit 0
        ;;
      *)
        echo "[Error] Invalid choice."
        continue
    esac
    break
  done
fi

# Install winhttp.dll if not exist
if [[ ! -e "$gameDir/winhttp.dll" ]]; then
  echo "[Info] winhttp.dll not detected. Installing BepInExPack modloader..."
  fetch "$bepinEx" "$tmpDir/bepinex"
  cp -a "$tmpDir/bepinex/BepInExPack/." "$gameDir/"
fi

# Download mods
for i in "${urls[@]}"; do
  echo "[Info] Installing $i..."
  fetch "$i" "$gameDir" || echo "[Error] Failed to install $i"
done

# Deal with dumb mods
echo "[Info] Moving mods that are not packaged correctly..."
mkdir -p "$pluginsDir"
for i in YippeeMod.dll yippeesound FreeJester NicholaScott.BepInEx.RuntimeNetcodeRPCValidator.dll; do
  if [[ -e "$gameDir/$i" ]]; then
    mv "$gameDir/$i" "$pluginsDir/"
  else
    echo "[Warn] '$i' not found in '$gameDir', skipping."
  fi
done

echo "[Done]"
pause