import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.business_center,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  'UL Business',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Acesso ao Sistema Comercial',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 28),

                // E-mail
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'E-mail corporativo',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Senha
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Entrar
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerLoginEmail,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                            'Entrar no Sistema',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'ou',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white10)),
                  ],
                ),
                const SizedBox(height: 16),

                // Botão Login Google
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginComGoogle,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Entrar com Google',
                      style: TextStyle(
                        color: Colors.white,
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
                    const Text(
                      'Não tem uma conta? ',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
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
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
