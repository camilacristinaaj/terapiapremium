import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  ApiService get api => _api;

  Future<void> checkAuth() async {
    await _api.loadTokens();
    _isAuthenticated = _api.hasToken;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String? mfaCode}) async {
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login', {
        'email': email,
        'password': password,
        'mfaCode': ?mfaCode,
      });
      if (res['mfaRequired'] == true) {
        _error = 'MFA_REQUIRED';
        notifyListeners();
        return false;
      }
      await _api.saveTokens(res['accessToken'], res['refreshToken']);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _isAuthenticated = false;
    notifyListeners();
  }
}
