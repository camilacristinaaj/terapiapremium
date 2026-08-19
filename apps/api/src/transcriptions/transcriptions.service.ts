import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CryptoService } from '../crypto/crypto.service';

@Injectable()
export class TranscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly crypto: CryptoService,
  ) {}

  async findBySession(sessionId: string, professionalId: string) {
    // Verifica acesso
    const session = await this.prisma.session.findFirst({
      where: { id: sessionId, professionalId },
      include: { patient: true },
    });
    if (!session) throw new ForbiddenException('Sessão não autorizada');

    // Verifica consentimento para transcrição
    const consent = await this.prisma.consent.findFirst({
      where: {
        patientId: session.patientId,
        purpose: 'TRANSCRIPTION',
        revokedAt: null,
      },
    });
    if (!consent) {
      throw new ForbiddenException(
        'Consentimento de transcrição não encontrado para este paciente',
      );
    }

    const transcription = await this.prisma.transcription.findFirst({
      where: { sessionId },
      orderBy: { createdAt: 'desc' },
    });
    if (!transcription) throw new NotFoundException('Transcrição ainda não disponível');

    // Descriptografa apenas em memória
    const text = this.crypto.decrypt(
      Buffer.from(transcription.encryptedText),
    );

    // Log de auditoria
    await this.prisma.auditLog.create({
      data: {
        userId: professionalId,
        action: 'TRANSCRIPTION_VIEW',
        resourceId: transcription.id,
      },
    });

    return {
      id: transcription.id,
      sessionId,
      text,
      language: transcription.language,
      createdAt: transcription.createdAt,
    };
  }
}
