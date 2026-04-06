import 'dart:typed_data';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT token and user profile between app launches.
class TokenStorage {
  TokenStorage._();

  static const _kToken          = 'sf_token';
  static const _kUserId         = 'sf_user_id';
  static const _kUserName       = 'sf_user_name';
  static const _kUserEmail      = 'sf_user_email';
  static const _kUserRole       = 'sf_user_role';
  static const _kUserProfileImg = 'sf_user_profile_img';
  // NEW: stores the locally-picked image as base64
  static const _kLocalImageB64  = 'sf_local_profile_img_b64';

  static Future<void> save({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
    String? profileImg,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken,      token);
    await p.setString(_kUserId,     userId);
    await p.setString(_kUserName,   userName);
    await p.setString(_kUserEmail,  userEmail);
    await p.setString(_kUserRole,   userRole);
    if (profileImg != null) {
      await p.setString(_kUserProfileImg, profileImg);
    } else {
      await p.remove(_kUserProfileImg);
    }
  }

  /// Saves locally-picked image bytes (persisted across logout/login).
  /// Pass null to clear.
  static Future<void> saveLocalImage(Uint8List? bytes) async {
    final p = await SharedPreferences.getInstance();
    if (bytes != null) {
      // base64 encode so we can store as a plain string
      final b64 = base64Encode(bytes);
      await p.setString(_kLocalImageB64, b64);
    } else {
      await p.remove(_kLocalImageB64);
    }
  }

  /// Deletes the locally-picked image — called when the server image changes
  /// from another device/platform so the app fetches the fresh URL instead.
  static Future<void> deleteLocalImage() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLocalImageB64);
  }

  /// Returns locally-picked image bytes, or null if none saved.
  static Future<Uint8List?> getLocalImage() async {
    final p = await SharedPreferences.getInstance();
    final b64 = p.getString(_kLocalImageB64);
    if (b64 == null || b64.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(b64));
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  static Future<Map<String, String?>> getUser() async {
    final p = await SharedPreferences.getInstance();
    return {
      'id':          p.getString(_kUserId),
      'name':        p.getString(_kUserName),
      'email':       p.getString(_kUserEmail),
      'role':        p.getString(_kUserRole),
      'profile_img': p.getString(_kUserProfileImg),
    };
  }

  static Future<bool> hasToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  /// Clears auth data (token + user info) but keeps the local image.
  /// Called on logout so the photo persists for the next login.
  static Future<void> clearAuth() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUserId);
    await p.remove(_kUserName);
    await p.remove(_kUserEmail);
    await p.remove(_kUserRole);
    await p.remove(_kUserProfileImg);
    // _kLocalImageB64 intentionally NOT removed
  }

  /// Full wipe including the local image — used only when the user
  /// explicitly clears their data or uninstalls.
  static Future<void> clear() async {
    await clearAuth();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLocalImageB64);
  }
}