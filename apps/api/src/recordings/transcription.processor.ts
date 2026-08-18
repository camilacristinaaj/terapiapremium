import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { CryptoService } from '../crypto/crypto.service';
import { Injectable, Logger } from '@nestjs/common';
import { join } from 'path';
import { readFile } from 'fs/promises';

const STORAGE_DIR = process.env.STORAGE_DIR || './storage';

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

    // Descriptografa áudio
    const filePath = join(STORAGE_DIR, recording.storageKey);
    const encrypted = await readFile(filePath);
    const audioBase64 = this.crypto.decrypt(encrypted);
    const audioBuffer = Buffer.from(audioBase64, 'base64');

    // TODO: Integrar com Whisper self-hosted ou API
    // Por enquanto, mock da transcrição
    const mockText = `[MOCK] Transcrição da sessão ${sessionId} - ${audioBuffer.length} bytes de áudio processados.`;

    // Criptografa e salva transcrição
    const encryptedText = this.crypto.encrypt(mockText);
    await this.prisma.transcription.create({
      data: {
        sessionId,
        encryptedText: new Uint8Array(encryptedText),
        language: 'pt-BR',
        engine: 'mock',
      },
    });

    await this.prisma.session.update({
      where: { id: sessionId },
      data: { status: 'COMPLETED' },
    });

    this.logger.log(`Transcrição concluída para sessão ${sessionId}`);
  }
}
