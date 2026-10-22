import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // Importe o Firebase

import 'firebase_options.dart'; // Importe o arquivo gerado pelo FlutterFire
import 'features/auth/auth_guard.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/main_shell.dart';

void main() async {
  // Garante que os widgets do Flutter estejam prontos antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase para a plataforma atual (Web, Android, iOS, etc)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: ULBusinessApp()));
}

// ... resto do código ULBusinessApp se mantém igual

class ULBusinessApp extends StatelessWidget {
  const ULBusinessApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UL Business',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGuard(), // A porta de entrada agora é segura
    );
  }
}
