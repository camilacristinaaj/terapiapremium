#!/usr/bin/env python3
"""
Worker de transcrição Whisper — TerapiaPremium

Uso: python transcribe.py <audio_path> [--model base] [--language pt]

Retorna JSON no stdout:
  {"text": "...", "language": "pt", "duration": 123.4}

Erros vão para stderr e exit code != 0.
"""

import argparse
import json
import sys
import os


def main() -> int:
    parser = argparse.ArgumentParser(description='Transcreve áudio com Whisper')
    parser.add_argument('audio_path', help='Caminho do arquivo de áudio')
    parser.add_argument('--model', default='base', help='Modelo Whisper (tiny, base, small, medium)')
    parser.add_argument('--language', default='pt', help='Idioma (pt, en, etc.)')
    parser.add_argument('--device', default='cpu', help='Dispositivo (cpu, cuda)')
    args = parser.parse_args()

    if not os.path.exists(args.audio_path):
        print(json.dumps({'error': f'Arquivo não encontrado: {args.audio_path}'}), file=sys.stderr)
        return 1

    try:
        import whisper
    except ImportError:
        print(json.dumps({'error': 'whisper não instalado. Rode: pip install openai-whisper'}), file=sys.stderr)
        return 1

    try:
        model = whisper.load_model(args.model, device=args.device)
        result = model.transcribe(args.audio_path, language=args.language, fp16=False)

        output = {
            'text': result['text'].strip(),
            'language': result.get('language', args.language),
            'duration': result.get('duration', 0),
        }
        print(json.dumps(output, ensure_ascii=False))
        return 0
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
