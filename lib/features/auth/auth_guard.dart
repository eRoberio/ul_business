import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_system_widgets.dart';
import '../../data/providers/repository_providers.dart';
import '../dashboard/main_shell.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';

class AuthGuard extends ConsumerStatefulWidget {
  const AuthGuard({super.key});

  @override
  ConsumerState<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends ConsumerState<AuthGuard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(authRepositoryProvider).ensureSessionPersistence(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uidAsync = ref.watch(authUidStreamProvider);

    return uidAsync.when(
      loading: () => const Scaffold(
        body: BrandLoadingView(message: 'Iniciando UL Business...'),
      ),
      error: (_, _) => const LoginScreen(),
      data: (uid) {
        if (uid == null) {
          return const LoginScreen();
        }

        final profileAsync = ref.watch(currentUserProfileProvider(uid));
        return profileAsync.when(
          loading: () => const Scaffold(
            body: BrandLoadingView(message: 'Carregando seu perfil...'),
          ),
          error: (_, _) => const PendingApprovalScreen(),
          data: (user) {
            if (user == null || user.isPending) {
              return const PendingApprovalScreen();
            }
            return const MainShell();
          },
        );
      },
    );
  }
}
