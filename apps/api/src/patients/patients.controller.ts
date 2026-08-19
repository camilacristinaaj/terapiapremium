import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { PatientsService } from './patients.service';
import { CreatePatientDto } from './dto/create-patient.dto';

@Controller('patients')
@UseGuards(AuthGuard('jwt'))
export class PatientsController {
  constructor(private readonly patientsService: PatientsService) {}

  @Post()
  create(
    @Request() req: { user: { sub: string } },
    @Body() dto: CreatePatientDto,
  ) {
    return this.patientsService.create(req.user.sub, dto);
  }

  @Get()
  findAll(@Request() req: { user: { sub: string } }) {
    return this.patientsService.findAllByProfessional(req.user.sub);
  }

  @Get(':id')
  findOne(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
  ) {
    return this.patientsService.findOne(id, req.user.sub);
  }
}
