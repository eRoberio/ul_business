import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FeedbackType { success, warning, error, info }

class FeedbackMessage {
  final String id;
  final String message;
  final FeedbackType type;
  final bool persistent;

  const FeedbackMessage({
    required this.id,
    required this.message,
    required this.type,
    this.persistent = false,
  });
}

class FeedbackNotifier extends Notifier<FeedbackMessage?> {
  Timer? _dismissTimer;

  @override
  FeedbackMessage? build() {
    ref.onDispose(() => _dismissTimer?.cancel());
    return null;
  }

  void show(
    String message, {
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 4),
    bool persistent = false,
  }) {
    _dismissTimer?.cancel();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    state = FeedbackMessage(
      id: id,
      message: message,
      type: type,
      persistent: persistent,
    );
    if (!persistent) {
      _dismissTimer = Timer(duration, () {
        if (state?.id == id) {
          state = null;
        }
      });
    }
  }

  void showSuccess(String message, {bool persistent = false}) => show(
    message,
    type: FeedbackType.success,
    persistent: persistent,
  );

  void showWarning(String message, {bool persistent = false}) => show(
    message,
    type: FeedbackType.warning,
    duration: const Duration(seconds: 5),
    persistent: persistent,
  );

  void showError(String message, {bool persistent = false}) => show(
    message,
    type: FeedbackType.error,
    duration: const Duration(seconds: 6),
    persistent: persistent,
  );

  void dismiss() {
    _dismissTimer?.cancel();
    state = null;
  }
}

final feedbackProvider =
    NotifierProvider<FeedbackNotifier, FeedbackMessage?>(FeedbackNotifier.new);
