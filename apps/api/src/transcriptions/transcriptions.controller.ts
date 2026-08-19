import {
  Controller,
  Get,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TranscriptionsService } from './transcriptions.service';

@Controller('transcriptions')
@UseGuards(AuthGuard('jwt'))
export class TranscriptionsController {
  constructor(private readonly transcriptionsService: TranscriptionsService) {}

  @Get('sessions/:sessionId')
  findBySession(
    @Request() req: { user: { sub: string } },
    @Param('sessionId') sessionId: string,
  ) {
    return this.transcriptionsService.findBySession(sessionId, req.user.sub);
  }
}
