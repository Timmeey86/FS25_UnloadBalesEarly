@echo off
for %%a in ("%~dp0\.") do set "modname=%%~nxa"
set "targetDir=%USERPROFILE%\Documents\my games\FarmingSimulator2025\mods"
del -q "%targetDir%\%modname%.zip"
robocopy . "%targetDir%\%modname%" /mir /XD ".git" ".vscode" "screenshots" "test" /XF "*.bat" "*.ps1" "*.md" "LICENSE" ".gitignore" ".gitattributes"