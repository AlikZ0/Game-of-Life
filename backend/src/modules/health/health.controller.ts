import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';

@ApiTags('health')
@Controller()
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  @Public()
  @Get('health')
  @ApiOperation({ summary: 'Liveness probe — process is up' })
  liveness() {
    return {
      status: 'ok',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  }

  @Public()
  @Get('health/ready')
  @ApiOperation({
    summary: 'Readiness probe — dependencies reachable (DB + Redis)',
  })
  async readiness() {
    const [db, redis] = await Promise.all([
      this.checkDb(),
      this.redis.isHealthy(),
    ]);
    const ready = db && redis;
    return {
      status: ready ? 'ok' : 'degraded',
      dependencies: {
        db: db ? 'up' : 'down',
        redis: redis ? 'up' : 'down',
      },
      timestamp: new Date().toISOString(),
    };
  }

  private async checkDb(): Promise<boolean> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch {
      return false;
    }
  }
}
