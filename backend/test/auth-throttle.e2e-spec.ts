import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';

/**
 * The unauthenticated auth endpoints carry tight per-IP rate limits so login
 * brute-force / signup abuse is throttled well below the global API limit. A
 * fresh app instance means a fresh (in-memory) throttle window for this suite.
 */
describe('Auth rate limiting (e2e)', () => {
  let app: INestApplication;
  let http: ReturnType<INestApplication['getHttpServer']>;
  const api = '/api/v1';

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1', { exclude: ['health'] });
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        transformOptions: { enableImplicitConversion: true },
      }),
    );
    app.useGlobalFilters(new HttpExceptionFilter());
    app.useGlobalInterceptors(new TransformInterceptor());
    await app.init();
    http = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('throttles repeated login attempts with 429 past the limit', async () => {
    // Login limit is 8/min — the 9th attempt within the window is rejected.
    const statuses: number[] = [];
    for (let i = 0; i < 9; i++) {
      const res = await request(http)
        .post(`${api}/auth/login`)
        .send({ email: 'nobody@lifequest.app', password: 'wrong-Passw0rd!' });
      statuses.push(res.status);
    }

    // Early attempts are processed (bad credentials → 401), not throttled.
    expect(statuses[0]).toBe(401);
    // The attempt past the limit is rejected with 429 Too Many Requests.
    expect(statuses[statuses.length - 1]).toBe(429);
    expect(statuses.filter((s) => s === 429).length).toBeGreaterThan(0);
  });
});
