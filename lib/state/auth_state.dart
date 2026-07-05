import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../models/user.dart';

class AuthState extends ChangeNotifier {
  AuthState(this._api, this._tokens);

  final ApiClient _api;
  final TokenStore _tokens;

  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isSignedIn => _user != null;

  Future<void> bootstrap() async {
    if (_tokens.access == null || _tokens.access!.isEmpty) {
      _loading = false;
      notifyListeners();
      return;
    }
    try {
      final res = await _api.dio.get('/auth/me/');
      _user = AppUser.fromJson((res.data as Map).cast<String, dynamic>());
    } catch (_) {
      await _tokens.clear();
      _user = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<AppUser> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login/', data: {
      'email': email,
      'password': password,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    await _tokens.set(
      access: data['access'] as String?,
      refresh: data['refresh'] as String?,
    );
    _user = AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    notifyListeners();
    return _user!;
  }

  Future<void> register(Map<String, dynamic> payload) async {
    await _api.dio.post('/auth/register/', data: payload);
  }

  Future<AppUser> verifyEmail(String token) async {
    final res =
        await _api.dio.post('/auth/verify-email/', data: {'token': token});
    final data = (res.data as Map).cast<String, dynamic>();
    await _tokens.set(
      access: data['access'] as String?,
      refresh: data['refresh'] as String?,
    );
    _user = AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    notifyListeners();
    return _user!;
  }

  Future<void> resendVerification(String email) async {
    await _api.dio
        .post('/auth/resend-verification/', data: {'email': email});
  }

  Future<void> requestPasswordReset(String email) async {
    await _api.dio.post('/auth/password-reset/', data: {'email': email});
  }

  Future<void> confirmPasswordReset(
      String uid, String token, String password) async {
    await _api.dio.post('/auth/password-reset-confirm/',
        data: {'uid': uid, 'token': token, 'password': password});
  }

  Future<void> logout() async {
    await _tokens.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _api.dio.delete('/auth/me/');
    await _tokens.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final res = await _api.dio.get('/auth/me/');
      _user = AppUser.fromJson((res.data as Map).cast<String, dynamic>());
      notifyListeners();
    } catch (_) {
      // ignore transient failures
    }
  }
}
