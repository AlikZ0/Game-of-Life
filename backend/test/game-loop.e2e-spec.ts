import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';

/**
 * End-to-end coverage of the core gameplay loop against a real Postgres + Redis:
 *   register → create character → create quest → complete (rewards, skill XP,
 *   streak) → idempotent re-complete (409) → stats reflect progress →
 *   boss takes damage and, at 0 HP, is defeated and grants its reward.
 *
 * Mirrors the production wiring from main.ts (global prefix, validation,
 * response envelope, error filter) so assertions match real API behaviour.
 */
describe('Game loop (e2e)', () => {
  let app: INestApplication;
  let http: ReturnType<INestApplication['getHttpServer']>;

  const api = '/api/v1';
  const email = `hero_${Date.now()}@lifequest.app`;
  let token: string;
  let questId: string;
  let bossId: string;
  let bossQuestId: string;

  const auth = () => ({ Authorization: `Bearer ${token}` });

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

  it('registers a new user without a character', async () => {
    const res = await request(http)
      .post(`${api}/auth/register`)
      .send({ email, password: 'Str0ng-Passw0rd!' });

    expect(res.status).toBe(201);
    expect(res.body.data.accessToken).toEqual(expect.any(String));
    expect(res.body.data.hasCharacter).toBe(false);
    token = res.body.data.accessToken;
  });

  it('creates a level-1 character with seeded skills', async () => {
    const res = await request(http)
      .post(`${api}/characters`)
      .set(auth())
      .send({ name: 'Aria', characterClass: 'MAGE' });

    expect(res.status).toBe(201);
    expect(res.body.data).toMatchObject({ level: 1, xp: 0, gold: 0 });

    const skills = await request(http).get(`${api}/skills`).set(auth());
    expect(skills.status).toBe(200);
    expect(skills.body.data.map((s: { key: string }) => s.key)).toContain(
      'programming',
    );
  });

  it('creates a daily quest', async () => {
    const res = await request(http)
      .post(`${api}/quests`)
      .set(auth())
      .send({
        title: 'Code for 45 minutes',
        cadence: 'DAILY',
        difficulty: 'HARD',
        skillKey: 'programming',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.completedThisPeriod).toBe(false);
    questId = res.body.data.id;
  });

  it('completes the quest and awards scaled XP, gold and a streak', async () => {
    const res = await request(http)
      .post(`${api}/quests/${questId}/complete`)
      .set(auth());

    expect(res.status).toBe(201);
    const body = res.body.data;
    // HARD scales the base 20 XP / 10 gold up (>= base).
    expect(body.xpAwarded).toBeGreaterThanOrEqual(20);
    expect(body.goldAwarded).toBeGreaterThanOrEqual(10);
    expect(body.newLevel).toBe(1);
    expect(body.streak).toBe(1);
  });

  it('rejects a second completion in the same period (idempotency)', async () => {
    const res = await request(http)
      .post(`${api}/quests/${questId}/complete`)
      .set(auth());

    expect(res.status).toBe(409);
    expect(res.body.statusCode).toBe(409);
  });

  it('reflects the completion in character, skill and stats', async () => {
    const me = await request(http).get(`${api}/characters/me`).set(auth());
    expect(me.body.data.xp).toBeGreaterThan(0);
    expect(me.body.data.gold).toBeGreaterThan(0);

    const skills = await request(http).get(`${api}/skills`).set(auth());
    const programming = skills.body.data.find(
      (s: { key: string }) => s.key === 'programming',
    );
    expect(programming.xp).toBeGreaterThan(0);

    const dash = await request(http)
      .get(`${api}/stats/dashboard`)
      .set(auth());
    expect(dash.body.data.questsCompleted30d).toBe(1);
    expect(dash.body.data.currentStreak).toBe(1);
  });

  it('defeats a boss when linked quest damage drains its HP', async () => {
    const boss = await request(http)
      .post(`${api}/bosses`)
      .set(auth())
      .send({ name: 'Ship v1', maxHp: 10, rewardXp: 500, rewardGold: 250 });
    expect(boss.status).toBe(201);
    bossId = boss.body.data.id;

    const quest = await request(http)
      .post(`${api}/quests`)
      .set(auth())
      .send({ title: 'Final push', cadence: 'DAILY', difficulty: 'MEDIUM', bossId });
    bossQuestId = quest.body.data.id;

    const res = await request(http)
      .post(`${api}/quests/${bossQuestId}/complete`)
      .set(auth());

    expect(res.status).toBe(201);
    expect(res.body.data.bossDamage).toBeGreaterThan(0);
    expect(res.body.data.bossDefeated).toBe(true);

    const view = await request(http)
      .get(`${api}/bosses/${bossId}`)
      .set(auth());
    expect(view.body.data.status).toBe('DEFEATED');
    expect(view.body.data.currentHp).toBe(0);
  });
});
