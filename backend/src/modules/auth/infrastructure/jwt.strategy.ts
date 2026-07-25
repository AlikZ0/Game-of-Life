import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { AccessTokenPayload } from './token.service';

/**
 * Validates the access JWT and resolves the authenticated principal, attaching
 * the user's characterId (if created) so downstream handlers can authorise by
 * character ownership without an extra query.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('jwt.accessSecret'),
    });
  }

  async validate(payload: AccessTokenPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { character: { select: { id: true } } },
    });
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User no longer active');
    }
    return {
      userId: user.id,
      email: user.email,
      characterId: user.character?.id,
    };
  }
}
