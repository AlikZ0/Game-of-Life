import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface LlmMessage {
  system?: string;
  prompt: string;
  maxTokens?: number;
}

const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';
const OPENAI_URL = 'https://api.openai.com/v1/chat/completions';
const DEFAULT_TIMEOUT_MS = 12_000;

/**
 * Minimal, dependency-free client for the configured LLM provider (Anthropic by
 * default, OpenAI-compatible as a fallback). It is fully optional: without
 * `AI_API_KEY` the client reports `enabled === false` and callers keep their
 * deterministic behaviour. All network work is time-boxed and defensive so a
 * slow/failing provider can never degrade the request path.
 */
@Injectable()
export class LlmClient {
  private readonly logger = new Logger(LlmClient.name);

  constructor(private readonly config: ConfigService) {}

  /** True when an API key is configured and completions can be requested. */
  get enabled(): boolean {
    return !!this.config.get<string>('ai.apiKey');
  }

  /**
   * Return a single text completion, or `null` on any failure (disabled,
   * timeout, transport or provider error, unexpected shape). Never throws.
   */
  async complete(message: LlmMessage): Promise<string | null> {
    const apiKey = this.config.get<string>('ai.apiKey');
    if (!apiKey) return null;

    const provider = this.config.get<string>('ai.provider') ?? 'anthropic';
    const model = this.config.get<string>('ai.model') ?? 'claude-sonnet-5';
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);

    try {
      return provider === 'openai'
        ? await this.callOpenAi(apiKey, model, message, controller.signal)
        : await this.callAnthropic(apiKey, model, message, controller.signal);
    } catch (err) {
      this.logger.warn(`LLM completion failed (${provider}): ${String(err)}`);
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  private async callAnthropic(
    apiKey: string,
    model: string,
    message: LlmMessage,
    signal: AbortSignal,
  ): Promise<string | null> {
    const res = await fetch(ANTHROPIC_URL, {
      method: 'POST',
      signal,
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': ANTHROPIC_VERSION,
      },
      body: JSON.stringify({
        model,
        max_tokens: message.maxTokens ?? 400,
        system: message.system,
        messages: [{ role: 'user', content: message.prompt }],
      }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = (await res.json()) as {
      content?: Array<{ type: string; text?: string }>;
    };
    const text = json.content?.find((c) => c.type === 'text')?.text;
    return text?.trim() || null;
  }

  private async callOpenAi(
    apiKey: string,
    model: string,
    message: LlmMessage,
    signal: AbortSignal,
  ): Promise<string | null> {
    const res = await fetch(OPENAI_URL, {
      method: 'POST',
      signal,
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        max_tokens: message.maxTokens ?? 400,
        messages: [
          ...(message.system
            ? [{ role: 'system', content: message.system }]
            : []),
          { role: 'user', content: message.prompt },
        ],
      }),
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = (await res.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    return json.choices?.[0]?.message?.content?.trim() || null;
  }
}
