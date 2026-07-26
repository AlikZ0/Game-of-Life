import { FcmSender } from './fcm-sender';

describe('FcmSender', () => {
  function build(projectId?: string) {
    const config = {
      get: jest.fn((k: string) =>
        k === 'firebase.projectId' ? projectId : undefined,
      ),
    };
    return new FcmSender(config as never);
  }

  it('reports disabled without a project id', () => {
    expect(build(undefined).enabled).toBe(false);
  });

  it('reports enabled when a project id is configured', () => {
    expect(build('lifequest-prod').enabled).toBe(true);
  });

  it('returns no dead tokens for an empty token list', async () => {
    await expect(
      build('p').sendMulticast([], { title: 't', body: 'b' }),
    ).resolves.toEqual([]);
  });

  it('is a no-op (empty result) when Firebase is unavailable', async () => {
    // Not configured → resolve() returns null → nothing sent, nothing to prune.
    const dead = await build(undefined).sendMulticast(['t1'], {
      title: 't',
      body: 'b',
    });
    expect(dead).toEqual([]);
  });
});
