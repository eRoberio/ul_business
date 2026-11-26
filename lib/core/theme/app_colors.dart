import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Mode (Padrão Executivo)
  static const Color darkCanvas = Color(0xFF0B0E14);
  static const Color darkSurface1 = Color(0xFF131722);
  static const Color darkSurface2 = Color(0xFF1A202E);
  static const Color darkBorder = Color(0xFF262E3F);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Light Mode (Alta Legibilidade)
  static const Color lightCanvas = Color(0xFFF4F6F9);
  static const Color lightSurface1 = Color(0xFFFFFFFF);
  static const Color lightSurface2 = Color(0xFFF8FAFC);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);

  // Marca & Status Semânticos
  static const Color primaryLight = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color followUp = Color(0xFF8B5CF6);
  static const Color neutral = Color(0xFF64748B);
  static const Color finished = Color(0xFF14B8A6);
  static const Color wazeAccent = Color(0xFF05C8F7);
}

@immutable
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final bool isDark;
  final Color canvas;
  final Color surfaceElevated1;
  final Color surfaceElevated2;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color primary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color followUp;
  final Color neutral;
  final Color finished;
  final List<BoxShadow> cardShadow;

  const AppThemeTokens({
    required this.isDark,
    required this.canvas,
    required this.surfaceElevated1,
    required this.surfaceElevated2,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.primary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.followUp,
    required this.neutral,
    required this.finished,
    required this.cardShadow,
  });

  static const AppThemeTokens dark = AppThemeTokens(
    isDark: true,
    canvas: AppColors.darkCanvas,
    surfaceElevated1: AppColors.darkSurface1,
    surfaceElevated2: AppColors.darkSurface2,
    borderSubtle: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    primary: AppColors.primaryDark,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    followUp: AppColors.followUp,
    neutral: AppColors.neutral,
    finished: AppColors.finished,
    cardShadow: [],
  );

  static const AppThemeTokens light = AppThemeTokens(
    isDark: false,
    canvas: AppColors.lightCanvas,
    surfaceElevated1: AppColors.lightSurface1,
    surfaceElevated2: AppColors.lightSurface2,
    borderSubtle: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    primary: AppColors.primaryLight,
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    followUp: AppColors.followUp,
    neutral: AppColors.neutral,
    finished: AppColors.finished,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 10,
        offset: Offset(0, 2),
      ),
    ],
  );

  Color badgeBackground(Color color) => color.withValues(alpha: 0.12);

  Color statusColor(String status) {
    switch (status) {
      case 'Agendada':
        return success;
      case 'Aguardando':
        return warning;
      case 'Recusada':
        return danger;
      case 'Acompanhamento':
        return followUp;
      case 'Finalizado':
        return finished;
      case 'Em Prospecção':
      default:
        return neutral;
    }
  }

  @override
  AppThemeTokens copyWith({
    bool? isDark,
    Color? canvas,
    Color? surfaceElevated1,
    Color? surfaceElevated2,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? primary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? followUp,
    Color? neutral,
    Color? finished,
    List<BoxShadow>? cardShadow,
  }) {
    return AppThemeTokens(
      isDark: isDark ?? this.isDark,
      canvas: canvas ?? this.canvas,
      surfaceElevated1: surfaceElevated1 ?? this.surfaceElevated1,
      surfaceElevated2: surfaceElevated2 ?? this.surfaceElevated2,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      followUp: followUp ?? this.followUp,
      neutral: neutral ?? this.neutral,
      finished: finished ?? this.finished,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceElevated1: Color.lerp(
        surfaceElevated1,
        other.surfaceElevated1,
        t,
      )!,
      surfaceElevated2: Color.lerp(
        surfaceElevated2,
        other.surfaceElevated2,
        t,
      )!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      followUp: Color.lerp(followUp, other.followUp, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      finished: Color.lerp(finished, other.finished, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension BuildContextThemeX on BuildContext {
  AppThemeTokens get tokens =>
      Theme.of(this).extension<AppThemeTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppThemeTokens.dark
          : AppThemeTokens.light);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
