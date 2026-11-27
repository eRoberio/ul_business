class ScheduleValidationException implements Exception {
  final String message;
  final bool isSaturdayRestriction;

  const ScheduleValidationException(
    this.message, {
    this.isSaturdayRestriction = false,
  });

  @override
  String toString() => message;
}

class ScheduledSlot {
  final String id;
  final String empresaNome;
  final DateTime start;
  final int durationMinutes;

  const ScheduledSlot({
    required this.id,
    required this.empresaNome,
    required this.start,
    required this.durationMinutes,
  });

  DateTime get end => start.add(Duration(minutes: durationMinutes));
}

class ScheduleValidator {
  static const int saturdayMinHour = 18;
  static const int saturdayMinMinute = 30;

  static void validateSaturdayRule(DateTime dateTime) {
    if (dateTime.weekday == DateTime.saturday) {
      final totalMinutes = dateTime.hour * 60 + dateTime.minute;
      final minAllowed = saturdayMinHour * 60 + saturdayMinMinute;
      if (totalMinutes < minAllowed) {
        throw const ScheduleValidationException(
          'Aos sábados, os agendamentos são permitidos exclusivamente após as 18:30.',
          isSaturdayRestriction: true,
        );
      }
    }
  }

  static void validateSlot({
    required DateTime start,
    required int durationMinutes,
    required List<ScheduledSlot> existingSlots,
    String? currentInteractionId,
    DateTime? now,
  }) {
    if (durationMinutes <= 0 || durationMinutes > 1440) {
      throw const ScheduleValidationException(
        'Informe uma duração entre 1 e 1440 minutos.',
      );
    }

    final referenceNow = now ?? DateTime.now();
    if (start.isBefore(referenceNow)) {
      throw const ScheduleValidationException('Escolha um horário futuro.');
    }

    validateSaturdayRule(start);

    final newEnd = start.add(Duration(minutes: durationMinutes));
    for (final slot in existingSlots) {
      if (currentInteractionId != null && slot.id == currentInteractionId) {
        continue;
      }
      if (start.isBefore(slot.end) && slot.start.isBefore(newEnd)) {
        throw ScheduleValidationException(
          'Horário ocupado por ${slot.empresaNome}. Escolha outro horário.',
        );
      }
    }
  }
}
