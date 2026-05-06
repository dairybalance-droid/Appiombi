@echo off
setlocal

cd /d "%~dp0"

set "SCRIPT_DIR=%~dp0"
set "TARGET_SCRIPT=%SCRIPT_DIR%dev_run_chrome.bat"
set "DESKTOP_DIR=%USERPROFILE%\Desktop"
set "SHORTCUT_PATH=%DESKTOP_DIR%\Appiombi Dev Chrome.lnk"
set "ICON_PATH=%SystemRoot%\System32\SHELL32.dll,220"

if not exist "%TARGET_SCRIPT%" (
  echo.
  echo [Appiombi] Script target non trovato:
  echo %TARGET_SCRIPT%
  pause
  exit /b 1
)

echo.
echo [Appiombi] Creo o aggiorno il collegamento Desktop...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ws = New-Object -ComObject WScript.Shell; " ^
  "$shortcut = $ws.CreateShortcut('%SHORTCUT_PATH%'); " ^
  "$shortcut.TargetPath = '%TARGET_SCRIPT%'; " ^
  "$shortcut.WorkingDirectory = '%SCRIPT_DIR%'; " ^
  "$shortcut.WindowStyle = 1; " ^
  "$shortcut.Description = 'Aggiorna e avvia Appiombi in Chrome'; " ^
  "$shortcut.IconLocation = '%ICON_PATH%'; " ^
  "$shortcut.Save()"

if errorlevel 1 goto :fail

echo.
echo [Appiombi] Collegamento creato o aggiornato con successo:
echo %SHORTCUT_PATH%
echo.
echo [Appiombi] Ora puoi avviare Appiombi con doppio clic su:
echo Appiombi Dev Chrome
pause
exit /b 0

:fail
echo.
echo [Appiombi] Errore nella creazione del collegamento Desktop.
pause
exit /b 1
