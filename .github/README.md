# LC Install Script

A script for installing various mods for Lethal Company. It purges old mods and installs the BepInEx modloader along with new mods.

I would put a list a brief description of each of the notable mods here, but that would detract from the fun - the mystery of not knowing exactly what you're getting into is quite thrilling... Also it means I don't have to constantly update this readme.

# Usage

## Windows

Using _PowerShell 5.1 or later_, you can run the script directly in memory. Of course, it is not _generally_ recommended to just run random scripts from the internet, so I trust you've read through the code in the repo before running such commands.

To run the script in memory, open _PowerShell_ and paste this:
```
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/Sfven/lethal-company-mod-installer-script/refs/heads/main/install-script.ps1" | Invoke-Expression
```
You can of course repalce the `main` branch with whatever branch/tag you prefer.

## Linux

Using a Bash terminal, simply run the script with the following command:
```
curl -s "https://raw.githubusercontent.com/Sfven/lethal-company-mod-installer-script/refs/heads/main/install-script.sh" | bash
```
As with Windows, you can of course repalce the `main` branch with whatever branch/tag you prefer.