import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/login_lockout_state.dart';
import '../../domain/repositories/login_security_repository.dart';

class LocalLoginSecurityRepository implements LoginSecurityRepository {
  static const String _attemptsKey = 'ul_login_failed_attempts';
  static const String _lockedUntilKey = 'ul_login_locked_until_ms';

  const LocalLoginSecurityRepository();

  @override
  Future<LoginLockoutState> getState({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockedUntilKey);

    if (lockedUntilMs != null) {
      final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      if (lockedUntil.isAfter(referenceNow)) {
        return LoginLockoutState(
          failedAttempts: LoginLockoutState.maxAttempts,
          lockedUntil: lockedUntil,
        );
      }
      // Bloqueio expirou: limpa contadores locais
      await prefs.remove(_attemptsKey);
      await prefs.remove(_lockedUntilKey);
      return const LoginLockoutState();
    }

    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    return LoginLockoutState(failedAttempts: attempts);
  }

  @override
  Future<LoginLockoutState> registerFailure({DateTime? now}) async {
    final referenceNow = now ?? DateTime.now();
    final current = await getState(now: referenceNow);
    if (current.isLockedAt(referenceNow)) {
      return current;
    }

    final prefs = await SharedPreferences.getInstance();
    final nextAttempts = current.failedAttempts + 1;

    if (nextAttempts >= LoginLockoutState.maxAttempts) {
      final lockedUntil = referenceNow.add(LoginLockoutState.lockoutDuration);
      await prefs.setInt(_attemptsKey, LoginLockoutState.maxAttempts);
      await prefs.setInt(_lockedUntilKey, lockedUntil.millisecondsSinceEpoch);
      return LoginLockoutState(
        failedAttempts: LoginLockoutState.maxAttempts,
        lockedUntil: lockedUntil,
      );
    }

    await prefs.setInt(_attemptsKey, nextAttempts);
    return LoginLockoutState(failedAttempts: nextAttempts);
  }

  @override
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockedUntilKey);
  }
}
