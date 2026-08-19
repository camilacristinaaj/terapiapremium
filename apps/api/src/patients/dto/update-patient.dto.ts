import { IsNotEmpty, IsOptional, IsString, IsISO8601 } from 'class-validator';

export class UpdatePatientDto {
  @IsString()
  @IsNotEmpty()
  @IsOptional()
  fullName?: string;

  @IsISO8601()
  @IsOptional()
  birthDate?: string;
}
