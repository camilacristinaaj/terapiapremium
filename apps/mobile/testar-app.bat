@echo off
chcp 65001 >nul
echo ========================================
echo   TerapiaPremium - Iniciando App
echo ========================================
echo.

cd /d %~dp0

echo Verificando API...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] API nao esta rodando em localhost:3000
    echo Execute primeiro: cd ..\api ^& npm run start:dev
    echo.
)

echo Iniciando app na porta 3002...
echo Acesse: http://localhost:3002
echo.
flutter run -d web-server --web-port=3002

pause
