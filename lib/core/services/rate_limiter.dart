// lib/core/services/rate_limiter.dart
// In-memory rate limiter — resets on app restart (intentional for client-side)
// For server-side enforcement, use Firestore security rules.

import 'package:flutter/foundation.dart';

class RateLimiter {
  RateLimiter._();
  static final RateLimiter instance = RateLimiter._();

  // Stores: key -> list of attempt timestamps
  final Map<String, List<DateTime>> _attempts = {};
  // Stores: key -> blocked until DateTime
  final Map<String, DateTime> _blockedUntil = {};

  /// Returns null if allowed, or a human-readable error string if blocked.
  /// [key] — unique identifier (e.g. 'login:user@email.com')
  /// [maxAttempts] — max allowed in [window]
  /// [window] — time window
  /// [blockDuration] — how long to block after exceeding
  String? check(
    String key, {
    required int maxAttempts,
    required Duration window,
    required Duration blockDuration,
  }) {
    final now = DateTime.now();

    // Check if currently blocked
    final blockedUntil = _blockedUntil[key];
    if (blockedUntil != null && now.isBefore(blockedUntil)) {
      final remaining = blockedUntil.difference(now);
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      if (mins > 0) {
        return 'Too many attempts. Try again in ${mins}m ${secs}s.';
      }
      return 'Too many attempts. Try again in ${secs}s.';
    }

    // Clean old attempts outside window
    _attempts[key] = (_attempts[key] ?? [])
        .where((t) => now.difference(t) < window)
        .toList();

    // Record this attempt
    _attempts[key]!.add(now);

    // Check if over limit
    if (_attempts[key]!.length > maxAttempts) {
      _blockedUntil[key] = now.add(blockDuration);
      _attempts.remove(key);
      debugPrint('RateLimiter: $key blocked for ${blockDuration.inMinutes}m');
      final mins = blockDuration.inMinutes;
      return 'Too many attempts. Try again in ${mins > 0 ? '${mins}m' : '${blockDuration.inSeconds}s'}.';
    }

    return null; // allowed
  }

  /// Clears all attempts for a key (call on successful auth).
  void reset(String key) {
    _attempts.remove(key);
    _blockedUntil.remove(key);
  }

  /// Returns true if currently blocked.
  bool isBlocked(String key) {
    final blockedUntil = _blockedUntil[key];
    return blockedUntil != null && DateTime.now().isBefore(blockedUntil);
  }
}
