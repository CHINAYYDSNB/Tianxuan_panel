import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unified storage backend.
/// - Mobile: flutter_secure_storage (Android Keystore / iOS Keychain) for secrets
/// - Web: fallback to SharedPreferences (flutter_secure_storage_web → base64)
class StorageService {
  StorageService._();

  static final _instance = StorageService._();
  static StorageService get instance => _instance;

  final _secure = const FlutterSecureStorage();

  // ─── API Key (sensitive, encrypted) ───

  Future<void> saveApiKey(String key) => _secure.write(key: 'api_key', value: key);

  Future<String?> getApiKey() => _secure.read(key: 'api_key');

  Future<void> deleteApiKey() => _secure.delete(key: 'api_key');

  // ─── Server URL (non-sensitive) ───

  Future<void> saveServerUrl(String url) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('server_url', url);
  }

  Future<String?> getServerUrl() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('server_url');
  }

  Future<void> deleteServerUrl() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('server_url');
  }

  // ─── Saved Servers List (keep apiKey encrypted, rest in prefs) ───

  /// Save server list metadata (without apiKey).
  /// Keys stored separately in secure storage.
  Future<void> saveServersJson(String json) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('saved_servers', json);
  }

  Future<String?> getServersJson() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('saved_servers');
  }

  /// Encrypt/store a single saved server's apiKey.
  Future<void> saveServerKey(String serverId, String apiKey) =>
      _secure.write(key: 'srv_key_$serverId', value: apiKey);

  /// Decrypt/load a single saved server's apiKey.
  Future<String?> getServerKey(String serverId) =>
      _secure.read(key: 'srv_key_$serverId');

  /// Delete a single saved server's apiKey.
  Future<void> deleteServerKey(String serverId) =>
      _secure.delete(key: 'srv_key_$serverId');

  // ─── First-launch migration (SharedPreferences → secure storage) ───

  Future<void> migrateIfNeeded() async {
    final p = await SharedPreferences.getInstance();
    final migrated = p.getBool('_migrated_v1');
    if (migrated == true) return;

    // migrate api_key
    final oldKey = p.getString('api_key');
    if (oldKey != null && oldKey.isNotEmpty) {
      await saveApiKey(oldKey);
      await p.remove('api_key');
    }

    // migrate saved server apiKeys
    final serversRaw = p.getString('saved_servers');
    if (serversRaw != null) {
      try {
        final list = (jsonDecode(serversRaw) as List).cast<Map<String, dynamic>>();
        for (final s in list) {
          final key = s['apiKey'] as String?;
          final id = s['id'] as String?;
          if (key != null && id != null && key.isNotEmpty) {
            await saveServerKey(id, key);
          }
        }
        // Strip apiKey from saved_servers JSON
        final cleaned = list.map((s) {
          final m = Map<String, dynamic>.from(s);
          m.remove('apiKey');
          return m;
        }).toList();
        await saveServersJson(jsonEncode(cleaned));
      } catch (_) {}
    }

    await p.setBool('_migrated_v1', true);
  }
}
