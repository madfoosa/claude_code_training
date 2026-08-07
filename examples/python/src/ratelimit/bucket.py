"""Token bucket rate limiting.

The bucket holds up to ``capacity`` tokens and regains ``refill_per_second`` of
them per elapsed second. Taking a token costs one unit of budget; when the
bucket is empty the request is refused rather than queued.

The clock is injected so behaviour is deterministic under test. Production
callers should keep the default, which is monotonic and therefore immune to
wall-clock adjustments.
"""

from __future__ import annotations

import time
from collections.abc import Callable

__all__ = ["TokenBucket"]


class TokenBucket:
    """A token bucket permitting bursts up to ``capacity``.

    Args:
        capacity: Maximum tokens held at once. Also the largest burst allowed.
        refill_per_second: Tokens regained per second of elapsed time.
        clock: Returns monotonically non-decreasing seconds. Injected for tests.

    Raises:
        ValueError: If ``capacity`` or ``refill_per_second`` is not positive.
    """

    def __init__(
        self,
        capacity: int,
        refill_per_second: float,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if capacity <= 0:
            raise ValueError(f"capacity must be positive, got {capacity}")
        if refill_per_second <= 0:
            raise ValueError(
                f"refill_per_second must be positive, got {refill_per_second}"
            )

        self._capacity = capacity
        self._refill_per_second = refill_per_second
        self._clock = clock
        self._tokens = float(capacity)
        self._updated_at = clock()

    @property
    def capacity(self) -> int:
        """The maximum number of tokens the bucket can hold."""
        return self._capacity

    def available(self) -> int:
        """Return the number of whole tokens currently available."""
        self._refill()
        return int(self._tokens)

    def try_acquire(self, tokens: int = 1) -> bool:
        """Attempt to take ``tokens`` from the bucket.

        Returns:
            ``True`` if the tokens were taken, ``False`` if the budget is
            insufficient right now. Never blocks.

        Raises:
            ValueError: If ``tokens`` is not positive, or exceeds ``capacity``
                and so could never succeed no matter how long the caller waits.
        """
        if tokens <= 0:
            raise ValueError(f"tokens must be positive, got {tokens}")
        if tokens > self._capacity:
            raise ValueError(
                f"cannot acquire {tokens} tokens from a bucket of "
                f"capacity {self._capacity}: this can never succeed"
            )

        self._refill()
        if self._tokens < tokens:
            return False

        self._tokens -= tokens
        return True

    def _refill(self) -> None:
        """Credit tokens for time elapsed since the last update."""
        now = self._clock()
        elapsed = now - self._updated_at

        # A non-monotonic clock can step backwards. Credit nothing rather than
        # debiting the caller for someone else's NTP correction.
        if elapsed <= 0:
            return

        self._updated_at = now
        self._tokens = min(
            float(self._capacity),
            self._tokens + elapsed * self._refill_per_second,
        )
