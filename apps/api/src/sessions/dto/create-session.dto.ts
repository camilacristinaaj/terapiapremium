import { IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateSessionDto {
  @IsUUID()
  @IsNotEmpty()
  patientId!: string;

  @IsString()
  @IsOptional()
  notes?: string;
}
