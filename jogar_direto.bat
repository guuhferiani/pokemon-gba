@echo off
cd /d "%~dp0"
title Pokemon Kanto e Johto (mGBA)

echo ======================================================================
echo   Iniciando Pokemon Kanto e Johto diretamente no mGBA integrado...
echo ======================================================================
echo.

if exist "%~dp0emulator\mGBA.exe" (
    if exist "%~dp0roms\Pokemon Kanto Johto.gba" (
        start "" "%~dp0emulator\mGBA.exe" "%~dp0roms\Pokemon Kanto Johto.gba"
        exit /b 0
    ) else if exist "%~dp0roms\Pokemon_Kanto_Johto.gba" (
        start "" "%~dp0emulator\mGBA.exe" "%~dp0roms\Pokemon_Kanto_Johto.gba"
        exit /b 0
    ) else (
        echo [ERRO] ROM nao encontrada na pasta roms!
        pause
    )
) else (
    echo [ERRO] Emulador mGBA nao encontrado em emulator\mGBA.exe!
    pause
)
