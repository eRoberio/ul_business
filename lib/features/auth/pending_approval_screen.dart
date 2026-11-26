import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final tokens = context.tokens;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CustomCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(32.0),
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ULBusinessLogo(size: 80, borderRadius: 18),
                const SizedBox(height: 20),
                Icon(Icons.hourglass_top_rounded, size: 32, color: tokens.warning),
                const SizedBox(height: 12),
                Text(
                  'Acesso em Análise',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Olá, ${user?.displayName ?? 'Usuário'}! Sua conta foi criada com o e-mail:\n${user?.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.badgeBackground(tokens.warning),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tokens.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Aguarde a liberação do administrador para acessar o painel do UL Business.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sair da Conta'),
                    onPressed: () => FirebaseAuth.instance.signOut(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}