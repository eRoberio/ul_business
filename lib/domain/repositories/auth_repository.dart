import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<String?> authStateUidChanges();
  String? get currentUid;
  String? get currentDisplayName;
  String? get currentEmail;
  String? get currentPhotoUrl;

  Future<void> ensureSessionPersistence();
  Stream<AppUser?> watchUserProfile(String uid);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();
  Future<void> signOut();
}
