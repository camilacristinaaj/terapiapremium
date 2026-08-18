import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  UseGuards,
  Request,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';
import { EnableMfaDto } from './dto/enable-mfa.dto';
import { VerifyMfaDto } from './dto/verify-mfa.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto) {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('mfa/setup')
  @UseGuards(AuthGuard('jwt'))
  setupMfa(@Request() req: { user: { sub: string } }) {
    return this.authService.setupMfa(req.user.sub);
  }

  @Post('mfa/enable')
  @UseGuards(AuthGuard('jwt'))
  enableMfa(
    @Request() req: { user: { sub: string } },
    @Body() dto: EnableMfaDto,
  ) {
    return this.authService.enableMfa(req.user.sub, dto);
  }

  @Post('mfa/verify')
  @HttpCode(HttpStatus.OK)
  @UseGuards(AuthGuard('jwt'))
  verifyMfa(
    @Request() req: { user: { sub: string } },
    @Body() dto: VerifyMfaDto,
  ) {
    return this.authService.verifyMfa(req.user.sub, dto);
  }
}
