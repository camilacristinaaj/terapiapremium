@echo off
chcp 65001 >nul
echo ========================================
echo   TerapiaPremium - Setup Completo
echo ========================================
echo.

cd /d %~dp0\..

echo [1/3] Subindo banco de dados...
docker compose up -d
if %errorlevel% neq 0 (
    echo [ERRO] Docker nao esta rodando. Abra o Docker Desktop primeiro.
    pause
    exit /b 1
)
echo OK - PostgreSQL e Redis rodando
echo.

echo [2/3] Aplicando migrations...
cd apps\api
npx prisma migrate dev
echo.

echo [3/3] Iniciando API...
echo Acesse: http://localhost:3000
echo Swagger: http://localhost:3000/api/docs
echo.
npm run start:dev
