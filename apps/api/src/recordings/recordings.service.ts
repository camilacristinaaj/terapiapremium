import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { PrismaService } from '../prisma/prisma.service';
import { CryptoService } from '../crypto/crypto.service';
import { createWriteStream, createReadStream, mkdirSync } from 'fs';
import { join } from 'path';
import { pipeline } from 'stream/promises';
import { v4 as uuidv4 } from 'uuid';
import type { Express } from 'express';

const STORAGE_DIR = process.env.STORAGE_DIR || './storage';

@Injectable()
export class RecordingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly crypto: CryptoService,
    @InjectQueue('transcription') private readonly transcriptionQueue: Queue,
  ) {
    mkdirSync(STORAGE_DIR, { recursive: true });
  }

  async upload(
    professionalId: string,
    sessionId: string,
    file: Express.Multer.File,
  ) {
    // Verifica acesso à sessão
    const session = await this.prisma.session.findFirst({
      where: { id: sessionId, professionalId },
      include: { patient: true },
    });
    if (!session) throw new ForbiddenException('Sessão não autorizada');

    // Verifica consentimento para gravação
    const consent = await this.prisma.consent.findFirst({
      where: {
        patientId: session.patientId,
        purpose: 'AUDIO_RECORDING',
        revokedAt: null,
      },
    });
    if (!consent) {
      throw new ForbiddenException(
        'Consentimento de gravação não encontrado para este paciente',
      );
    }

    // Criptografa o áudio
    const encrypted = this.crypto.encrypt(file.buffer.toString('base64'));
    const storageKey = `${uuidv4()}.enc`;
    const filePath = join(STORAGE_DIR, storageKey);

    await pipeline(
      createReadStream(Buffer.from(encrypted) as any),
      createWriteStream(filePath),
    );

    const recording = await this.prisma.recording.create({
      data: {
        sessionId,
        storageKey,
        durationSecs: null,
      },
    });

    // Enfileira transcrição assíncrona
    await this.transcriptionQueue.add('transcribe', {
      recordingId: recording.id,
      sessionId,
    });

    return { id: recording.id, status: 'PROCESSING' };
  }

  async download(id: string, professionalId: string) {
    const recording = await this.prisma.recording.findFirst({
      where: { id, session: { professionalId } },
      include: { session: true },
    });
    if (!recording) throw new NotFoundException('Gravação não encontrada');

    const filePath = join(STORAGE_DIR, recording.storageKey);
    const encrypted = await import('fs/promises').then((fs) =>
      fs.readFile(filePath),
    );
    const decrypted = this.crypto.decrypt(encrypted);
    const buffer = Buffer.from(decrypted, 'base64');

    return {
      buffer,
      filename: `sessao-${recording.sessionId}.m4a`,
    };
  }
}
