@echo off
setlocal enabledelayedexpansion

echo Lethal Company mod installer/updater script, by Sfven.
echo ------------------------------------------------------

set "defaultDir=C:\Program Files (x86)\Steam\steamapps\common\Lethal Company"
set "downloadFolder=%USERPROFILE%\Downloads"

set "urls[0]=https://gcdn.thunderstore.io/live/repository/packages/notnotnotswipez-MoreCompany-1.7.5.zip"
set "urls[1]=https://gcdn.thunderstore.io/live/repository/packages/2018-LC_API-3.4.5.zip"
set "urls[2]=https://gcdn.thunderstore.io/live/repository/packages/Sligili-More_Emotes-1.3.3.zip"
set "urls[3]=https://gcdn.thunderstore.io/live/repository/packages/Ozone-Runtime_Netcode_Patcher-0.2.5.zip"
set "urls[4]=https://gcdn.thunderstore.io/live/repository/packages/sunnobunno-YippeeMod-1.2.3.zip"
set "urls[5]=https://gcdn.thunderstore.io/live/repository/packages/KoderTeh-Boombox_Controller-1.1.9.zip"
set "urls[6]=https://gcdn.thunderstore.io/live/repository/packages/anormaltwig-LateCompany-1.0.10.zip"
set "urls[7]=https://gcdn.thunderstore.io/live/repository/packages/atg-FreeJester-1.0.3.zip"
set "urls[8]=https://gcdn.thunderstore.io/live/repository/packages/no00ob-LCSoundTool-1.5.0.zip"
set "urls[9]=https://gcdn.thunderstore.io/live/repository/packages/Clementinise-CustomSounds-2.3.1.zip"
set "urls[10]=https://gcdn.thunderstore.io/live/repository/packages/PanHouse-LethalClunk-1.1.1.zip"
set "urls[11]=https://gcdn.thunderstore.io/live/repository/packages/x753-More_Suits-1.4.1.zip"
set "size=11"
set "bepinEx=https://gcdn.thunderstore.io/live/repository/packages/BepInEx-BepInExPack-5.4.2100.zip"

echo Tip: To copy a folder's location, shift+right click the folder and press 'Copy as path.'
echo Other tip: To paste that in here, use ctrl+shift+v.
echo.

set "extractPath=%defaultDir%"
set /p "extractPath=Enter path of your Lethal Company installation (Leave blank for default: '%extractPath%'): "
set extractPath=%extractPath:"=%
set "fileName=tmp.zip"
set "downloadPath=!downloadFolder!\!fileName!"

if not exist "%extractPath%" (
    echo Critial error: Path "%extractPath%" not found.
    pause
    goto :eof
)

if exist "%extractPath%\BepInEx\plugins" (
    echo Warning: Detected plugins folder. Removing...
    rmdir /S /Q "%extractPath%\BepInEx\plugins"
    echo Complete.
)

if not exist "%extractPath%\winhttp.dll" (
    echo Warning: winhttp.dll not detected. BepInExPack modloader must not be installed. It will now be installed.
    echo Downloading !bepinEx!...
    curl --ssl-no-revoke -so "%downloadPath%" "!bepinEx!"
    tar -xf "%downloadPath%" -C "%downloadFolder%"
    xcopy /E /Y /Q "%downloadFolder%\BepInExPack\*" "!extractPath!"
    del /S /Q "%downloadPath%"
    rmdir /S /Q "%downloadFolder%\BepInExPack"
    echo Complete.
)

for /L %%i in (0,1,%size%) do (
    set "url=!urls[%%i]!"
    echo Downloading !url!...
    curl --ssl-no-revoke -so "!downloadPath!" "!url!"
    if !errorLevel! equ 0 (
        echo Extracting to "!extractPath!"...
        tar -xf "!downloadPath!" -C "!extractPath!"
        if !errorLevel! equ 0 (
            echo Complete.
        ) else (
            echo Error extracting !fileName! to !extractPath!
        )
    ) else (
        echo Error downloading !url!
    )
)

echo Performing moves on mods that are not packaged correctly...
move "!extractPath!\YippeeMod.dll" "!extractPath!\BepInEx\plugins"
move "!extractPath!\yippeesound" "!extractPath!\BepInEx\plugins"
move "!extractPath!\FreeJester" "!extractPath!\BepInEx\plugins"
move "!extractPath!\NicholaScott.BepInEx.RuntimeNetcodeRPCValidator.dll" "!extractPath!\BepInEx\plugins"
echo Complete.

echo Cleaning up downloaded artifacts...
del /Q "!downloadPath!"
echo Complete.

endlocal
pause
