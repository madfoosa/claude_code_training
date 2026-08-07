/**
 * Token bucket rate limiting.
 *
 * The bucket holds up to `capacity` tokens and regains `refillPerSecond` of
 * them per elapsed second. Taking a token costs one unit of budget; when the
 * bucket is empty the request is refused rather than queued.
 *
 * The clock is injected so behaviour is deterministic under test. Production
 * callers should keep the default, which is monotonic and therefore immune to
 * wall-clock adjustments.
 *
 * Mirrors `examples/python/src/ratelimit/bucket.py` feature for feature.
 */

import { performance } from 'node:perf_hooks';

/** Returns monotonically non-decreasing seconds. */
export type Clock = () => number;

/** Monotonic, and therefore immune to wall-clock adjustments. */
const defaultClock: Clock = () => performance.now() / 1000;

/** A token bucket permitting bursts up to `capacity`. */
export class TokenBucket {
  readonly #capacity: number;
  readonly #refillPerSecond: number;
  readonly #clock: Clock;
  #tokens: number;
  #updatedAt: number;

  /**
   * @param capacity Maximum tokens held at once. Also the largest burst allowed.
   * @param refillPerSecond Tokens regained per second of elapsed time.
   * @param clock Injected for tests; defaults to a monotonic source.
   * @throws RangeError If `capacity` or `refillPerSecond` is not positive.
   */
  constructor(capacity: number, refillPerSecond: number, clock: Clock = defaultClock) {
    if (!Number.isInteger(capacity) || capacity <= 0) {
      throw new RangeError(`capacity must be a positive integer, got ${capacity}`);
    }
    if (!(refillPerSecond > 0)) {
      throw new RangeError(`refillPerSecond must be positive, got ${refillPerSecond}`);
    }

    this.#capacity = capacity;
    this.#refillPerSecond = refillPerSecond;
    this.#clock = clock;
    this.#tokens = capacity;
    this.#updatedAt = clock();
  }

  /** The maximum number of tokens the bucket can hold. */
  get capacity(): number {
    return this.#capacity;
  }

  /** The number of whole tokens currently available. */
  available(): number {
    this.#refill();
    return Math.floor(this.#tokens);
  }

  /**
   * Attempt to take `tokens` from the bucket. Never blocks.
   *
   * @returns `true` if the tokens were taken, `false` if the budget is
   *   insufficient right now.
   * @throws RangeError If `tokens` is not positive, or exceeds `capacity` and
   *   so could never succeed no matter how long the caller waits.
   */
  tryAcquire(tokens = 1): boolean {
    if (!Number.isInteger(tokens) || tokens <= 0) {
      throw new RangeError(`tokens must be a positive integer, got ${tokens}`);
    }
    if (tokens > this.#capacity) {
      throw new RangeError(
        `cannot acquire ${tokens} tokens from a bucket of ` +
          `capacity ${this.#capacity}: this can never succeed`,
      );
    }

    this.#refill();
    if (this.#tokens < tokens) {
      return false;
    }

    this.#tokens -= tokens;
    return true;
  }

  /** Credit tokens for time elapsed since the last update. */
  #refill(): void {
    const now = this.#clock();
    const elapsed = now - this.#updatedAt;

    // A non-monotonic clock can step backwards. Credit nothing rather than
    // debiting the caller for someone else's NTP correction.
    if (elapsed <= 0) {
      return;
    }

    this.#updatedAt = now;
    this.#tokens = Math.min(
      this.#capacity,
      this.#tokens + elapsed * this.#refillPerSecond,
    );
  }
}
