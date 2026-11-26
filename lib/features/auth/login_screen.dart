import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/design_system_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Future<void>? _googleInitialization;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login via E-mail e Senha
  Future<void> _fazerLoginEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o e-mail e a senha.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Falha no login.';
      if (e.code == 'user-not-found') msg = 'Usuário não encontrado.';
      if (e.code == 'wrong-password') msg = 'Senha incorreta.';
      if (e.code == 'invalid-credential') msg = 'E-mail ou senha incorretos.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Login via Google
  Future<void> _loginComGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final UserCredential userCredential;
      final String accessToken;
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        for (final scope in _calendarScopes) {
          provider.addScope(scope);
        }
        userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
        final credential = userCredential.credential;
        if (credential is! OAuthCredential || credential.accessToken == null) {
          throw StateError('Google nao retornou um token de acesso.');
        }
        accessToken = credential.accessToken!;
      } else {
        final googleSignIn = GoogleSignIn.instance;
        await (_googleInitialization ??= googleSignIn.initialize());
        if (!googleSignIn.supportsAuthenticate()) {
          throw UnsupportedError(
            'Login com Google indisponivel nesta plataforma.',
          );
        }
        final googleUser = await googleSignIn.authenticate(
          scopeHint: _calendarScopes,
        );
        final authorization = await googleUser.authorizationClient
            .authorizeScopes(_calendarScopes);
        accessToken = authorization.accessToken;
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }
      final User? user = userCredential.user;

      if (user != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnap = await userDocRef.get();

        if (!docSnap.exists) {
          await userDocRef.set({
            'uid': user.uid,
            'nome': user.displayName ?? 'Sem Nome',
            'email': user.email,
            'fotoUrl': user.photoURL,
            'role': 'pendente',
            'googleAccessToken': accessToken,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        } else {
          await userDocRef.update({
            'googleAccessToken': accessToken,
          });
        }
      }
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (e is FirebaseAuthException && e.code == 'popup-closed-by-user') {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao entrar com Google: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
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
                            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
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
                      child: ULBusinessLogo(
                        size: 92,
                        borderRadius: 20,
                      ),
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
                    const SizedBox(height: 28),

                    // E-mail
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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

                    // Senha
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onSubmitted: (_) => _isLoading ? null : _fazerLoginEmail(),
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botão Entrar
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fazerLoginEmail,
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
                                'Entrar no Sistema',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
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

                    // Botão Login Google
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

                    // Atalho para Criar Conta
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
                                builder: (context) => const RegisterScreen(),
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
            ),
          ),
        ],
      ),
    );
  }
}
