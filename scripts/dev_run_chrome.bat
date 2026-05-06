@echo off
setlocal

cd /d "%~dp0\.."

echo.
echo [Appiombi] Step 1/4 - Aggiorno il repository con git pull...
git pull
if errorlevel 1 goto :fail

echo.
echo [Appiombi] Step 2/4 - Eseguo flutter pub get...
flutter pub get
if errorlevel 1 goto :fail

echo.
echo [Appiombi] Step 3/4 - Eseguo flutter analyze...
flutter analyze
if errorlevel 1 goto :fail

echo.
echo [Appiombi] Step 4/4 - Avvio Appiombi in Chrome...
flutter run -d chrome
if errorlevel 1 goto :fail

echo.
echo [Appiombi] Esecuzione completata.
pause
exit /b 0

:fail
echo.
echo [Appiombi] Esecuzione interrotta: uno dei comandi e' fallito.
pause
exit /b 1
