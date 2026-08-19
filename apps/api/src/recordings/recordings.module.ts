import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { CryptoModule } from '../crypto/crypto.module';
import { RecordingsController } from './recordings.controller';
import { RecordingsService } from './recordings.service';
import { TranscriptionProcessor } from './transcription.processor';

@Module({
  imports: [
    CryptoModule,
    BullModule.forRoot({
      connection: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379', 10),
        retryStrategy: (times: number) => Math.min(times * 50, 2000),
        maxRetriesPerRequest: 3,
        enableReadyCheck: true,
        lazyConnect: true,
      },
    }),
    BullModule.registerQueue({ name: 'transcription' }),
  ],
  controllers: [RecordingsController],
  providers: [RecordingsService, TranscriptionProcessor],
  exports: [RecordingsService],
})
export class RecordingsModule {}
