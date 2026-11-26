import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ul_business/core/theme/app_colors.dart';
import 'package:ul_business/core/theme/design_system_widgets.dart';
import 'package:ul_business/core/theme/theme_provider.dart';

void main() {
  test('formatBrlCurrency formata valores monetários brasileiros', () {
    expect(formatBrlCurrency(0), 'R\$ 0,00');
    expect(formatBrlCurrency(600), 'R\$ 600,00');
    expect(formatBrlCurrency(3600), 'R\$ 3.600,00');
    expect(formatBrlCurrency(1234567.89), 'R\$ 1.234.567,89');
  });

  test('ThemeModeNotifier serializa e desserializa modos de tema', () {
    expect(ThemeModeNotifier.parseThemeMode('dark'), ThemeMode.dark);
    expect(ThemeModeNotifier.parseThemeMode('light'), ThemeMode.light);
    expect(ThemeModeNotifier.parseThemeMode('system'), ThemeMode.system);
    expect(ThemeModeNotifier.serializeThemeMode(ThemeMode.dark), 'dark');
    expect(ThemeModeNotifier.serializeThemeMode(ThemeMode.light), 'light');
    expect(ThemeModeNotifier.serializeThemeMode(ThemeMode.system), 'system');
  });

  test('AppThemeTokens mapeia cores semânticas de status', () {
    expect(AppThemeTokens.dark.statusColor('Agendada'), AppColors.success);
    expect(AppThemeTokens.light.statusColor('Aguardando'), AppColors.warning);
    expect(AppThemeTokens.dark.statusColor('Recusada'), AppColors.danger);
    expect(
      AppThemeTokens.light.statusColor('Acompanhamento'),
      AppColors.followUp,
    );
  });
}
