import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { EmailDomainService } from './email-domain.service';
import { GoogleTokenService } from './google-token.service';
import { UsersService } from '../users/users.service';

describe('AuthService.loginWithGoogle', () => {
  const usersService = {
    findByGoogleSub: jest.fn(),
    findByEmail: jest.fn(),
    linkGoogleSub: jest.fn(),
    create: jest.fn(),
    findPetName: jest.fn(),
    syncTutorFromGoogle: jest.fn(),
  };
  const jwtService = {
    sign: jest.fn().mockReturnValue('jwt-token'),
  };
  const emailDomainService = {
    assertDeliverableDomain: jest.fn(),
  };
  const googleTokenService = {
    verifyIdToken: jest.fn(),
  };

  const service = new AuthService(
    usersService as unknown as UsersService,
    jwtService as unknown as JwtService,
    emailDomainService as unknown as EmailDomainService,
    googleTokenService as unknown as GoogleTokenService,
  );

  beforeEach(() => {
    jest.clearAllMocks();
    usersService.findPetName.mockResolvedValue(null);
    usersService.syncTutorFromGoogle.mockResolvedValue(undefined);
    googleTokenService.verifyIdToken.mockResolvedValue({
      googleSub: 'google-sub-1',
      email: 'luna@gmail.com',
      emailVerified: true,
      name: 'Luna',
      picture: 'https://example.com/a.png',
    });
  });

  it('devuelve JWT si ya existe googleSub', async () => {
    usersService.findByGoogleSub.mockResolvedValue({
      id: 'u1',
      email: 'luna@gmail.com',
    });

    const result = await service.loginWithGoogle({ idToken: 'tok' });

    expect(result).toEqual({
      accessToken: 'jwt-token',
      needsPetOnboarding: true,
    });
    expect(usersService.create).not.toHaveBeenCalled();
  });

  it('vincula Google si el email ya existe', async () => {
    usersService.findByGoogleSub.mockResolvedValue(null);
    usersService.findByEmail.mockResolvedValue({
      id: 'u2',
      email: 'luna@gmail.com',
    });
    usersService.linkGoogleSub.mockResolvedValue({
      id: 'u2',
      email: 'luna@gmail.com',
    });

    const result = await service.loginWithGoogle({ idToken: 'tok' });

    expect(usersService.linkGoogleSub).toHaveBeenCalledWith(
      'u2',
      'google-sub-1',
    );
    expect(result.accessToken).toBe('jwt-token');
  });

  it('crea usuario nuevo sin password', async () => {
    usersService.findByGoogleSub.mockResolvedValue(null);
    usersService.findByEmail.mockResolvedValue(null);
    usersService.create.mockResolvedValue({
      id: 'u3',
      email: 'luna@gmail.com',
    });

    const result = await service.loginWithGoogle({ idToken: 'tok' });

    expect(usersService.create).toHaveBeenCalledWith({
      email: 'luna@gmail.com',
      passwordHash: null,
      googleSub: 'google-sub-1',
      profileName: 'Luna',
      avatarUrl: 'https://example.com/a.png',
    });
    expect(result).toEqual({
      accessToken: 'jwt-token',
      needsPetOnboarding: true,
    });
  });

  it('no pide onboarding si la mascota ya tiene nombre', async () => {
    usersService.findByGoogleSub.mockResolvedValue({
      id: 'u1',
      email: 'luna@gmail.com',
    });
    usersService.findPetName.mockResolvedValue('Firulais');

    const result = await service.loginWithGoogle({ idToken: 'tok' });

    expect(result.needsPetOnboarding).toBe(false);
  });

  it('login email falla claro si solo tiene Google', async () => {
    usersService.findByEmail.mockResolvedValue({
      id: 'u4',
      email: 'luna@gmail.com',
      passwordHash: null,
    });

    await expect(
      service.login({ email: 'luna@gmail.com', password: 'x' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
