import { LlmClient } from './llm-client';

describe('LlmClient', () => {
  const realFetch = global.fetch;
  afterEach(() => {
    global.fetch = realFetch;
    jest.restoreAllMocks();
  });

  function build(cfg: Record<string, string | undefined>) {
    const config = { get: jest.fn((k: string) => cfg[k]) };
    return new LlmClient(config as never);
  }

  it('is disabled without an API key', () => {
    expect(build({}).enabled).toBe(false);
  });

  it('is enabled with an API key', () => {
    expect(build({ 'ai.apiKey': 'sk' }).enabled).toBe(true);
  });

  it('returns null (never calls out) when disabled', async () => {
    const fetchMock = jest.fn();
    global.fetch = fetchMock as never;
    const res = await build({}).complete({ prompt: 'hi' });
    expect(res).toBeNull();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('parses an Anthropic text response', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ content: [{ type: 'text', text: '  Coached!  ' }] }),
    }) as never;

    const res = await build({
      'ai.apiKey': 'sk',
      'ai.provider': 'anthropic',
      'ai.model': 'claude-sonnet-5',
    }).complete({ prompt: 'improve this' });

    expect(res).toBe('Coached!');
    const [url, init] = (global.fetch as jest.Mock).mock.calls[0];
    expect(url).toContain('anthropic.com');
    expect((init.headers as Record<string, string>)['x-api-key']).toBe('sk');
  });

  it('parses an OpenAI-style response', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ choices: [{ message: { content: 'Nice work' } }] }),
    }) as never;

    const res = await build({
      'ai.apiKey': 'sk',
      'ai.provider': 'openai',
    }).complete({ prompt: 'x' });

    expect(res).toBe('Nice work');
    expect((global.fetch as jest.Mock).mock.calls[0][0]).toContain(
      'openai.com',
    );
  });

  it('returns null on a provider error instead of throwing', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValue({ ok: false, status: 500 }) as never;
    await expect(
      build({ 'ai.apiKey': 'sk' }).complete({ prompt: 'x' }),
    ).resolves.toBeNull();
  });
});
