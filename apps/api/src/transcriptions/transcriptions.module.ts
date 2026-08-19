import { Module } from '@nestjs/common';
import { CryptoModule } from '../crypto/crypto.module';
import { TranscriptionsController } from './transcriptions.controller';
import { TranscriptionsService } from './transcriptions.service';

@Module({
  imports: [CryptoModule],
  controllers: [TranscriptionsController],
  providers: [TranscriptionsService],
})
export class TranscriptionsModule {}
