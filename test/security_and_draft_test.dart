import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ul_business/core/draft/draft_storage_service.dart';
import 'package:ul_business/core/feedback/feedback_service.dart';
import 'package:ul_business/data/repositories/local_login_security_repository.dart';
import 'package:ul_business/domain/entities/login_lockout_state.dart';
import 'package:ul_business/domain/entities/schedule_validator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalLoginSecurityRepository (Brute-Force 5 tentativas / 5 min)', () {
    test('bloqueia após 5 falhas e persiste estado entre instâncias', () async {
      const repo = LocalLoginSecurityRepository();
      final baseTime = DateTime(2026, 11, 26, 20, 0, 0);

      for (var i = 1; i <= 4; i++) {
        final state = await repo.registerFailure(now: baseTime);
        expect(state.failedAttempts, i);
        expect(state.isLockedAt(baseTime), isFalse);
      }

      final lockedState = await repo.registerFailure(now: baseTime);
      expect(lockedState.isLockedAt(baseTime), isTrue);
      expect(
        lockedState.remainingAt(baseTime),
        LoginLockoutState.lockoutDuration,
      );

      // Simula recarregamento da página / nova instância lendo do storage local
      const reloadedRepo = LocalLoginSecurityRepository();
      final persisted = await reloadedRepo.getState(
        now: baseTime.add(const Duration(minutes: 2)),
      );
      expect(persisted.isLockedAt(baseTime.add(const Duration(minutes: 2))), isTrue);
      expect(
        persisted.remainingAt(baseTime.add(const Duration(minutes: 2))),
        const Duration(minutes: 3),
      );

      // Após 5 minutos, desbloqueia automaticamente
      final afterLockout = await reloadedRepo.getState(
        now: baseTime.add(const Duration(minutes: 5, seconds: 1)),
      );
      expect(afterLockout.isLockedAt(baseTime.add(const Duration(minutes: 6))), isFalse);
      expect(afterLockout.failedAttempts, 0);
    });
  });

  group('ScheduleValidator (Regra de Sábado > 18:30 e conflitos)', () {
    test('rejeita sábado antes das 18:30 e aceita sábado 18:30 ou depois', () {
      // 2026-11-28 é sábado
      final saturdayBefore = DateTime(2026, 11, 28, 18, 29);
      final saturdayValid = DateTime(2026, 11, 28, 18, 30);

      expect(
        () => ScheduleValidator.validateSaturdayRule(saturdayBefore),
        throwsA(isA<ScheduleValidationException>()),
      );
      expect(
        () => ScheduleValidator.validateSaturdayRule(saturdayValid),
        returnsNormally,
      );
    });

    test('detecta horários sobrepostos e ignora o próprio card em edição', () {
      final now = DateTime(2026, 11, 26, 10, 0);
      final existing = [
        ScheduledSlot(
          id: 'doc-1',
          empresaNome: 'Empresa Alpha',
          start: DateTime(2026, 11, 27, 14, 0),
          durationMinutes: 60,
        ),
      ];

      expect(
        () => ScheduleValidator.validateSlot(
          start: DateTime(2026, 11, 27, 14, 30),
          durationMinutes: 60,
          existingSlots: existing,
          now: now,
        ),
        throwsA(isA<ScheduleValidationException>()),
      );

      // Mesmo horário ao editar o próprio card é permitido
      expect(
        () => ScheduleValidator.validateSlot(
          start: DateTime(2026, 11, 27, 14, 30),
          durationMinutes: 60,
          existingSlots: existing,
          currentInteractionId: 'doc-1',
          now: now,
        ),
        returnsNormally,
      );
    });
  });

  group('DraftStorageService e FeedbackNotifier', () {
    test('salva, restaura e limpa rascunho localmente', () async {
      const service = SharedPreferencesDraftStorageService();
      await service.saveDraft('test_form', {
        'empresa_nome': 'ULB Parceiros',
        'status': 'Agendada',
      });

      final loaded = await service.loadDraft('test_form');
      expect(loaded, isNotNull);
      expect(loaded!['empresa_nome'], 'ULB Parceiros');

      await service.clearDraft('test_form');
      expect(await service.loadDraft('test_form'), isNull);
    });

    test('FeedbackNotifier publica mensagens tipadas e limpa ao dispensar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(feedbackProvider.notifier).showSuccess('Salvo!');
      expect(container.read(feedbackProvider)?.type, FeedbackType.success);
      expect(container.read(feedbackProvider)?.message, 'Salvo!');

      container.read(feedbackProvider.notifier).dismiss();
      expect(container.read(feedbackProvider), isNull);
    });
  });
}
