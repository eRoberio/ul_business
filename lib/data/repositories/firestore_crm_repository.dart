import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/entities/schedule_validator.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/crm_repository.dart';

class FirestoreCrmRepository implements CrmRepository {
  final FirebaseFirestore _firestore;
  final AuditLogRepository _auditLogRepository;

  FirestoreCrmRepository({
    FirebaseFirestore? firestore,
    required AuditLogRepository auditLogRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditLogRepository = auditLogRepository;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('interacoes');

  @override
  Stream<List<Map<String, dynamic>>> watchInteractions() {
    return _collection
        .orderBy('data_registro', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'doc_id': doc.id})
              .toList(),
        );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchScheduledInteractions() {
    return _collection
        .where('status', isEqualTo: 'Agendada')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'doc_id': doc.id})
              .toList(),
        );
  }

  @override
  Future<String> saveInteraction({
    String? existingId,
    required Map<String, dynamic> payload,
    required String actorUid,
    required String actorName,
    String? previousStatus,
  }) async {
    final status = '${payload['status'] ?? 'Em Prospecção'}';
    final empresaNome = '${payload['empresa_nome'] ?? 'Cliente'}';

    if (status == 'Agendada') {
      final dataEventoTs = payload['data_evento'] as Timestamp?;
      if (dataEventoTs == null) {
        throw const ScheduleValidationException(
          'Selecione a data e o horário para agendar o evento.',
        );
      }
      final start = dataEventoTs.toDate();
      final duration = (payload['duracao_minutos'] as num?)?.toInt() ?? 60;

      final scheduledSnap = await _collection
          .where('status', isEqualTo: 'Agendada')
          .get();

      final existingSlots = scheduledSnap.docs
          .map((doc) {
            final d = doc.data();
            final ts = d['data_evento'] as Timestamp?;
            if (ts == null) return null;
            return ScheduledSlot(
              id: doc.id,
              empresaNome: '${d['empresa_nome'] ?? 'outro compromisso'}',
              start: ts.toDate(),
              durationMinutes: (d['duracao_minutos'] as num?)?.toInt() ?? 60,
            );
          })
          .whereType<ScheduledSlot>()
          .toList();

      ScheduleValidator.validateSlot(
        start: start,
        durationMinutes: duration,
        existingSlots: existingSlots,
        currentInteractionId: existingId,
      );
    }

    final String savedId;
    if (existingId == null) {
      final ref = await _collection.add(payload);
      savedId = ref.id;
    } else {
      await _collection.doc(existingId).update(payload);
      savedId = existingId;
    }

    final AuditActionType action;
    final String details;
    if (status == 'Agendada' && previousStatus != 'Agendada') {
      action = AuditActionType.eventScheduled;
      details = 'Palestra agendada para $empresaNome.';
    } else if (existingId == null) {
      action = AuditActionType.cardCreated;
      details = 'Card criado em "$status" para $empresaNome.';
    } else {
      action = AuditActionType.cardUpdated;
      details = 'Card atualizado em "$status" para $empresaNome.';
    }

    await _auditLogRepository.recordLog(
      action: action,
      actorUid: actorUid,
      actorName: actorName,
      targetId: savedId,
      targetName: empresaNome,
      details: details,
      metadata: {'status': status},
    );

    return savedId;
  }

  @override
  Future<void> moveStatus({
    required Map<String, dynamic> item,
    required String newStatus,
    required String newStatusFullName,
    required String actorUid,
    required String actorName,
  }) async {
    final docId = item['doc_id'] as String?;
    if (docId == null) return;

    final previousStatus = '${item['status'] ?? 'Em Prospecção'}';
    final empresaNome = '${item['empresa_nome'] ?? 'Cliente'}';
    final tags = List<String>.from(item['tags'] ?? []);
    final novaTag = '${newStatus}_${DateTime.now().millisecondsSinceEpoch}';
    if (!tags.contains(novaTag)) {
      tags.add(novaTag);
    }

    await _collection.doc(docId).update({
      'status': newStatus,
      'tags': tags,
      'ultimo_status_nome': newStatusFullName,
    });

    await _auditLogRepository.recordLog(
      action: AuditActionType.cardMoved,
      actorUid: actorUid,
      actorName: actorName,
      targetId: docId,
      targetName: empresaNome,
      details: 'Card movido de "$previousStatus" para "$newStatus".',
      metadata: {'from': previousStatus, 'to': newStatus},
    );
  }

  @override
  Future<void> removeTag({
    required String docId,
    required List<String> updatedTags,
  }) async {
    await _collection.doc(docId).update({'tags': updatedTags});
  }

  @override
  Future<void> deleteInteraction({
    required String docId,
    required String empresaNome,
    required String actorUid,
    required String actorName,
  }) async {
    await _collection.doc(docId).delete();
    await _auditLogRepository.recordLog(
      action: AuditActionType.cardDeleted,
      actorUid: actorUid,
      actorName: actorName,
      targetId: docId,
      targetName: empresaNome,
      details: 'Card de $empresaNome removido do CRM.',
    );
  }
}
