@echo off
cd /d G:\SteamLibrary\SteamApps\common\GarrysMod\bin
gmad.exe create -folder "D:/Projects/playx/" -out "D:/Projects/playx.gma"
gmpublish.exe update -addon "D:/Projects/playx.gma" -id 106516163
pause