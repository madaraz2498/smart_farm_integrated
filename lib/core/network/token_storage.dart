import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT token and user profile between app launches.
///
/// Security: all sensitive values (token, userId, email, role, profileImg)
/// are stored in the OS keychain / keystore via [FlutterSecureStorage].
/// On first run after upgrading from an older version that used
/// SharedPreferences, existing values are migrated and then deleted from
/// SharedPreferences automatically.
class TokenStorage {
  TokenStorage._();

  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Key names (same as before for migration compatibility) ────────────────
  static const _kToken          = 'sf_token';
  static const _kUserId         = 'sf_user_id';
  static const _kUserName       = 'sf_user_name';
  static const _kUserEmail      = 'sf_user_email';
  static const _kUserRole       = 'sf_user_role';
  static const _kUserProfileImg = 'sf_user_profile_img';
  static const _kLocalImageB64  = 'sf_local_profile_img_b64';

  // ── Migration ─────────────────────────────────────────────────────────────

  /// Migrates any tokens still stored in SharedPreferences to secure storage.
  /// Safe to call on every startup — it's a no-op if already migrated.
  static Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyToken = prefs.getString(_kToken);
      if (legacyToken == null || legacyToken.isEmpty) return;

      // Token exists in SharedPreferences → migrate to secure storage.
      await _secure.write(key: _kToken,          value: legacyToken);
      await _secure.write(key: _kUserId,         value: prefs.getString(_kUserId));
      await _secure.write(key: _kUserName,       value: prefs.getString(_kUserName));
      await _secure.write(key: _kUserEmail,      value: prefs.getString(_kUserEmail));
      await _secure.write(key: _kUserRole,       value: prefs.getString(_kUserRole));
      await _secure.write(key: _kUserProfileImg, value: prefs.getString(_kUserProfileImg));
      final b64 = prefs.getString(_kLocalImageB64);
      if (b64 != null) await _secure.write(key: _kLocalImageB64, value: b64);

      // Remove from SharedPreferences after successful migration.
      await prefs.remove(_kToken);
      await prefs.remove(_kUserId);
      await prefs.remove(_kUserName);
      await prefs.remove(_kUserEmail);
      await prefs.remove(_kUserRole);
      await prefs.remove(_kUserProfileImg);
      await prefs.remove(_kLocalImageB64);
    } catch (e) {
      // Non-critical: migration failure is not fatal; the user will simply
      // be asked to log in again.
      assert(() { print('[TokenStorage] migration warning: $e'); return true; }());
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  static Future<void> save({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    String? profileImg,
  }) async {
    await _secure.write(key: _kToken,    value: token);
    await _secure.write(key: _kUserId,   value: userId);
    await _secure.write(key: _kUserName, value: userName);
    await _secure.write(key: _kUserEmail, value: userEmail);
    await _secure.write(key: _kUserRole,  value: userRole);
    if (profileImg != null) {
      await _secure.write(key: _kUserProfileImg, value: profileImg);
    } else {
      await _secure.delete(key: _kUserProfileImg);
    }
  }

  /// Saves locally-picked image bytes (persisted across logout/login).
  /// Pass null to clear.
  static Future<void> saveLocalImage(Uint8List? bytes) async {
    if (bytes != null) {
      await _secure.write(key: _kLocalImageB64, value: base64Encode(bytes));
    } else {
      await _secure.delete(key: _kLocalImageB64);
    }
  }

  /// Deletes the locally-picked image — called when the server image changes
  /// from another device/platform so the app fetches the fresh URL instead.
  static Future<void> deleteLocalImage() async {
    await _secure.delete(key: _kLocalImageB64);
  }

  /// Returns locally-picked image bytes, or null if none saved.
  static Future<Uint8List?> getLocalImage() async {
    try {
      final b64 = await _secure.read(key: _kLocalImageB64);
      if (b64 == null || b64.isEmpty) return null;
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async =>
      _secure.read(key: _kToken);

  static Future<Map<String, String?>> getUser() async => {
    'id':          await _secure.read(key: _kUserId),
    'name':        await _secure.read(key: _kUserName),
    'email':       await _secure.read(key: _kUserEmail),
    'role':        await _secure.read(key: _kUserRole),
    'profile_img': await _secure.read(key: _kUserProfileImg),
  };

  static Future<bool> hasToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  /// Clears auth data but keeps the local image.
  /// Called on logout so the photo persists for the next login.
  static Future<void> clearAuth() async {
    await _secure.delete(key: _kToken);
    await _secure.delete(key: _kUserId);
    await _secure.delete(key: _kUserName);
    await _secure.delete(key: _kUserEmail);
    await _secure.delete(key: _kUserRole);
    await _secure.delete(key: _kUserProfileImg);
    // _kLocalImageB64 intentionally NOT removed
  }

  /// Full wipe including the local image — used only when the user
  /// explicitly clears their data or uninstalls.
  static Future<void> clear() async {
    await clearAuth();
    await _secure.delete(key: _kLocalImageB64);
  }
}
