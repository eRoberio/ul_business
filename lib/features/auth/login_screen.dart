import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/feedback/feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../data/providers/repository_providers.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/entities/login_lockout_state.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  LoginLockoutState _lockoutState = const LoginLockoutState();
  Timer? _countdownTimer;
  Duration _remainingLockout = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadLockoutState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadLockoutState() async {
    final state = await ref.read(loginSecurityRepositoryProvider).getState();
    if (!mounted) return;
    _applyLockoutState(state);
  }

  void _applyLockoutState(LoginLockoutState state) {
    _countdownTimer?.cancel();
    final now = DateTime.now();
    final remaining = state.remainingAt(now);

    setState(() {
      _lockoutState = state;
      _remainingLockout = remaining;
    });

    if (remaining > Duration.zero) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final left = state.remainingAt(DateTime.now());
        if (left <= Duration.zero) {
          timer.cancel();
          ref.read(loginSecurityRepositoryProvider).reset();
          setState(() {
            _lockoutState = const LoginLockoutState();
            _remainingLockout = Duration.zero;
          });
        } else {
          setState(() => _remainingLockout = left);
        }
      });
    }
  }

  bool get _isLocked => _remainingLockout > Duration.zero;

  String _formatCountdown(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _fazerLoginEmail() async {
    if (_isLocked) {
      ref.read(feedbackProvider.notifier).showWarning(
        'Muitas tentativas falhas. Aguarde ${_formatCountdown(_remainingLockout)} para tentar novamente.',
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ref.read(feedbackProvider.notifier).showWarning(
        'Preencha o e-mail e a senha.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
        email: email,
        password: password,
      );
      await ref.read(loginSecurityRepositoryProvider).reset();
    } on FirebaseAuthException catch (e) {
      final nextState = await ref
          .read(loginSecurityRepositoryProvider)
          .registerFailure();
      if (mounted) {
        _applyLockoutState(nextState);
      }

      if (nextState.isLockedAt(DateTime.now())) {
        try {
          await ref.read(auditLogRepositoryProvider).recordLog(
            action: AuditActionType.loginBlocked,
            actorUid: 'anonymous',
            actorName: email,
            targetId: email,
            targetName: email,
            details:
                'Acesso bloqueado por 5 minutos após ${LoginLockoutState.maxAttempts} tentativas falhas de login.',
            metadata: {'reason': e.code},
          );
        } catch (_) {
          // Não bloqueia o fluxo se estiver offline
        }
        ref.read(feedbackProvider.notifier).showError(
          'Conta temporariamente bloqueada por 5 minutos devido a 5 tentativas falhas.',
          persistent: true,
        );
      } else {
        String msg = 'Falha no login.';
        if (e.code == 'user-not-found') msg = 'Usuário não encontrado.';
        if (e.code == 'wrong-password') msg = 'Senha incorreta.';
        if (e.code == 'invalid-credential') msg = 'E-mail ou senha incorretos.';
        if (e.code == 'too-many-requests') {
          msg = 'Muitas tentativas recentes. Tente novamente em instantes.';
        }

        final restantes = nextState.remainingAttemptsBeforeLock;
        ref.read(feedbackProvider.notifier).showError(
          '$msg ($restantes ${restantes == 1 ? 'tentativa restante' : 'tentativas restantes'})',
        );
      }
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginComGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle()
          .timeout(const Duration(seconds: 90));
      await ref.read(loginSecurityRepositoryProvider).reset();
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (e is FirebaseAuthException &&
          (e.code == 'popup-closed-by-user' ||
              e.code == 'cancelled-popup-request')) {
        return;
      }
      if (e is TimeoutException) {
        ref.read(feedbackProvider.notifier).showWarning(
          'O login com Google expirou ou foi fechado. Tente novamente.',
        );
        return;
      }
      ref.read(feedbackProvider.notifier).showError(
        'Erro ao entrar com Google: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      body: Stack(
        children: [
          if (tokens.isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.75,
                    colors: [
                      tokens.primary.withValues(alpha: 0.14),
                      tokens.canvas,
                    ],
                  ),
                ),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: tokens.surfaceElevated1,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tokens.borderSubtle,
                          width: 1,
                        ),
                        boxShadow: tokens.isDark
                            ? [
                                BoxShadow(
                                  color: tokens.primary.withValues(alpha: 0.08),
                                  blurRadius: 48,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: ULBusinessLogo(size: 92, borderRadius: 20),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'UL Business',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: tokens.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Acesso ao Sistema Comercial',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_isLocked) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: tokens.badgeBackground(tokens.danger),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: tokens.danger.withValues(alpha: 0.45),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_clock_outlined,
                                    color: tokens.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Login bloqueado após 5 tentativas falhas. Liberação em ${_formatCountdown(_remainingLockout)}.',
                                      style: TextStyle(
                                        color: tokens.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_lockoutState.failedAttempts > 0) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Tentativas falhas: ${_lockoutState.failedAttempts}/${LoginLockoutState.maxAttempts}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],

                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLocked,
                            decoration: const InputDecoration(
                              labelText: 'E-mail corporativo',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            enabled: !_isLocked,
                            onSubmitted: (_) =>
                                (_isLoading || _isLocked) ? null : _fazerLoginEmail(),
                            decoration: InputDecoration(
                              labelText: 'Senha',
                              prefixIcon:
                                  const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Exibir senha'
                                    : 'Ocultar senha',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _isLocked)
                                  ? null
                                  : _fazerLoginEmail,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLocked
                                          ? 'Bloqueado (${_formatCountdown(_remainingLockout)})'
                                          : 'Entrar no Sistema',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: tokens.borderSubtle),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ou',
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: tokens.borderSubtle),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _loginComGoogle,
                              icon: Icon(
                                Icons.g_mobiledata,
                                size: 26,
                                color: tokens.textPrimary,
                              ),
                              label: Text(
                                'Entrar com Google',
                                style: TextStyle(
                                  color: tokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Não tem uma conta? ',
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    color: tokens.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const InstitutionalPartnersStrip(compact: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
