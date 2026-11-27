import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

class FirebaseFreeTierConfig {
  static const String _webRecaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  static Future<void> configure() async {
    _configureFirestoreOfflinePersistence();
    await _activateAppCheck();
  }

  static void _configureFirestoreOfflinePersistence() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore persistence config skipped: $e');
    }
  }

  static Future<void> _activateAppCheck() async {
    try {
      if (kIsWeb) {
        if (_webRecaptchaSiteKey.isEmpty) {
          debugPrint(
            'App Check Web: defina --dart-define=RECAPTCHA_SITE_KEY=... em produção.',
          );
          return;
        }
        await FirebaseAppCheck.instance.activate(
          providerWeb: ReCaptchaV3Provider(_webRecaptchaSiteKey),
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      }
    } catch (e) {
      // Não impede o app de iniciar caso o App Check ainda não esteja provisionado no console
      debugPrint('Firebase App Check activation skipped: $e');
    }
  }
}
