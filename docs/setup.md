# Setup do Ambiente — TerapiaPremium

## 1. Banco de dados (PostgreSQL + Redis)

### Opção A: Docker (recomendado)

1. Instale o [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Na raiz do projeto:

```bash
docker compose up -d
```

3. Verifique:

```bash
docker compose ps
```

### Opção B: Instalação local (Windows)

**PostgreSQL:**
- Baixe: https://www.postgresql.org/download/windows/
- Instale com senha e anote a porta (padrão 5432)
- Crie o banco:

```sql
CREATE DATABASE terapiapremium;
CREATE USER terapiapremium WITH PASSWORD 'sua-senha';
GRANT ALL PRIVILEGES ON DATABASE terapiapremium TO terapiapremium;
```

**Redis:**
- Baixe: https://github.com/tporadowski/redis/releases
- Extraia e rode `redis-server.exe`

---

## 2. Configurar a API

```bash
cd apps/api
cp .env.example .env
```

Edite `.env`:

```env
DB_PASSWORD=sua-senha-do-postgres
DATABASE_URL=postgresql://terapiapremium:sua-senha-do-postgres@localhost:5432/terapiapremium
ENCRYPTION_KEY=  # Gere: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
JWT_SECRET=      # Gere: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Aplique as migrations:

```bash
npx prisma migrate dev
```

---

## 3. Configurar o Whisper (transcrição)

### Instalar dependências Python

```bash
cd apps/api/workers/whisper
pip install -r requirements.txt
```

### Testar o worker

```bash
# Baixe um arquivo de áudio de teste ou grave um
python transcribe.py teste.m4a --model tiny --language pt
```

### Configurar a API para usar Whisper real

Edite `apps/api/.env`:

```env
WHISPER_WORKER_PATH=workers/whisper/transcribe.py
WHISPER_MODEL=base   # ou tiny, small, medium
```

---

## 4. Rodar tudo

Terminal 1 — API:

```bash
cd apps/api
npm run start:dev
```

Terminal 2 — App Flutter:

```bash
cd apps/mobile
flutter run
```

---

## 5. Verificar

- API: http://localhost:3000
- Banco: `npx prisma studio` (interface visual)

---

## Troubleshooting

| Problema | Solução |
|----------|---------|
| `ECONNREFUSED` no Postgres | Verifique se o container/serviço está rodando |
| Whisper muito lento | Use modelo `tiny` ou `base`; considere GPU |
| `ENCRYPTION_KEY` inválida | Gere 64 caracteres hex (32 bytes) |
| Flutter não conecta | Em dispositivo físico, use o IP da máquina, não `localhost` |
