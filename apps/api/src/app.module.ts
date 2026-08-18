import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

import { CryptoModule } from './crypto/crypto.module';

@Module({
  imports: [CryptoModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
