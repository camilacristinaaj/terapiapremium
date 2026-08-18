import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { RecordingsController } from './recordings.controller';
import { RecordingsService } from './recordings.service';
import { TranscriptionProcessor } from './transcription.processor';

@Module({
  imports: [
    BullModule.forRoot({
      connection: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379', 10),
      },
    }),
    BullModule.registerQueue({ name: 'transcription' }),
  ],
  controllers: [RecordingsController],
  providers: [RecordingsService, TranscriptionProcessor],
  exports: [RecordingsService],
})
export class RecordingsModule {}
