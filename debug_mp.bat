set "MODFOLDER=%USERPROFILE%\Documents\my games\FarmingSimulator2025\mods\"
set "MODNAME=FS25_UnloadBalesEarly"
robocopy . "%MODFOLDER%\%MODNAME%" /mir /XD ".git" ".vscode" ".VSCodeCounter" "screenshots" "doc" /XF "*.bat" "*.md" "LICENSE" ".gitignore" ".gitattributes"
pushd %MODFOLDER%\%MODNAME%
tar -a -c -f ..\%MODNAME%.zip *.*
popd
rmdir /s /q "%MODFOLDER%\%MODNAME%"
start "" "E:\Games\Farming Simulator 2025\FarmingSimulator2025.exe" -skipStartVideos