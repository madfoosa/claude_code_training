/**
 * Tests for the token bucket.
 *
 * These double as the worked example for the testing pillar
 * (`docs/strategy/04-testing.md`): every test names the behaviour it pins down,
 * and the clock is driven by hand so nothing depends on wall time.
 *
 * Mirrors `examples/python/tests/test_bucket.py` case for case.
 */

import { describe, expect, it } from 'vitest';

import { TokenBucket } from '../src/index.js';

/** A hand-driven monotonic clock. */
class FakeClock {
  now: number;

  constructor(start = 0) {
    this.now = start;
  }

  readonly tick = (): number => this.now;

  advance(seconds: number): void {
    this.now += seconds;
  }
}

function makeBucket(
  capacity = 10,
  refillPerSecond = 1,
): { bucket: TokenBucket; clock: FakeClock } {
  const clock = new FakeClock();
  return { bucket: new TokenBucket(capacity, refillPerSecond, clock.tick), clock };
}

describe('construction', () => {
  it('starts full', () => {
    const { bucket } = makeBucket(5);
    expect(bucket.available()).toBe(5);
  });

  it('exposes capacity', () => {
    const { bucket } = makeBucket(5);
    expect(bucket.capacity).toBe(5);
  });

  it.each([0, -1, 1.5])('rejects a capacity of %s', (capacity) => {
    expect(() => new TokenBucket(capacity, 1)).toThrow(
      /capacity must be a positive integer/,
    );
  });

  it.each([0, -1])('rejects a refill rate of %s', (rate) => {
    expect(() => new TokenBucket(10, rate)).toThrow(/refillPerSecond must be positive/);
  });
});

describe('acquire', () => {
  it('allows a burst up to capacity', () => {
    const { bucket } = makeBucket(3);
    expect([bucket.tryAcquire(), bucket.tryAcquire(), bucket.tryAcquire()]).toEqual([
      true,
      true,
      true,
    ]);
  });

  it('refuses once empty', () => {
    const { bucket } = makeBucket(1);
    expect(bucket.tryAcquire()).toBe(true);
    expect(bucket.tryAcquire()).toBe(false);
  });

  it('takes multiple tokens at once', () => {
    const { bucket } = makeBucket(10);
    expect(bucket.tryAcquire(4)).toBe(true);
    expect(bucket.available()).toBe(6);
  });

  it('refuses rather than partially granting', () => {
    const { bucket } = makeBucket(10);
    bucket.tryAcquire(8);
    expect(bucket.tryAcquire(5)).toBe(false);
    // The failed attempt must not have consumed anything.
    expect(bucket.available()).toBe(2);
  });

  it.each([0, -1, 1.5])('rejects a token count of %s', (tokens) => {
    const { bucket } = makeBucket();
    expect(() => bucket.tryAcquire(tokens)).toThrow(
      /tokens must be a positive integer/,
    );
  });

  it('rejects a request larger than capacity', () => {
    // An unsatisfiable request is a bug, not a rate limit decision. Returning
    // false would invite the caller into an infinite retry loop.
    const { bucket } = makeBucket(5);
    expect(() => bucket.tryAcquire(6)).toThrow(/can never succeed/);
  });
});

describe('refill', () => {
  it('refills over time', () => {
    const { bucket, clock } = makeBucket(10, 2);
    bucket.tryAcquire(10);
    expect(bucket.available()).toBe(0);

    clock.advance(3);
    expect(bucket.available()).toBe(6);
  });

  it('holds fractional credit rather than rounding it away', () => {
    const { bucket, clock } = makeBucket(10, 1);
    bucket.tryAcquire(10);

    clock.advance(0.5);
    expect(bucket.available()).toBe(0);
    expect(bucket.tryAcquire()).toBe(false);

    clock.advance(0.5);
    expect(bucket.available()).toBe(1);
    expect(bucket.tryAcquire()).toBe(true);
  });

  it('does not refill past capacity', () => {
    const { bucket, clock } = makeBucket(10, 1);
    bucket.tryAcquire(5);

    clock.advance(1000);
    expect(bucket.available()).toBe(10);
  });

  it('ignores a backwards clock', () => {
    const { bucket, clock } = makeBucket(10, 1);
    bucket.tryAcquire(5);
    expect(bucket.available()).toBe(5);

    clock.advance(-100);
    expect(bucket.available()).toBe(5);
  });

  it('sustains throughput at the configured rate', () => {
    const { bucket, clock } = makeBucket(5, 1);
    while (bucket.tryAcquire()) {
      /* drain */
    }

    let granted = 0;
    for (let i = 0; i < 100; i += 1) {
      clock.advance(1);
      if (bucket.tryAcquire()) {
        granted += 1;
      }
    }

    expect(granted).toBe(100);
  });
});
