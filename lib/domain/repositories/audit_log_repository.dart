import '../entities/audit_log.dart';

abstract class AuditLogRepository {
  Future<void> recordLog({
    required AuditActionType action,
    required String actorUid,
    required String actorName,
    required String targetId,
    required String targetName,
    required String details,
    Map<String, dynamic> metadata = const {},
  });

  Stream<List<AuditLogEntry>> watchLogs({int limit = 100});
}
