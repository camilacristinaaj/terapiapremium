@echo off
chcp 65001 >nul
echo ========================================
echo   TerapiaPremium - Iniciar Tudo
echo ========================================
echo.

cd /d %~dp0

echo [1/4] Subindo banco de dados...
docker compose up -d
if %errorlevel% neq 0 (
    echo [ERRO] Docker nao esta rodando. Abra o Docker Desktop primeiro.
    pause
    exit /b 1
)
echo OK - PostgreSQL e Redis rodando
echo.

echo [2/4] Aplicando migrations...
cd apps\api
npx prisma migrate dev
echo.

echo [3/4] Iniciando API em nova janela...
start "TerapiaPremium API" cmd /k "cd /d %~dp0apps\api && npm run start:dev"
timeout /t 5 /nobreak >nul

echo [4/4] Iniciando App em nova janela...
start "TerapiaPremium App" cmd /k "cd /d %~dp0apps\mobile && flutter run -d web-server --web-port=3002"

echo.
echo ========================================
echo   Tudo iniciado!
echo ========================================
echo.
echo API:      http://localhost:3000
echo Swagger:  http://localhost:3000/api/docs
echo App:      http://localhost:3002
echo.
echo Feche esta janela quando terminar.
pause
