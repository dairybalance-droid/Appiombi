@echo off
setlocal

cd /d "%~dp0\.."

echo.
echo [Appiombi] Step 1/4 - Aggiorno il repository con git pull...
call git pull
if errorlevel 1 goto :fail_step_1

echo.
echo [Appiombi] Step 2/4 - Eseguo flutter pub get...
call flutter pub get
if errorlevel 1 goto :fail_step_2

echo.
echo [Appiombi] Step 3/4 - Eseguo flutter analyze...
call flutter analyze
if errorlevel 1 goto :fail_step_3

echo.
echo [Appiombi] Step 4/4 - Avvio Appiombi in Chrome...
call flutter run -d chrome
if errorlevel 1 goto :fail_step_4

echo.
echo [Appiombi] Esecuzione completata.
pause
exit /b 0

:fail_step_1
echo.
echo [Appiombi] ERRORE nello step 1 - git pull
pause
exit /b 1

:fail_step_2
echo.
echo [Appiombi] ERRORE nello step 2 - flutter pub get
pause
exit /b 1

:fail_step_3
echo.
echo [Appiombi] ERRORE nello step 3 - flutter analyze
pause
exit /b 1

:fail_step_4
echo.
echo [Appiombi] ERRORE nello step 4 - flutter run -d chrome
pause
exit /b 1
