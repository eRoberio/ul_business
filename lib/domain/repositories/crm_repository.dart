abstract class CrmRepository {
  Stream<List<Map<String, dynamic>>> watchInteractions();
  Stream<List<Map<String, dynamic>>> watchScheduledInteractions();

  Future<String> saveInteraction({
    String? existingId,
    required Map<String, dynamic> payload,
    required String actorUid,
    required String actorName,
    String? previousStatus,
  });

  Future<void> moveStatus({
    required Map<String, dynamic> item,
    required String newStatus,
    required String newStatusFullName,
    required String actorUid,
    required String actorName,
  });

  Future<void> removeTag({
    required String docId,
    required List<String> updatedTags,
  });

  Future<void> deleteInteraction({
    required String docId,
    required String empresaNome,
    required String actorUid,
    required String actorName,
  });
}
