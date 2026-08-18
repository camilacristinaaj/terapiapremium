# terapiapremium

Aplicativo para os profissionais da saúde mental gravar e transcrever as sessões de terapia.

## Estrutura do projeto

```
apps/
  mobile/   # App Flutter (Android/iOS)
  api/      # API NestJS (TypeScript)
docs/       # Arquitetura e conformidade LGPD
docker-compose.yml  # PostgreSQL + Redis (desenvolvimento)
```

## Começando

### Pré-requisitos

- Node.js 20+
- Flutter 3.x
- Docker (para PostgreSQL/Redis)

### Subir o banco de dados

```bash
docker compose up -d
```

### API

```bash
cd apps/api
cp .env.example .env   # preencha as variáveis
npm install
npx prisma migrate dev
npm run start:dev
```

### App mobile

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Documentação

- [Arquitetura](docs/arquitetura.md)
- [Conformidade LGPD](docs/lgpd-compliance.md) — **leitura obrigatória** antes de contribuir (dados sensíveis de saúde)
- [Setup do ambiente](docs/setup.md) — PostgreSQL, Redis, Whisper

## Segurança

Este projeto trata dados sensíveis de saúde. Nunca commite segredos,
áudios ou transcrições. Consulte `docs/lgpd-compliance.md`.
