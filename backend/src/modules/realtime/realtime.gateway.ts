import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { AccessTokenPayload } from '../auth/infrastructure/token.service';

/**
 * Real-time gateway (Socket.IO, namespace `/realtime`). Pushes live gameplay
 * events — level-ups, boss defeats, guild chat and leaderboard changes — to
 * connected clients. Clients are authenticated on connection with their access
 * JWT and auto-joined to their character and guild rooms.
 */
@WebSocketGateway({ cors: true, namespace: '/realtime' })
export class RealtimeGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * Authenticate the handshake by validating the access token, then join the
   * socket to its `character:{id}` room and (if any) its `guild:{id}` room so
   * targeted emits reach the right clients.
   */
  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = this.extractToken(client);
      if (!token) throw new Error('missing token');

      // Validates the same access token issued by the auth module.
      const payload = await this.jwt.verifyAsync<AccessTokenPayload>(token, {
        secret: this.config.get<string>('jwt.accessSecret'),
      });

      client.data.userId = payload.sub;
      client.data.characterId = payload.characterId;

      if (payload.characterId) {
        client.join(`character:${payload.characterId}`);
        const membership = await this.prisma.guildMember.findUnique({
          where: { characterId: payload.characterId },
          select: { guildId: true },
        });
        if (membership) {
          client.data.guildId = membership.guildId;
          client.join(`guild:${membership.guildId}`);
        }
      }

      this.logger.debug(`Socket connected: ${client.id} (user ${payload.sub})`);
    } catch (err) {
      this.logger.warn(`Rejecting socket ${client.id}: ${String(err)}`);
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    this.logger.debug(`Socket disconnected: ${client.id}`);
  }

  // ── Inbound messages ─────────────────────────────────────
  @SubscribeMessage('guild:message')
  handleGuildMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { text: string },
  ) {
    const guildId = client.data.guildId as string | undefined;
    if (!guildId) return { ok: false, error: 'not in a guild' };
    this.emitGuildMessage(guildId, {
      characterId: client.data.characterId,
      text: body?.text,
      at: new Date().toISOString(),
    });
    return { ok: true };
  }

  @SubscribeMessage('presence:ping')
  handlePresencePing(@ConnectedSocket() client: Socket) {
    return { type: 'presence:pong', at: Date.now(), id: client.id };
  }

  // ── Outbound emits (called by services) ──────────────────
  // `server` is only bound once the HTTP server is listening; guard so service
  // callers are safe during tests / before any client has connected.
  emitLevelUp(characterId: string, payload: unknown): void {
    this.server?.to(`character:${characterId}`).emit('level-up', payload);
  }

  emitBossDefeated(characterId: string, payload: unknown): void {
    this.server?.to(`character:${characterId}`).emit('boss-defeated', payload);
  }

  emitAchievementUnlocked(characterId: string, payload: unknown): void {
    this.server
      ?.to(`character:${characterId}`)
      .emit('achievement-unlocked', payload);
  }

  emitGuildMessage(guildId: string, payload: unknown): void {
    this.server?.to(`guild:${guildId}`).emit('guild:message', payload);
  }

  emitLeaderboardUpdate(guildId: string, payload: unknown): void {
    this.server?.to(`guild:${guildId}`).emit('leaderboard:update', payload);
  }

  /** Pull the access token from socket auth, query string, or auth header. */
  private extractToken(client: Socket): string | null {
    const auth = client.handshake.auth?.token as string | undefined;
    if (auth) return auth.replace(/^Bearer\s+/i, '');
    const query = client.handshake.query?.token;
    if (typeof query === 'string') return query;
    const header = client.handshake.headers?.authorization;
    if (header) return header.replace(/^Bearer\s+/i, '');
    return null;
  }
}
