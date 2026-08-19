import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CryptoModule } from './crypto/crypto.module';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { PatientsModule } from './patients/patients.module';
import { SessionsModule } from './sessions/sessions.module';
import { RecordingsModule } from './recordings/recordings.module';
import { TranscriptionsModule } from './transcriptions/transcriptions.module';

@Module({
  imports: [
    PrismaModule,
    CryptoModule,
    AuthModule,
    PatientsModule,
    SessionsModule,
    RecordingsModule,
    TranscriptionsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
