import { Injectable, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { CryptoService } from '../crypto/crypto.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { EnableMfaDto } from './dto/enable-mfa.dto';
import { VerifyMfaDto } from './dto/verify-mfa.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { authenticator } from 'otplib';
import * as QRCode from 'qrcode';
import { randomBytes } from 'crypto';

export interface JwtPayload {
  sub: string;
  email: string;
  role: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly crypto: CryptoService,
  ) {}

  async register(dto: RegisterDto) {
    const passwordHash = this.crypto.hashPassword(dto.password);
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        name: dto.name,
        licenseId: dto.licenseId,
        passwordHash,
      },
      select: { id: true, email: true, name: true, licenseId: true },
    });
    return user;
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || !this.crypto.verifyPassword(dto.password, user.passwordHash)) {
      throw new UnauthorizedException('Credenciais inválidas');
    }
    if (user.mfaEnabled && !dto.mfaCode) {
      return { mfaRequired: true };
    }
    if (user.mfaEnabled && dto.mfaCode) {
      const valid = authenticator.verify({
        token: dto.mfaCode,
        secret: user.mfaSecret!,
      });
      if (!valid) throw new UnauthorizedException('Código MFA inválido');
    }
    return this.generateTokens(user.id, user.email, user.role);
  }

  async refresh(refreshToken: string) {
    try {
      const payload = this.jwtService.verify<JwtPayload>(refreshToken);
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });
      if (!user) throw new UnauthorizedException();
      return this.generateTokens(user.id, user.email, user.role);
    } catch {
      throw new UnauthorizedException('Refresh token inválido');
    }
  }

  async setupMfa(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    const secret = authenticator.generateSecret();
    const otpauth = authenticator.keyuri(user.email, 'TerapiaPremium', secret);
    const qrCode = await QRCode.toDataURL(otpauth);
    await this.prisma.user.update({
      where: { id: userId },
      data: { mfaSecret: secret },
    });
    return { secret, qrCode };
  }

  async enableMfa(userId: string, dto: EnableMfaDto) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    const valid = authenticator.verify({
      token: dto.code,
      secret: user.mfaSecret!,
    });
    if (!valid) throw new UnauthorizedException('Código inválido');
    await this.prisma.user.update({
      where: { id: userId },
      data: { mfaEnabled: true },
    });
    return { enabled: true };
  }

  async verifyMfa(userId: string, dto: VerifyMfaDto) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
    });
    return {
      valid: authenticator.verify({
        token: dto.code,
        secret: user.mfaSecret!,
      }),
    };
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user) {
      // Não revela se o email existe (segurança)
      return { message: 'Se o email existir, enviaremos instruções' };
    }

    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hora

    await this.prisma.passwordResetToken.create({
      data: {
        token,
        userId: user.id,
        expiresAt,
      },
    });

    // Em produção: enviar email com link
    // await this.mailService.sendResetPassword(user.email, token);
    console.log(`[DEV] Token de recuperação para ${user.email}: ${token}`);

    return { message: 'Se o email existir, enviaremos instruções' };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const resetToken = await this.prisma.passwordResetToken.findUnique({
      where: { token: dto.token },
      include: { user: true },
    });

    if (!resetToken || resetToken.expiresAt < new Date() || resetToken.usedAt) {
      throw new UnauthorizedException('Token inválido ou expirado');
    }

    const passwordHash = this.crypto.hashPassword(dto.newPassword);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: resetToken.userId },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: resetToken.id },
        data: { usedAt: new Date() },
      }),
    ]);

    return { message: 'Senha alterada com sucesso' };
  }

  private generateTokens(userId: string, email: string, role: string) {
    const payload: JwtPayload = { sub: userId, email, role };
    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken: this.jwtService.sign(payload, {
        expiresIn: (process.env.JWT_REFRESH_EXPIRES_IN ||
          '7d') as import('@nestjs/jwt').JwtSignOptions['expiresIn'],
      }),
    };
  }
}
