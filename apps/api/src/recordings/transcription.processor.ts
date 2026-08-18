import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { CryptoService } from '../crypto/crypto.service';
import { Injectable, Logger } from '@nestjs/common';
import { join } from 'path';
import { readFile, writeFile, unlink } from 'fs/promises';
import { spawn } from 'child_process';
import { tmpdir } from 'os';

const STORAGE_DIR = process.env.STORAGE_DIR || './storage';
const WHISPER_WORKER = process.env.WHISPER_WORKER_PATH || 'workers/whisper/transcribe.py';
const WHISPER_MODEL = process.env.WHISPER_MODEL || 'base';

@Injectable()
@Processor('transcription')
export class TranscriptionProcessor extends WorkerHost {
  private readonly logger = new Logger(TranscriptionProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly crypto: CryptoService,
  ) {
    super();
  }

  async process(job: Job<{ recordingId: string; sessionId: string }>) {
    const { recordingId, sessionId } = job.data;
    this.logger.log(`Iniciando transcrição da gravação ${recordingId}`);

    const recording = await this.prisma.recording.findUnique({
      where: { id: recordingId },
    });
    if (!recording) {
      this.logger.error(`Gravação ${recordingId} não encontrada`);
      return;
    }

    // Descriptografa áudio em memória
    const filePath = join(STORAGE_DIR, recording.storageKey);
    const encrypted = await readFile(filePath);
    const audioBase64 = this.crypto.decrypt(encrypted);
    const audioBuffer = Buffer.from(audioBase64, 'base64');

    // Escreve em arquivo temporário (único ponto onde áudio fica em claro no disco)
    const tempPath = join(tmpdir(), `whisper_${recordingId}.m4a`);
    let text: string;
    let engine: string;

    try {
      await writeFile(tempPath, audioBuffer);
      text = await this.runWhisper(tempPath);
      engine = `whisper-${WHISPER_MODEL}`;
    } catch (err) {
      this.logger.warn(`Whisper falhou, usando fallback: ${err}`);
      text = `[ERRO NA TRANSCRIÇÃO] ${err instanceof Error ? err.message : String(err)}`;
      engine = 'error';
    } finally {
      // Garante remoção do arquivo temporário
      await unlink(tempPath).catch(() => {});
    }

    // Criptografa e salva transcrição
    const encryptedText = this.crypto.encrypt(text);
    await this.prisma.transcription.create({
      data: {
        sessionId,
        encryptedText: new Uint8Array(encryptedText),
        language: 'pt-BR',
        engine,
      },
    });

    await this.prisma.session.update({
      where: { id: sessionId },
      data: { status: engine === 'error' ? 'PROCESSING' : 'COMPLETED' },
    });

    this.logger.log(`Transcrição concluída para sessão ${sessionId}`);
  }

  private runWhisper(audioPath: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const proc = spawn('python', [
        WHISPER_WORKER,
        audioPath,
        '--model', WHISPER_MODEL,
        '--language', 'pt',
      ]);

      let stdout = '';
      let stderr = '';

      proc.stdout.on('data', (data: Buffer) => { stdout += data.toString(); });
      proc.stderr.on('data', (data: Buffer) => { stderr += data.toString(); });

      proc.on('close', (code) => {
        if (code !== 0) {
          reject(new Error(`Whisper exit ${code}: ${stderr}`));
          return;
        }
        try {
          const result = JSON.parse(stdout) as { text?: string };
          if (!result.text) {
            reject(new Error('Whisper retornou texto vazio'));
            return;
          }
          resolve(result.text);
        } catch {
          reject(new Error(`Whisper output inválido: ${stdout}`));
        }
      });

      proc.on('error', (err) => reject(err));
    });
  }
}
