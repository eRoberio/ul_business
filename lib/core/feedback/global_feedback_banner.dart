import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'feedback_service.dart';

class GlobalFeedbackOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalFeedbackOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = ref.watch(feedbackProvider);

    return Stack(
      children: [
        child,
        if (feedback != null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _FeedbackBannerCard(
                    feedback: feedback,
                    onDismiss: () =>
                        ref.read(feedbackProvider.notifier).dismiss(),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedbackBannerCard extends StatelessWidget {
  final FeedbackMessage feedback;
  final VoidCallback onDismiss;

  const _FeedbackBannerCard({
    required this.feedback,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final Color accent;
    final IconData icon;
    final String prefix;

    switch (feedback.type) {
      case FeedbackType.success:
        accent = tokens.success;
        icon = Icons.check_circle_rounded;
        prefix = 'Sucesso';
      case FeedbackType.warning:
        accent = tokens.warning;
        icon = Icons.warning_amber_rounded;
        prefix = 'Aviso';
      case FeedbackType.error:
        accent = tokens.danger;
        icon = Icons.error_outline_rounded;
        prefix = 'Erro';
      case FeedbackType.info:
        accent = tokens.primary;
        icon = Icons.info_outline_rounded;
        prefix = 'Informação';
    }

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: tokens.isDark ? 0.45 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tokens.badgeBackground(accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prefix,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feedback.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: tokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Fechar aviso',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
