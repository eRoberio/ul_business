import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/draft/draft_storage_service.dart';
import '../../core/feedback/feedback_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import '../../data/providers/repository_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const String _draftKey = 'register_form';

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _draftRestored = false;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _nomeController.addListener(_scheduleDraftSave);
    _emailController.addListener(_scheduleDraftSave);
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await ref.read(draftStorageProvider).loadDraft(_draftKey);
    if (!mounted || draft == null) return;

    final nome = '${draft['nome'] ?? ''}';
    final email = '${draft['email'] ?? ''}';
    if (nome.isNotEmpty || email.isNotEmpty) {
      setState(() {
        if (nome.isNotEmpty) _nomeController.text = nome;
        if (email.isNotEmpty) _emailController.text = email;
        _draftRestored = true;
      });
    }
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(draftStorageProvider).saveDraft(_draftKey, {
        'nome': _nomeController.text,
        'email': _emailController.text,
      });
    });
  }

  Future<void> _cadastrarComGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle()
          .timeout(const Duration(seconds: 90));
      await ref.read(draftStorageProvider).clearDraft(_draftKey);

      if (mounted) {
        ref.read(feedbackProvider.notifier).showSuccess(
          'Conta Google conectada! Aguarde a aprovação do administrador.',
        );
        Navigator.pop(context);
      }
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
          'O cadastro com Google expirou ou foi fechado. Tente novamente.',
        );
        return;
      }
      ref.read(feedbackProvider.notifier).showError(
        'Erro ao cadastrar com Google: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
        name: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await ref.read(draftStorageProvider).clearDraft(_draftKey);

      if (mounted) {
        ref.read(feedbackProvider.notifier).showSuccess(
          'Cadastro solicitado! Aguarde a aprovação do administrador.',
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String mensagem = 'Erro ao criar conta.';
      if (e.code == 'email-already-in-use') {
        mensagem = 'Este e-mail já está cadastrado no sistema.';
      } else if (e.code == 'weak-password') {
        mensagem = 'A senha deve ter no mínimo 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensagem = 'Formato de e-mail inválido.';
      }
      ref.read(feedbackProvider.notifier).showError(mensagem);
    } catch (e) {
      ref.read(feedbackProvider.notifier).showError('Erro inesperado: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Criar Nova Conta',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: tokens.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        shape: const Border(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderSubtle),
              boxShadow: tokens.cardShadow,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: ULBusinessLogo(size: 76, borderRadius: 18),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cadastro de Agendista',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha seus dados para solicitar acesso',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                  ),
                  if (_draftRestored) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.badgeBackground(tokens.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rascunho restaurado automaticamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome Completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail corporativo',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!v.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Exibir senha'
                            : 'Ocultar senha',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo de 6 caracteres'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(Icons.lock_reset),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Exibir senha'
                            : 'Ocultar senha',
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _criarConta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Solicitar Cadastro',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: Divider(color: tokens.borderSubtle)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: tokens.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _cadastrarComGoogle,
                      icon: Icon(
                        Icons.g_mobiledata,
                        size: 26,
                        color: tokens.textPrimary,
                      ),
                      label: Text(
                        'Cadastrar-se com Google',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}