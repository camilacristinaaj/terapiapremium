import {
  Controller,
  Get,
  Param,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { FileInterceptor } from '@nestjs/platform-express';
import { RecordingsService } from './recordings.service';
import type { Response } from 'express';

@Controller('recordings')
@UseGuards(AuthGuard('jwt'))
export class RecordingsController {
  constructor(private readonly recordingsService: RecordingsService) {}

  @Post('sessions/:sessionId')
  @UseInterceptors(FileInterceptor('audio'))
  upload(
    @Request() req: { user: { sub: string } },
    @Param('sessionId') sessionId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.recordingsService.upload(req.user.sub, sessionId, file);
  }

  @Get(':id/download')
  async download(
    @Request() req: { user: { sub: string } },
    @Param('id') id: string,
    @Res() res: Response,
  ) {
    const { buffer, filename } = await this.recordingsService.download(
      id,
      req.user.sub,
    );
    res.set({
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${filename}"`,
    });
    res.send(buffer);
  }
}
