import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';

/**
 * End-to-end coverage of the social layer (guilds + PvP) against a real
 * Postgres + Redis, using two registered players.
 */
describe('Social (e2e)', () => {
  let app: INestApplication;
  let http: ReturnType<INestApplication['getHttpServer']>;
  const api = '/api/v1';
  const stamp = Date.now();

  let u1: { token: string; characterId: string };
  let u2: { token: string; characterId: string };
  let guildId: string;
  let challengeId: string;

  const bearer = (t: string) => ({ Authorization: `Bearer ${t}` });

  async function register(
    email: string,
    name: string,
  ): Promise<{ token: string; characterId: string }> {
    const reg = await request(http)
      .post(`${api}/auth/register`)
      .send({ email, password: 'Str0ng-Passw0rd!' });
    const token = reg.body.data.accessToken;
    const char = await request(http)
      .post(`${api}/characters`)
      .set(bearer(token))
      .send({ name, characterClass: 'WARRIOR' });
    return { token, characterId: char.body.data.id };
  }

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

    u1 = await register(`guild_a_${stamp}@lifequest.app`, 'Guildmaster');
    u2 = await register(`guild_b_${stamp}@lifequest.app`, 'Rival');
  });

  afterAll(async () => {
    await app.close();
  });

  // ── Guilds ──────────────────────────────────────────────
  it('creates a guild with the creator as leader', async () => {
    const res = await request(http)
      .post(`${api}/guilds`)
      .set(bearer(u1.token))
      .send({ name: `Dawn Raiders ${stamp}`, tag: `D${stamp % 10000}` });
    expect(res.status).toBe(201);
    expect(res.body.data.id).toEqual(expect.any(String));
    guildId = res.body.data.id;
  });

  it('lets a second player join, and lists both members', async () => {
    const join = await request(http)
      .post(`${api}/guilds/${guildId}/join`)
      .set(bearer(u2.token));
    expect(join.status).toBe(201);

    const view = await request(http)
      .get(`${api}/guilds/${guildId}`)
      .set(bearer(u1.token));
    expect(view.body.data.members).toHaveLength(2);
  });

  it('enforces one guild per character', async () => {
    const res = await request(http)
      .post(`${api}/guilds`)
      .set(bearer(u2.token))
      .send({ name: `Second Guild ${stamp}`, tag: 'SEC' });
    expect(res.status).toBe(400);
  });

  it('broadcasts + lists chat messages', async () => {
    const post = await request(http)
      .post(`${api}/guilds/${guildId}/messages`)
      .set(bearer(u1.token))
      .send({ body: 'Welcome to the guild!' });
    expect(post.status).toBe(201);

    const list = await request(http)
      .get(`${api}/guilds/${guildId}/messages`)
      .set(bearer(u2.token));
    expect(list.body.data.map((m: { body: string }) => m.body)).toContain(
      'Welcome to the guild!',
    );
  });

  it('allows only the leader to create missions', async () => {
    const asMember = await request(http)
      .post(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u2.token))
      .send({ title: 'Grind 10k XP', targetValue: 10000 });
    expect(asMember.status).toBe(403);

    const asLeader = await request(http)
      .post(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u1.token))
      .send({ title: 'Grind 10k XP', targetValue: 10000 });
    expect(asLeader.status).toBe(201);
  });

  it('reflects quest XP on the weekly leaderboard', async () => {
    const quest = await request(http)
      .post(`${api}/quests`)
      .set(bearer(u2.token))
      .send({ title: 'Guild grind', cadence: 'DAILY', difficulty: 'MEDIUM' });
    await request(http)
      .post(`${api}/quests/${quest.body.data.id}/complete`)
      .set(bearer(u2.token));

    const board = await request(http)
      .get(`${api}/guilds/${guildId}/leaderboard`)
      .set(bearer(u1.token));
    const rival = board.body.data.find(
      (m: { characterId: string }) => m.characterId === u2.characterId,
    );
    expect(rival.weeklyXp).toBeGreaterThan(0);
  });

  it('auto-progresses and completes a guild mission from activity', async () => {
    const mission = await request(http)
      .post(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u1.token))
      .send({ title: 'First XP', targetValue: 1 });
    const missionId = mission.body.data.id;

    const quest = await request(http)
      .post(`${api}/quests`)
      .set(bearer(u1.token))
      .send({ title: 'Mission fuel', cadence: 'DAILY', difficulty: 'HARD' });
    await request(http)
      .post(`${api}/quests/${quest.body.data.id}/complete`)
      .set(bearer(u1.token));

    const missions = await request(http)
      .get(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u1.token));
    const done = missions.body.data.find(
      (m: { id: string }) => m.id === missionId,
    );
    expect(done.currentValue).toBeGreaterThan(0);
    expect(done.completedAt).not.toBeNull();
  });

  it('auto-progresses a non-XP (quests-completed) guild mission', async () => {
    const mission = await request(http)
      .post(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u1.token))
      .send({
        title: 'Complete a quest together',
        targetValue: 1,
        metric: 'QUESTS_COMPLETED',
      });
    expect(mission.status).toBe(201);
    const missionId = mission.body.data.id;

    const quest = await request(http)
      .post(`${api}/quests`)
      .set(bearer(u1.token))
      .send({ title: 'Any quest', cadence: 'DAILY', difficulty: 'EASY' });
    await request(http)
      .post(`${api}/quests/${quest.body.data.id}/complete`)
      .set(bearer(u1.token));

    const missions = await request(http)
      .get(`${api}/guilds/${guildId}/missions`)
      .set(bearer(u1.token));
    const done = missions.body.data.find(
      (m: { id: string }) => m.id === missionId,
    );
    expect(done.currentValue).toBeGreaterThanOrEqual(1);
    expect(done.completedAt).not.toBeNull();
  });

  it('lets a member leave the guild', async () => {
    const leave = await request(http)
      .post(`${api}/guilds/${guildId}/leave`)
      .set(bearer(u2.token));
    expect(leave.status).toBe(201);

    const view = await request(http)
      .get(`${api}/guilds/${guildId}`)
      .set(bearer(u1.token));
    expect(view.body.data.members).toHaveLength(1);
  });

  // ── PvP ─────────────────────────────────────────────────
  it('creates a pending PvP challenge', async () => {
    const res = await request(http)
      .post(`${api}/pvp`)
      .set(bearer(u1.token))
      .send({ opponentId: u2.characterId, metric: 'XP' });
    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe('PENDING');
    challengeId = res.body.data.id;
  });

  it('lists the challenge for the challenger', async () => {
    const res = await request(http).get(`${api}/pvp`).set(bearer(u1.token));
    expect(res.body.data.map((c: { id: string }) => c.id)).toContain(
      challengeId,
    );
  });

  it('lets the opponent accept, moving it to ACTIVE', async () => {
    const accept = await request(http)
      .post(`${api}/pvp/${challengeId}/accept`)
      .set(bearer(u2.token));
    expect(accept.status).toBe(201);
    expect(accept.body.data.status).toBe('ACTIVE');

    const standings = await request(http)
      .get(`${api}/pvp/${challengeId}/standings`)
      .set(bearer(u1.token));
    expect(standings.body.data).toMatchObject({
      status: 'ACTIVE',
      challengerScore: expect.any(Number),
      opponentScore: expect.any(Number),
    });
  });

  it('scores the challenger when they complete a quest (XP metric)', async () => {
    const quest = await request(http)
      .post(`${api}/quests`)
      .set(bearer(u1.token))
      .send({ title: 'Duel grind', cadence: 'DAILY', difficulty: 'HARD' });
    await request(http)
      .post(`${api}/quests/${quest.body.data.id}/complete`)
      .set(bearer(u1.token));

    const standings = await request(http)
      .get(`${api}/pvp/${challengeId}/standings`)
      .set(bearer(u1.token));
    expect(standings.body.data.challengerScore).toBeGreaterThan(0);
  });
});
