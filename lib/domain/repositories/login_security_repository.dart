import '../entities/login_lockout_state.dart';

abstract class LoginSecurityRepository {
  Future<LoginLockoutState> getState({DateTime? now});
  Future<LoginLockoutState> registerFailure({DateTime? now});
  Future<void> reset();
}
