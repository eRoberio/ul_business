import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/main_shell.dart';

void main() {
  runApp(
    // ProviderScope gerencia o estado de todo o app
    const ProviderScope(
      child: ULBusinessApp(),
    ),
  );
}

class ULBusinessApp extends StatelessWidget {
  const ULBusinessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UL Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Aponta para o "Shell", a casca principal da navegação
      home: const MainShell(), 
    );
  }
}