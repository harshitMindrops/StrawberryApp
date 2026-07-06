import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService(this._prefs);

  final SharedPreferences _prefs;
  static const _userEmailKey = 'auth_user_email';

  Future<void> login({required String email}) async {
    await _prefs.setString(_userEmailKey, email.trim().toLowerCase());
  }

  Future<void> signup({required String email}) async {
    await _prefs.setString(_userEmailKey, email.trim().toLowerCase());
  }

  Future<bool> isLoggedIn() async {
    final email = _prefs.getString(_userEmailKey);
    return email != null && email.isNotEmpty;
  }

  Future<String?> currentUserEmail() async {
    return _prefs.getString(_userEmailKey);
  }

  Future<void> logout() async {
    await _prefs.remove(_userEmailKey);
  }
}
