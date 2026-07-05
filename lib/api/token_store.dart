import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore(this._prefs);

  static const _accessKey = 'qe_access';
  static const _refreshKey = 'qe_refresh';

  final SharedPreferences _prefs;

  String? get access => _prefs.getString(_accessKey);
  String? get refresh => _prefs.getString(_refreshKey);

  Future<void> set({String? access, String? refresh}) async {
    if (access != null) await _prefs.setString(_accessKey, access);
    if (refresh != null) await _prefs.setString(_refreshKey, refresh);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}
