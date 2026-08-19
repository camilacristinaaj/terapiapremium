import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  String? _accessToken;
  String? _refreshToken;

  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    _accessToken = access;
    _refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  bool get hasToken => _accessToken != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
    if (res.statusCode == 401) await _tryRefresh();
    return _handleResponse(res);
  }

  Future<dynamic> post(String path, dynamic body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 401) await _tryRefresh();
    return _handleResponse(res);
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
    return _handleResponse(res);
  }

  Future<dynamic> uploadFile(
    String path,
    String filePath,
    String fieldName,
  ) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _handleResponse(res);
  }

  dynamic _handleResponse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isNotEmpty ? jsonDecode(res.body) : null;
    }
    throw ApiException(res.statusCode, res.body);
  }

  Future<void> _tryRefresh() async {
    if (_refreshToken == null) return;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
      }
    } catch (_) {}
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}
