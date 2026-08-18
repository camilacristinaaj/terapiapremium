import { IsNotEmpty, IsOptional, IsString, IsISO8601 } from 'class-validator';

export class CreatePatientDto {
  @IsString()
  @IsNotEmpty()
  fullName!: string;

  @IsISO8601()
  @IsOptional()
  birthDate?: string;
}
