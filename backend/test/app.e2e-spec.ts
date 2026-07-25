import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';

/**
 * Smoke e2e: boots the full Nest app and hits the public liveness probe.
 * Illustrative — it exercises the real wiring and therefore needs a reachable
 * database (the /health handler performs a `SELECT 1` round-trip).
 */
describe('App (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    // /health is registered without the global API prefix, so we don't set one.
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health → 200 with a status field', async () => {
    const res = await request(app.getHttpServer()).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('status');
  });

  it('GET /health/ready → reports DB + Redis dependencies', async () => {
    const res = await request(app.getHttpServer()).get('/health/ready');
    expect(res.status).toBe(200);
    expect(res.body.dependencies).toHaveProperty('db');
    expect(res.body.dependencies).toHaveProperty('redis');
  });

  it('GET /metrics → Prometheus exposition', async () => {
    const res = await request(app.getHttpServer()).get('/metrics');
    expect(res.status).toBe(200);
    expect(res.text).toContain('http_requests_total');
  });
});
