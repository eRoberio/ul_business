import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class DraftStorageService {
  Future<void> saveDraft(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadDraft(String key);
  Future<void> clearDraft(String key);
}

class SharedPreferencesDraftStorageService implements DraftStorageService {
  static const String _prefix = 'ul_draft_';

  const SharedPreferencesDraftStorageService();

  @override
  Future<void> saveDraft(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', jsonEncode(data));
  }

  @override
  Future<Map<String, dynamic>?> loadDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearDraft(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}

final draftStorageProvider = Provider<DraftStorageService>(
  (ref) => const SharedPreferencesDraftStorageService(),
);
