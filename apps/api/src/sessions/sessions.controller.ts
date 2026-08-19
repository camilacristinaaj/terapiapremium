import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { SessionsService } from './sessions.service';
import { CreateSessionDto } from './dto/create-session.dto';
import { UpdateSessionDto } from './dto/update-session.dto';

@Controller('sessions')
@UseGuards(AuthGuard('jwt'))
export class SessionsController {
  constructor(private readonly sessionsService: SessionsService) {}

  @Post()
  create(
    @Request() req: { user: { sub: string } },
    @Body() dto: CreateSessionDto,
  ) {
    return this.sessionsService.create(req.user.sub, dto);
  }

  @Get()
  findAll(@Request() req: { user: { sub: string } }) {
    return this.sessionsService.findAllByProfessional(req.user.sub);
  }

  @Get(':id')
  findOne(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
  ) {
    return this.sessionsService.findOne(id, req.user.sub);
  }

  @Patch(':id')
  update(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
    @Body() dto: UpdateSessionDto,
  ) {
    return this.sessionsService.update(id, req.user.sub, dto);
  }

  @Post(':id/consent')
  grantConsent(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
    @Body() body: { purpose: 'AUDIO_RECORDING' | 'TRANSCRIPTION' },
  ) {
    return this.sessionsService.grantConsent(id, req.user.sub, body.purpose);
  }

  @Delete(':id')
  remove(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
  ) {
    return this.sessionsService.remove(id, req.user.sub);
  }
}
