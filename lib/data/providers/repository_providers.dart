import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/crm_repository.dart';
import '../../domain/repositories/login_security_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../repositories/firestore_audit_log_repository.dart';
import '../repositories/firestore_crm_repository.dart';
import '../repositories/local_login_security_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => FirestoreAuditLogRepository(),
);

final crmRepositoryProvider = Provider<CrmRepository>(
  (ref) => FirestoreCrmRepository(
    auditLogRepository: ref.watch(auditLogRepositoryProvider),
  ),
);

final loginSecurityRepositoryProvider = Provider<LoginSecurityRepository>(
  (ref) => const LocalLoginSecurityRepository(),
);

final authUidStreamProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateUidChanges();
});

final currentUserProfileProvider = StreamProvider.family<AppUser?, String>((
  ref,
  uid,
) {
  return ref.watch(authRepositoryProvider).watchUserProfile(uid);
});
