import { LockService } from './lock.service';

describe('LockService', () => {
  function build(setResult: 'OK' | null, status = 'ready') {
    const redis = {
      status,
      connect: jest.fn().mockResolvedValue(undefined),
      set: jest.fn().mockResolvedValue(setResult),
      eval: jest.fn().mockResolvedValue(1),
    };
    return { service: new LockService(redis as never), redis };
  }

  it('acquires the lock with SET NX PX and returns a token', async () => {
    const { service, redis } = build('OK');
    const token = await service.acquire('job', 1000);
    expect(token).toEqual(expect.any(String));
    expect(redis.set).toHaveBeenCalledWith('lock:job', token, 'PX', 1000, 'NX');
  });

  it('returns null when the lock is already held', async () => {
    const { service } = build(null);
    await expect(service.acquire('job', 1000)).resolves.toBeNull();
  });

  it('connects first when Redis is not ready', async () => {
    const { service, redis } = build('OK', 'wait');
    await service.acquire('job', 1000);
    expect(redis.connect).toHaveBeenCalled();
  });

  it('runs fn and releases when the lock is won', async () => {
    const { service, redis } = build('OK');
    const fn = jest.fn().mockResolvedValue('done');
    const result = await service.withLock('job', 1000, fn);
    expect(result).toBe('done');
    expect(fn).toHaveBeenCalled();
    // release runs the compare-and-delete Lua script against our key
    expect(redis.eval).toHaveBeenCalledWith(
      expect.stringContaining('redis.call("del"'),
      1,
      'lock:job',
      expect.any(String),
    );
  });

  it('skips fn when the lock is not won', async () => {
    const { service } = build(null);
    const fn = jest.fn();
    const result = await service.withLock('job', 1000, fn);
    expect(result).toBeNull();
    expect(fn).not.toHaveBeenCalled();
  });

  it('treats a Redis error as "lock not acquired"', async () => {
    const redis = {
      status: 'ready',
      connect: jest.fn(),
      set: jest.fn().mockRejectedValue(new Error('down')),
      eval: jest.fn(),
    };
    const service = new LockService(redis as never);
    await expect(service.acquire('job', 1000)).resolves.toBeNull();
  });
});
