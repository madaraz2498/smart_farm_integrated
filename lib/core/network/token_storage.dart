import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT token and user profile between app launches.
class TokenStorage {
  TokenStorage._();

  static const _kToken     = 'sf_token';
  static const _kUserId    = 'sf_user_id';
  static const _kUserName  = 'sf_user_name';
  static const _kUserEmail = 'sf_user_email';
  static const _kUserRole  = 'sf_user_role';

  static Future<void> save({
    required String token,
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken,     token);
    await p.setString(_kUserId,    userId);
    await p.setString(_kUserName,  userName);
    await p.setString(_kUserEmail, userEmail);
    await p.setString(_kUserRole,  userRole);
  }

  static Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_kToken);

  static Future<Map<String, String?>> getUser() async {
    final p = await SharedPreferences.getInstance();
    return {
      'id':    p.getString(_kUserId),
      'name':  p.getString(_kUserName),
      'email': p.getString(_kUserEmail),
      'role':  p.getString(_kUserRole),
    };
  }

  static Future<bool> hasToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUserId);
    await p.remove(_kUserName);
    await p.remove(_kUserEmail);
    await p.remove(_kUserRole);
  }
}
