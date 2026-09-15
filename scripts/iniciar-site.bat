@echo off
setlocal
cd /d "%~dp0.."
set "PORT=5500"
set "URL=http://127.0.0.1:%PORT%/admin.html"

echo.
echo  Kleimpaul - iniciando painel local...
echo.

where py >nul 2>nul
if %errorlevel%==0 goto use_py
where python >nul 2>nul
if %errorlevel%==0 goto use_python

echo Python nao encontrado. Usando servidor local do Windows PowerShell...
start "Kleimpaul - Servidor Local" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor-local.ps1"
timeout /t 2 /nobreak >nul
start "" "%URL%"
exit /b 0

:use_py
start "Kleimpaul - Servidor Local" cmd /k "cd /d ""%~dp0.."" && py -m http.server %PORT% --bind 127.0.0.1"
timeout /t 2 /nobreak >nul
start "" "%URL%"
exit /b 0

:use_python
start "Kleimpaul - Servidor Local" cmd /k "cd /d ""%~dp0.."" && python -m http.server %PORT% --bind 127.0.0.1"
timeout /t 2 /nobreak >nul
start "" "%URL%"
exit /b 0
