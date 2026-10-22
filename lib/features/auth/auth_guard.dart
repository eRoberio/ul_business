import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'pending_approval_screen.dart';
import '../dashboard/main_shell.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // Se o usuário está autenticado, escuta a Role dele no Firestore em tempo real
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              return const PendingApprovalScreen();
            }

            final userData =
                userDocSnapshot.data!.data() as Map<String, dynamic>?;
            final role = userData?['role'] ?? 'pendente';

            // Se for pendente, prende na tela de aprovação
            if (role == 'pendente') {
              return const PendingApprovalScreen();
            }

            // Liberado como 'orador' ou 'agendista', vai para a aplicação principal
            return const MainShell();
          },
        );
      },
    );
  }
}
