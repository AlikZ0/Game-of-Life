import { QuestCadence } from '@prisma/client';

/**
 * Derives the "period key" that scopes a quest completion, enabling
 * idempotent recurring completions via the unique (questId, periodKey) index.
 *   DAILY   -> 2026-07-25
 *   WEEKLY  -> 2026-W30   (ISO week)
 *   MONTHLY -> 2026-07
 *   ONE_OFF -> once       (a quest can be completed exactly one time)
 */
export function periodKeyFor(
  cadence: QuestCadence,
  at: Date = new Date(),
): string {
  switch (cadence) {
    case 'DAILY':
      return at.toISOString().slice(0, 10);
    case 'WEEKLY':
      return `${at.getUTCFullYear()}-W${String(isoWeek(at)).padStart(2, '0')}`;
    case 'MONTHLY':
      return at.toISOString().slice(0, 7);
    case 'ONE_OFF':
    default:
      return 'once';
  }
}

/** ISO-8601 week number (1..53). */
export function isoWeek(date: Date): number {
  const d = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()),
  );
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
}

/** Local calendar day (YYYY-MM-DD) used for streak accounting. */
export function dayKey(at: Date = new Date()): string {
  return at.toISOString().slice(0, 10);
}
