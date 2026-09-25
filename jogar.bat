@echo off
cd /d "%~dp0"
title Pokemon GBA Studio++

echo ======================================================================
echo   Iniciando Pokemon GBA Studio++...
echo ======================================================================
echo.
echo   - JOGAR: Disparo instantaneo do mGBA integrado
echo   - MOCHILA e ITENS: Injetor de Doces Raros, Master Balls e Dex
echo   - SHINYDEX: Scanner de Pokemons Shiny capturados
echo   - SAVE SLOTS: Alternancia e backup de slots
echo.

if exist "%~dp0tools\love\love.exe" (
    start "" "%~dp0tools\love\love.exe" "%~dp0."
    exit /b 0
)

if exist "C:\Program Files\LOVE\love.exe" (
    start "" "C:\Program Files\LOVE\love.exe" "%~dp0."
    exit /b 0
)

echo [INFO] LOVE2D nao encontrado. Iniciando diretamente no mGBA integrado...
echo.

if exist "%~dp0emulator\mGBA.exe" (
    start "" "%~dp0emulator\mGBA.exe" "%~dp0roms\Pokemon Kanto Johto.gba"
    exit /b 0
) else (
    echo [ERRO] Emulador mGBA nao encontrado em emulator\mGBA.exe!
    pause
)
