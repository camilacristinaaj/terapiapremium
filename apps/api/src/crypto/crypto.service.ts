import { Injectable } from '@nestjs/common';
import {
  createCipheriv,
  createDecipheriv,
  randomBytes,
  scryptSync,
} from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const AUTH_TAG_LENGTH = 16;
const KEY_LENGTH = 32;

/**
 * Criptografia de dados sensíveis (áudio de sessões e transcrições).
 *
 * Formato do payload criptografado (Buffer):
 *   [IV 12B][authTag 16B][ciphertext]
 *
 * A chave vem de ENCRYPTION_KEY (hex, 32 bytes). Em produção, usar um
 * secret manager e rotação de chaves — nunca commitar a chave.
 */
@Injectable()
export class CryptoService {
  private readonly key: Buffer;

  constructor() {
    const hex = process.env.ENCRYPTION_KEY;
    if (!hex || hex.length !== KEY_LENGTH * 2) {
      throw new Error(
        'ENCRYPTION_KEY deve ser uma string hex de 64 caracteres (32 bytes). ' +
          'Gere com: node -e "console.log(require(\'crypto\').randomBytes(32).toString(\'hex\'))"',
      );
    }
    this.key = Buffer.from(hex, 'hex');
  }

  encrypt(plaintext: string): Buffer {
    const iv = randomBytes(IV_LENGTH);
    const cipher = createCipheriv(ALGORITHM, this.key, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });
    const encrypted = Buffer.concat([
      cipher.update(plaintext, 'utf8'),
      cipher.final(),
    ]);
    return Buffer.concat([iv, cipher.getAuthTag(), encrypted]);
  }

  decrypt(payload: Buffer): string {
    const iv = payload.subarray(0, IV_LENGTH);
    const authTag = payload.subarray(IV_LENGTH, IV_LENGTH + AUTH_TAG_LENGTH);
    const ciphertext = payload.subarray(IV_LENGTH + AUTH_TAG_LENGTH);
    const decipher = createDecipheriv(ALGORITHM, this.key, iv, {
      authTagLength: AUTH_TAG_LENGTH,
    });
    decipher.setAuthTag(authTag);
    return Buffer.concat([
      decipher.update(ciphertext),
      decipher.final(),
    ]).toString('utf8');
  }

  /** Deriva um hash de senha (scrypt) no formato salt:hash (hex). */
  hashPassword(password: string): string {
    const salt = randomBytes(16);
    const hash = scryptSync(password, salt, 64);
    return `${salt.toString('hex')}:${hash.toString('hex')}`;
  }

  verifyPassword(password: string, stored: string): boolean {
    const [saltHex, hashHex] = stored.split(':');
    if (!saltHex || !hashHex) return false;
    const hash = scryptSync(password, Buffer.from(saltHex, 'hex'), 64);
    const expected = Buffer.from(hashHex, 'hex');
    return hash.length === expected.length && hash.equals(expected);
  }
}
