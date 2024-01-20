#!/bin/sh

pause() {
  echo "Press any key to continue..."
  read -n 1 -s key
}

echo "Lethal Company mod installer/updater script, by Sfven."
echo "------------------------------------------------------"

defaultDir="/home/$(whoami)/.steam/steam/steamapps/common/Lethal Company/"
downloadFolder="/home/$(whoami)/Downloads"

urls=(
"https://gcdn.thunderstore.io/live/repository/packages/notnotnotswipez-MoreCompany-1.7.5.zip"
"https://gcdn.thunderstore.io/live/repository/packages/2018-LC_API-3.4.5.zip"
"https://gcdn.thunderstore.io/live/repository/packages/Sligili-More_Emotes-1.3.3.zip"
"https://gcdn.thunderstore.io/live/repository/packages/Ozone-Runtime_Netcode_Patcher-0.2.5.zip"
"https://gcdn.thunderstore.io/live/repository/packages/sunnobunno-YippeeMod-1.2.3.zip"
"https://gcdn.thunderstore.io/live/repository/packages/KoderTeh-Boombox_Controller-1.1.9.zip"
"https://gcdn.thunderstore.io/live/repository/packages/anormaltwig-LateCompany-1.0.10.zip"
"https://gcdn.thunderstore.io/live/repository/packages/atg-FreeJester-1.0.3.zip"
"https://gcdn.thunderstore.io/live/repository/packages/no00ob-LCSoundTool-1.5.0.zip"
"https://gcdn.thunderstore.io/live/repository/packages/Clementinise-CustomSounds-2.3.1.zip"
"https://gcdn.thunderstore.io/live/repository/packages/PanHouse-LethalClunk-1.1.1.zip"
"https://gcdn.thunderstore.io/live/repository/packages/x753-More_Suits-1.4.1.zip"
)
bepinEx="https://gcdn.thunderstore.io/live/repository/packages/BepInEx-BepInExPack-5.4.2100.zip"

echo "Tip: To copy a folder's location, right click the folder and press 'Copy as path.'"
echo "Other tip: To paste that in here, use ctrl+shift+v."
echo ""

read -p "Enter path of your Lethal Company installation (Leave blank for default: '$defaultDir'): " extractPath
extractPath="${extractPath:-$defaultDir}"
extractPath=${extractPath//\"/}
fileName="tmp.zip"
downloadPath="$downloadFolder/$fileName"

if [ ! -e "$extractPath" ]; then
  echo "Critical error: Path '$extractPath' not found."
  pause
  exit 1
fi

if [ -e "$extractPath/BepInEx/plugins/" ]; then
  echo "Warning: Detected plugins folder. Removing..."
  rm -r "$extractPath/BepInEx/plugins/"
  echo "Complete."
fi

if [ ! -e "$extractPath/winhttp.dll" ]; then
  echo "Warning: winhttp.dll not detected. BepInExPack modloader must not be installed. It will now be installed."
  echo "Downloading $bepinEx..."
  curl --ssl-no-revoke -so "$downloadPath" "$bepinEx"
  if ! command -v unzip >/dev/null 2>&1; then
    echo "Critical error: Package 'unzip' is not installed. Please install it using your package manager of choice."
    pause
    exit 2
  fi
  unzip -oq "$downloadPath" -d "$downloadFolder"
  mv "$downloadFolder/BepInExPack/"* "$extractPath"
  rm -r "$downloadFolder/BepInExPack/" "$downloadPath"
  echo "Complete."
fi

for url in "${urls[@]}"; do
  echo "Downloading $url..."
  if curl --ssl-no-revoke -so "$downloadPath" "$url"; then
    echo "Extracting to $extractPath/..."
    if unzip -oq "$downloadPath" -d "$extractPath"; then
      echo "Complete."
    else
      echo "Error extracting $fileName to $extractPath"
    fi
  else
    echo "Error downloading $url"
  fi
done

echo "Performing moves on mods that are not packaged correctly..."
mv \
"$extractPath/YippeeMod.dll" \
"$extractPath/yippeesound" \
"$extractPath/FreeJester/" \
"$extractPath/NicholaScott.BepInEx.RuntimeNetcodeRPCValidator.dll" \
"$extractPath/BepInEx/plugins/"
echo "Complete."

echo "Cleaning up downloaded artifacts..."
rm -r "$downloadPath"
echo "Complete."
pause
