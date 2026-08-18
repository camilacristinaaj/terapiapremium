import { CryptoService } from './crypto.service';

describe('CryptoService', () => {
  const keyHex =
    'a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90';
  let service: CryptoService;

  beforeEach(() => {
    process.env.ENCRYPTION_KEY = keyHex;
    service = new CryptoService();
  });

  afterEach(() => {
    delete process.env.ENCRYPTION_KEY;
  });

  it('criptografa e descriptografa texto', () => {
    const original = 'Transcrição confidencial da sessão';
    const encrypted = service.encrypt(original);
    expect(encrypted).toBeInstanceOf(Buffer);
    expect(encrypted.toString('utf8')).not.toContain(original);
    expect(service.decrypt(encrypted)).toBe(original);
  });

  it('gera IVs diferentes para o mesmo texto', () => {
    const a = service.encrypt('mesmo texto');
    const b = service.encrypt('mesmo texto');
    expect(a.equals(b)).toBe(false);
  });

  it('rejeita payload adulterado', () => {
    const encrypted = service.encrypt('dados clínicos');
    encrypted[encrypted.length - 1] ^= 0xff;
    expect(() => service.decrypt(encrypted)).toThrow();
  });

  it('faz hash e verifica senha', () => {
    const stored = service.hashPassword('SenhaForte!123');
    expect(stored).not.toContain('SenhaForte!123');
    expect(service.verifyPassword('SenhaForte!123', stored)).toBe(true);
    expect(service.verifyPassword('errada', stored)).toBe(false);
  });

  it('falha sem ENCRYPTION_KEY válida', () => {
    delete process.env.ENCRYPTION_KEY;
    expect(() => new CryptoService()).toThrow();
  });
});
