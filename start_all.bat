@echo off
REM ============================================================
REM  MedCare + ReadmitGuard - lancement de tous les services
REM  Prerequis : demarrer MySQL (et au besoin Apache) via XAMPP.
REM  Chaque service s'ouvre dans sa propre fenetre.
REM ============================================================

REM Cle secrete partagee du jeton ReadmitGuard (IDENTIQUE cote MedCare : config.local.php).
set READMITGUARD_SECRET=dev-secret-local-7f3a9c2e1b

cd /d "%~dp0"

echo ============================================================
echo   Rappel : demarrez MySQL via XAMPP avant de continuer.
echo ============================================================
echo.

REM 1. Site PHP MedCare (:8000)
start "MedCare - Site PHP :8000" cmd /k "php -S 127.0.0.1:8000 -t public"

REM 2. API MedCare - Doza + Sora (:8001)
start "MedCare - API :8001" cmd /k ".venv-api\Scripts\activate && uvicorn main:app --app-dir api --port 8001"

REM 3. API ReadmitGuard (:8002)  [8000 etait en conflit avec le site PHP]
start "ReadmitGuard - API :8002" cmd /k "set READMITGUARD_SECRET=%READMITGUARD_SECRET% && deployment\.venv\Scripts\activate && uvicorn main:app --app-dir deployment\api --port 8002"

REM 4. Streamlit ReadmitGuard (:8501)
start "ReadmitGuard - Streamlit :8501" cmd /k "set READMITGUARD_SECRET=%READMITGUARD_SECRET% && deployment\.venv\Scripts\activate && streamlit run deployment\app\Home.py --server.port 8501"

echo.
echo Services lances. Ouvrez :  http://127.0.0.1:8000
echo   - Site MedCare      : http://127.0.0.1:8000
echo   - API MedCare       : http://127.0.0.1:8001/health
echo   - API ReadmitGuard  : http://127.0.0.1:8002/health
echo   - Streamlit         : http://127.0.0.1:8501
echo.
pause
