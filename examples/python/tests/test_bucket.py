"""Tests for the token bucket.

These double as the worked example for the testing pillar
(``docs/strategy/04-testing.md``): every test names the behaviour it pins down,
and the clock is driven by hand so nothing depends on wall time.
"""

from __future__ import annotations

import pytest

from ratelimit import TokenBucket


class FakeClock:
    """A hand-driven monotonic clock."""

    def __init__(self, start: float = 0.0) -> None:
        self.now = start

    def __call__(self) -> float:
        return self.now

    def advance(self, seconds: float) -> None:
        self.now += seconds


def make_bucket(
    capacity: int = 10,
    refill_per_second: float = 1.0,
) -> tuple[TokenBucket, FakeClock]:
    clock = FakeClock()
    return TokenBucket(capacity, refill_per_second, clock), clock


class TestConstruction:
    def test_starts_full(self) -> None:
        bucket, _ = make_bucket(capacity=5)
        assert bucket.available() == 5

    def test_exposes_capacity(self) -> None:
        bucket, _ = make_bucket(capacity=5)
        assert bucket.capacity == 5

    @pytest.mark.parametrize("capacity", [0, -1])
    def test_rejects_non_positive_capacity(self, capacity: int) -> None:
        with pytest.raises(ValueError, match="capacity must be positive"):
            TokenBucket(capacity, 1.0)

    @pytest.mark.parametrize("rate", [0.0, -1.0])
    def test_rejects_non_positive_refill_rate(self, rate: float) -> None:
        with pytest.raises(ValueError, match="refill_per_second must be positive"):
            TokenBucket(10, rate)


class TestAcquire:
    def test_allows_burst_up_to_capacity(self) -> None:
        bucket, _ = make_bucket(capacity=3)
        assert all(bucket.try_acquire() for _ in range(3))

    def test_refuses_once_empty(self) -> None:
        bucket, _ = make_bucket(capacity=1)
        assert bucket.try_acquire() is True
        assert bucket.try_acquire() is False

    def test_multi_token_acquire(self) -> None:
        bucket, _ = make_bucket(capacity=10)
        assert bucket.try_acquire(4) is True
        assert bucket.available() == 6

    def test_partial_budget_refuses_rather_than_partially_granting(self) -> None:
        bucket, _ = make_bucket(capacity=10)
        bucket.try_acquire(8)
        assert bucket.try_acquire(5) is False
        # The failed attempt must not have consumed anything.
        assert bucket.available() == 2

    @pytest.mark.parametrize("tokens", [0, -1])
    def test_rejects_non_positive_token_count(self, tokens: int) -> None:
        bucket, _ = make_bucket()
        with pytest.raises(ValueError, match="tokens must be positive"):
            bucket.try_acquire(tokens)

    def test_rejects_request_larger_than_capacity(self) -> None:
        """An unsatisfiable request is a bug, not a rate limit decision.

        Returning False would invite the caller into an infinite retry loop, so
        this raises instead.
        """
        bucket, _ = make_bucket(capacity=5)
        with pytest.raises(ValueError, match="can never succeed"):
            bucket.try_acquire(6)


class TestRefill:
    def test_refills_over_time(self) -> None:
        bucket, clock = make_bucket(capacity=10, refill_per_second=2.0)
        bucket.try_acquire(10)
        assert bucket.available() == 0

        clock.advance(3.0)
        assert bucket.available() == 6

    def test_refill_is_fractional(self) -> None:
        """Half a token of credit is held, not rounded away."""
        bucket, clock = make_bucket(capacity=10, refill_per_second=1.0)
        bucket.try_acquire(10)

        clock.advance(0.5)
        assert bucket.available() == 0
        assert bucket.try_acquire() is False

        clock.advance(0.5)
        assert bucket.available() == 1
        assert bucket.try_acquire() is True

    def test_does_not_refill_past_capacity(self) -> None:
        bucket, clock = make_bucket(capacity=10, refill_per_second=1.0)
        bucket.try_acquire(5)

        clock.advance(1_000.0)
        assert bucket.available() == 10

    def test_ignores_backwards_clock(self) -> None:
        """A clock that steps backwards must not debit the caller."""
        bucket, clock = make_bucket(capacity=10, refill_per_second=1.0)
        bucket.try_acquire(5)
        assert bucket.available() == 5

        clock.advance(-100.0)
        assert bucket.available() == 5

    def test_sustained_rate_matches_refill_rate(self) -> None:
        """Over a long window, throughput converges on the configured rate."""
        bucket, clock = make_bucket(capacity=5, refill_per_second=1.0)
        while bucket.try_acquire():
            pass

        granted = 0
        for _ in range(100):
            clock.advance(1.0)
            if bucket.try_acquire():
                granted += 1

        assert granted == 100
