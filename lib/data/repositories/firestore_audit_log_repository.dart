import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/audit_log_repository.dart';

class FirestoreAuditLogRepository implements AuditLogRepository {
  final FirebaseFirestore _firestore;

  FirestoreAuditLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> recordLog({
    required AuditActionType action,
    required String actorUid,
    required String actorName,
    required String targetId,
    required String targetName,
    required String details,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action.code,
      'action_label': action.label,
      'actor_uid': actorUid,
      'actor_name': actorName,
      'target_id': targetId,
      'target_name': targetName,
      'details': details,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AuditLogEntry>> watchLogs({int limit = 100}) {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final ts = data['timestamp'] as Timestamp?;
            return AuditLogEntry(
              id: doc.id,
              action: AuditActionType.fromCode('${data['action'] ?? ''}'),
              actorUid: '${data['actor_uid'] ?? ''}',
              actorName: '${data['actor_name'] ?? 'Sistema'}',
              targetId: '${data['target_id'] ?? ''}',
              targetName: '${data['target_name'] ?? ''}',
              details: '${data['details'] ?? ''}',
              timestamp: ts?.toDate() ?? DateTime.now(),
              metadata: (data['metadata'] as Map<String, dynamic>?) ?? const {},
            );
          }).toList();
        });
  }
}
