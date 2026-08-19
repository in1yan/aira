import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class UserProfile {
  final int id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String role;

  const UserProfile(
      {required this.id,
      required this.email,
      required this.name,
      this.avatarUrl,
      required this.role});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String,
      );
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  const AuthSession(
      {required this.accessToken,
      required this.refreshToken,
      required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class ApiClient {
  // Android emulators reach the host machine through 10.0.2.2.
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  final http.Client _http;

  String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final apiUri = Uri.parse(baseUrl);
    return apiUri
        .replace(path: path.startsWith('/') ? path : '/$path')
        .toString();
  }

  String? _accessToken;
  String? _refreshToken;

  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<AuthSession> login(String email, String password) async {
    final response = await _send('POST', '/auth/login',
        body: {'email': email, 'password': password}, authenticated: false);
    final session = AuthSession.fromJson(response);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> register(
      String name, String email, String password) async {
    final response = await _send('POST', '/auth/register',
        body: {'name': name, 'email': email, 'password': password},
        authenticated: false);
    final session = AuthSession.fromJson(response);
    await _saveSession(session);
    return session;
  }

  Future<UserProfile> me() async =>
      UserProfile.fromJson(await _send('GET', '/auth/me'));

  Future<List<Map<String, dynamic>>> categories() async {
    final result = await _send('GET', '/categories');
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> cards({int? categoryId}) async {
    final path =
        categoryId == null ? '/cards' : '/cards?category_id=$categoryId';
    final result = await _send('GET', path);
    return (result as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> detect(File image) async {
    await _ensureToken();
    final extension = image.path.split('.').last.toLowerCase();
    final subtype = extension == 'png'
        ? 'png'
        : extension == 'webp'
            ? 'webp'
            : 'jpeg';
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/detect'))
      ..headers['Authorization'] = 'Bearer $_accessToken'
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        image.path,
        contentType: MediaType('image', subtype),
      ));
    final response = await _http.send(request);
    final body = await response.stream.bytesToString();
    if (response.statusCode == 401 && await _refresh()) return detect(image);
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw ApiException(response.statusCode, _message(body));
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body,
      bool authenticated = true,
      bool retry = true}) async {
    if (authenticated) await _ensureToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    if (authenticated) headers['Authorization'] = 'Bearer $_accessToken';
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await _http.send(request);
    final text = await response.stream.bytesToString();
    if (response.statusCode == 401 &&
        authenticated &&
        retry &&
        await _refresh()) {
      return _send(method, path,
          body: body, authenticated: authenticated, retry: false);
    }
    if (response.statusCode < 200 || response.statusCode >= 300)
      throw ApiException(response.statusCode, _message(text));
    return text.isEmpty ? null : jsonDecode(text);
  }

  Future<void> _ensureToken() async {
    if (_accessToken == null && _refreshToken == null) await restoreSession();
    if (_accessToken == null)
      throw const ApiException(401, 'Please sign in again.');
  }

  Future<bool> _refresh() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _send('POST', '/auth/refresh',
          body: {'refresh_token': _refreshToken}, authenticated: false);
      final session = AuthSession.fromJson(response);
      await _saveSession(session);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setString('refresh_token', session.refreshToken);
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  String _message(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null)
        return decoded['detail'].toString();
    } catch (_) {}
    return 'Request failed. Please try again.';
  }
}

final apiClient = ApiClient();
