import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateSessionDto {
  @IsString()
  @IsOptional()
  notes?: string;

  @IsBoolean()
  @IsOptional()
  endSession?: boolean;
}
