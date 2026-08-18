import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';

@Injectable()
export class SessionsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(professionalId: string, dto: CreateSessionDto) {
    // Verifica se o paciente pertence ao profissional
    const patient = await this.prisma.patient.findFirst({
      where: { id: dto.patientId, professionalId },
    });
    if (!patient) throw new ForbiddenException('Paciente não autorizado');

    return this.prisma.session.create({
      data: {
        patientId: dto.patientId,
        professionalId,
        notes: dto.notes,
      },
      include: { patient: { select: { fullName: true } } },
    });
  }

  findAllByProfessional(professionalId: string) {
    return this.prisma.session.findMany({
      where: { professionalId },
      include: {
        patient: { select: { fullName: true } },
        _count: { select: { recordings: true, transcriptions: true } },
      },
      orderBy: { startedAt: 'desc' },
    });
  }

  async findOne(id: string, professionalId: string) {
    const session = await this.prisma.session.findFirst({
      where: { id, professionalId },
      include: {
        patient: true,
        recordings: true,
        transcriptions: { select: { id: true, createdAt: true } },
      },
    });
    if (!session) throw new NotFoundException('Sessão não encontrada');
    return session;
  }

  async update(id: string, professionalId: string, dto: UpdateSessionDto) {
    await this.findOne(id, professionalId); // garante acesso
    return this.prisma.session.update({
      where: { id },
      data: {
        notes: dto.notes,
        endedAt: dto.endSession ? new Date() : undefined,
        status: dto.endSession ? 'COMPLETED' : undefined,
      },
    });
  }

  async grantConsent(
    sessionId: string,
    professionalId: string,
    purpose: 'AUDIO_RECORDING' | 'TRANSCRIPTION',
  ) {
    const session = await this.findOne(sessionId, professionalId);
    return this.prisma.consent.create({
      data: {
        patientId: session.patientId,
        purpose,
        termVersion: '1.0',
      },
    });
  }
}
