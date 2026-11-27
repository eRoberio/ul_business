enum AuditActionType {
  loginBlocked('login_blocked', 'Login bloqueado (5 tentativas)'),
  cardCreated('card_created', 'Card criado no CRM'),
  cardUpdated('card_updated', 'Card atualizado no CRM'),
  cardMoved('card_moved', 'Card movido no CRM'),
  cardDeleted('card_deleted', 'Card excluído no CRM'),
  eventScheduled('event_scheduled', 'Palestra agendada'),
  contractGenerated('contract_generated', 'Contrato gerado e assinado');

  final String code;
  final String label;

  const AuditActionType(this.code, this.label);

  static AuditActionType fromCode(String code) {
    return AuditActionType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AuditActionType.cardUpdated,
    );
  }
}

class AuditLogEntry {
  final String? id;
  final AuditActionType action;
  final String actorUid;
  final String actorName;
  final String targetId;
  final String targetName;
  final String details;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AuditLogEntry({
    this.id,
    required this.action,
    required this.actorUid,
    required this.actorName,
    required this.targetId,
    required this.targetName,
    required this.details,
    required this.timestamp,
    this.metadata = const {},
  });
}
