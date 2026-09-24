@echo off
cd /d "%~dp0"
title Pokemon GBA Studio++ (Launcher, Save Editor & Mod Manager)
echo ======================================================================
echo   Iniciando Pokemon GBA Studio++ (Launcher & Mod Manager)...
echo ======================================================================
echo.
echo Recursos:
echo   - 🕹️ JOGAR: Disparo instantaneo do mGBA integrado com saves sincronizados
echo   - 🎒 MOCHILA & ITENS: Injetor de Doces Raros, Master Balls, Dinheiro e Dex
echo   - ✨ SHINYDEX: Scanner em tempo real de Pokemons Shiny capturados
echo   - 💾 SAVE SLOTS: Alternancia, backup e criacao de slots independentes
echo   - 🧩 MODS: Traducao PT-BR, Exp. Share Moderno, Correr dentro de casas
echo.

if exist "C:\Program Files\LOVE\love.exe" (
    start "" "C:\Program Files\LOVE\love.exe" "%~dp0."
) else (
    start "" love "%~dp0."
)
