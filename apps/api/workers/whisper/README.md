# Whisper Worker — Transcrição Local

Worker Python que roda **self-hosted** para transcrever áudio sem enviar dados para APIs externas.

## Requisitos

- Python 3.10+
- 4GB+ RAM (modelo `base` recomendado)
- Opcional: GPU CUDA para velocidade

## Instalação

```bash
pip install -r requirements.txt
```

## Uso

```bash
python transcribe.py <arquivo_audio> [--model base] [--language pt]
```

### Modelos disponíveis

| Modelo | RAM | Velocidade | Qualidade |
|--------|-----|-----------|-----------|
| tiny   | 1GB | Muito rápida | Básica |
| base   | 1GB | Rápida | Boa |
| small  | 2GB | Média | Muito boa |
| medium | 5GB | Lenta | Excelente |

**Recomendado:** `base` para produção, `tiny` para testes.

## Integração com a API

O worker é chamado pelo NestJS via fila BullMQ. O arquivo de áudio
(descriptografado temporariamente em memória) é passado como argumento.

**IMPORTANTE:** O arquivo temporário é deletado imediatamente após a
transcrição. Nenhum áudio em texto plano persiste no disco.
