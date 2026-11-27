class LoginLockoutState {
  final int failedAttempts;
  final DateTime? lockedUntil;

  const LoginLockoutState({
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 5);

  bool isLockedAt(DateTime now) {
    return lockedUntil != null && lockedUntil!.isAfter(now);
  }

  Duration remainingAt(DateTime now) {
    if (!isLockedAt(now)) return Duration.zero;
    return lockedUntil!.difference(now);
  }

  int get remainingAttemptsBeforeLock =>
      (maxAttempts - failedAttempts).clamp(0, maxAttempts);
}
