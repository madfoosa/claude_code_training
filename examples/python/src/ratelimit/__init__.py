"""A token bucket rate limiter.

This package exists to give the development kit something real to lint,
typecheck, test, break, and fix. It is mirrored feature-for-feature by
``examples/typescript`` -- see the "Both stacks mirror each other" rule in
``CLAUDE.md``.
"""

from ratelimit.bucket import TokenBucket

__all__ = ["TokenBucket"]
