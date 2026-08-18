import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePatientDto } from './dto/create-patient.dto';

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
}
