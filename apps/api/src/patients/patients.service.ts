import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { UpdatePatientDto } from './dto/update-patient.dto';

@Injectable()
export class PatientsService {
  constructor(private readonly prisma: PrismaService) {}

  create(professionalId: string, dto: CreatePatientDto) {
    return this.prisma.patient.create({
      data: {
        fullName: dto.fullName,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : null,
        professionalId,
      },
    });
  }

  findAllByProfessional(professionalId: string) {
    return this.prisma.patient.findMany({
      where: { professionalId },
      orderBy: { fullName: 'asc' },
    });
  }

  async findOne(id: string, professionalId: string) {
    const patient = await this.prisma.patient.findFirst({
      where: { id, professionalId },
    });
    if (!patient) throw new NotFoundException('Paciente não encontrado');
    return patient;
  }

  async update(id: string, professionalId: string, dto: UpdatePatientDto) {
    await this.findOne(id, professionalId);
    return this.prisma.patient.update({
      where: { id },
      data: {
        fullName: dto.fullName,
        birthDate: dto.birthDate ? new Date(dto.birthDate) : undefined,
      },
    });
  }

  async remove(id: string, professionalId: string) {
    await this.findOne(id, professionalId);
    // Exclui sessões associadas primeiro (cascade manual)
    const sessions = await this.prisma.session.findMany({
      where: { patientId: id },
      select: { id: true },
    });
    for (const s of sessions) {
      await this.prisma.recording.deleteMany({ where: { sessionId: s.id } });
      await this.prisma.transcription.deleteMany({ where: { sessionId: s.id } });
    }
    await this.prisma.session.deleteMany({ where: { patientId: id } });
    await this.prisma.consent.deleteMany({ where: { patientId: id } });
    return this.prisma.patient.delete({ where: { id } });
  }
}
