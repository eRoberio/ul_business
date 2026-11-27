import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  static const _calendarScopes = [
    'https://www.googleapis.com/auth/calendar.events',
  ];

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  Future<void>? _googleInitialization;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<String?> authStateUidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentDisplayName => _auth.currentUser?.displayName;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  String? get currentPhotoUrl => _auth.currentUser?.photoURL;

  @override
  Future<void> ensureSessionPersistence() async {
    if (kIsWeb) {
      try {
        await _auth.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('Web auth persistence setup skipped: $e');
      }
    }
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(uid, doc.data());
    });
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await ensureSessionPersistence();
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await ensureSessionPersistence();
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Não foi possível criar o usuário.');
    }

    await user.updateDisplayName(name);
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'nome': name,
      'email': user.email,
      'fotoUrl': null,
      'role': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
    });

    return AppUser(
      uid: user.uid,
      nome: name,
      email: user.email ?? email,
      role: 'pendente',
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await ensureSessionPersistence();
    final UserCredential userCredential;
    final String accessToken;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      for (final scope in _calendarScopes) {
        provider.addScope(scope);
      }
      userCredential = await _auth.signInWithPopup(provider);
      final credential = userCredential.credential;
      if (credential is! OAuthCredential || credential.accessToken == null) {
        throw StateError('Google não retornou um token de acesso.');
      }
      accessToken = credential.accessToken!;
    } else {
      final googleSignIn = GoogleSignIn.instance;
      await (_googleInitialization ??= googleSignIn.initialize());
      if (!googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Login com Google indisponível nesta plataforma.',
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
      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user != null) {
      final userDocRef = _firestore.collection('users').doc(user.uid);
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
        await userDocRef.update({'googleAccessToken': accessToken});
      }
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
