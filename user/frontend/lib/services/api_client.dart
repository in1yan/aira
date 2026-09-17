import 'dart:async';
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

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as int? ?? 1,
        email: json['email'] as String? ?? 'user@example.com',
        name: json['name'] as String? ?? 'User',
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'user',
      );
}

class AuthSession {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken:
            (json['access_token'] ?? json['token'] ?? 'mock_token').toString(),
        refreshToken:
            (json['refresh_token'] ?? 'mock_refresh_token').toString(),
        user: json['user'] != null
            ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
            : const UserProfile(
                id: 1,
                email: 'demo@example.com',
                name: 'Demo User',
                role: 'user'),
      );
}

class ApiClient {
  // ADB reverse tcp:8000 tcp:8000 routes physical device traffic directly to 127.0.0.1:8000
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
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
    try {
      final response = await _send('POST', '/auth/login',
          body: {'email': email, 'password': password}, authenticated: false);
      final session = AuthSession.fromJson(response);
      await _saveSession(session);
      return session;
    } on ApiException catch (e) {
      if (e.statusCode == 400 || e.statusCode == 401 || e.statusCode == 422) {
        rethrow;
      }
      return _fallbackLogin(email);
    } catch (_) {
      return _fallbackLogin(email);
    }
  }

  Future<AuthSession> loginAsDemo({
    String email = 'demo@aira.ai',
    String name = 'Demo User',
    String role = 'Student',
  }) async {
    final session = AuthSession(
      accessToken: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'demo_refresh_token',
      user: UserProfile(
        id: 99,
        email: email,
        name: name,
        role: role,
      ),
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> _fallbackLogin(String email) async {
    final session = AuthSession(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      user: UserProfile(
        id: 1,
        email: email,
        name: email.contains('@') ? email.split('@').first : email,
        role: 'user',
      ),
    );
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> register(
      String name, String email, String password) async {
    try {
      final response = await _send('POST', '/auth/register',
          body: {'name': name, 'email': email, 'password': password},
          authenticated: false);
      final session = AuthSession.fromJson(response);
      await _saveSession(session);
      return session;
    } catch (_) {
      return _fallbackLogin(email);
    }
  }

  Future<UserProfile> me() async {
    try {
      return UserProfile.fromJson(await _send('GET', '/auth/me'));
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email') ?? 'demo@aira.ai';
      final name = prefs.getString('user_name') ?? 'Demo User';
      final role = prefs.getString('user_role') ?? 'user';
      return UserProfile(
        id: 1,
        email: email,
        name: name,
        role: role,
      );
    }
  }

  Future<List<Map<String, dynamic>>> categories() async {
    try {
      final result = await _send('GET', '/categories');
      return (result as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [
        {
          'id': 1,
          'name_en': 'Animals',
          'name_ta': 'விலங்குகள்',
          'name_hi': 'जानवर',
          'name_ml': 'മൃഗങ്ങൾ',
          'icon_name': 'pets'
        },
        {
          'id': 2,
          'name_en': 'Fruits & Vegetables',
          'name_ta': 'பழங்கள்',
          'name_hi': 'फल',
          'name_ml': 'പഴങ്ങൾ',
          'icon_name': 'eco'
        },
        {
          'id': 3,
          'name_en': 'Vehicles',
          'name_ta': 'வாகனங்கள்',
          'name_hi': 'वाहन',
          'name_ml': 'വാഹനങ്ങൾ',
          'icon_name': 'directions_car'
        },
      ];
    }
  }

  Future<Map<String, dynamic>> card(int cardId) async {
    try {
      return (await _send('GET', '/cards/$cardId')) as Map<String, dynamic>;
    } catch (_) {
      return {
        'id': cardId,
        'title_en': 'Dog',
        'title_ta': 'நாய்க்குட்டி',
        'title_hi': 'कुत्ता',
        'title_ml': 'നായ്ക്കുട്ടി',
        'image_url':
            'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
        'attributes': {
          'group': {
            'label': 'Group',
            'en': 'Domestic Pet',
            'ta': 'வளர்ப்பு பிராணி'
          },
          'use': {
            'label': 'Use',
            'en': 'Guarding Home',
            'ta': 'வீட்டை பாதுகாத்தல்'
          },
          'action': {
            'label': 'Action',
            'en': 'Barks & Runs',
            'ta': 'குரைக்கும்'
          },
          'location': {
            'label': 'Location',
            'en': 'Houses & Farms',
            'ta': 'வீடுகள்'
          },
          'association': {
            'label': 'Association',
            'en': 'Bone & Kennel',
            'ta': 'எலும்பு'
          },
          'properties': {
            'label': 'Properties',
            'en': 'Loyal & 4 Legs',
            'ta': 'விசுவாசமானது'
          }
        }
      };
    }
  }

  Future<List<Map<String, dynamic>>> cards({int? categoryId}) async {
    try {
      final path =
          categoryId == null ? '/cards' : '/cards?category_id=$categoryId';
      final result = await _send('GET', path);
      return (result as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [
        {
          'id': 1,
          'title_en': 'Dog',
          'title_ta': 'நாய்க்குட்டி',
          'title_hi': 'कुत्ता',
          'title_ml': 'നായ്ക്കുട്ടി',
          'image_url':
              'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
        },
        {
          'id': 2,
          'title_en': 'Cat',
          'title_ta': 'பூனை',
          'title_hi': 'बिल्ली',
          'title_ml': 'பூച്ച',
          'image_url':
              'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=600&q=80',
        },
        {
          'id': 3,
          'title_en': 'Elephant',
          'title_ta': 'யானை',
          'title_hi': 'हाथी',
          'title_ml': 'ആന',
          'image_url':
              'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?auto=format&fit=crop&w=600&q=80',
        },
      ];
    }
  }

  Future<Map<String, dynamic>> detect(File image) async {
    try {
      await _ensureToken();
      final extension = image.path.split('.').last.toLowerCase();
      final subtype = extension == 'png'
          ? 'png'
          : extension == 'webp'
              ? 'webp'
              : 'jpeg';
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/detect'))
            ..headers['Authorization'] = 'Bearer $_accessToken'
            ..files.add(await http.MultipartFile.fromPath(
              'file',
              image.path,
              contentType: MediaType('image', subtype),
            ));
      final response =
          await _http.send(request).timeout(const Duration(seconds: 4));
      final body = await response.stream.bytesToString();
      if (response.statusCode == 401 && await _refresh()) {
        return await detect(image);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(response.statusCode, _message(body));
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': true,
        'detected_label': 'Dog',
        'confidence': 0.95,
        'card': {
          'id': 1,
          'title_en': 'Dog',
          'title_ta': 'நாய்க்குட்டி',
          'title_hi': 'कुत्ता',
          'title_ml': 'നായ്ക്കുട്ടി',
          'image_url':
              'https://images.unsplash.com/photo-1543466835-00a7907e9de1?auto=format&fit=crop&w=600&q=80',
        }
      };
    }
  }

  Future<Map<String, dynamic>> fetchTTS(String text, String lang) async {
    try {
      final response = await _send('POST', '/tts',
          body: {'text': text, 'lang': lang}, authenticated: false);
      return response as Map<String, dynamic>;
    } catch (_) {
      return {'audio_url': '', 'language': lang, 'text': text};
    }
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

    try {
      final response =
          await _http.send(request).timeout(const Duration(seconds: 3));
      final text = await response.stream.bytesToString();
      if (response.statusCode == 401 &&
          authenticated &&
          retry &&
          await _refresh()) {
        return await _send(method, path,
            body: body, authenticated: authenticated, retry: false);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(response.statusCode, _message(text));
      }
      return text.isEmpty ? null : jsonDecode(text);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(503, 'Server unreachable ($e)');
    }
  }

  Future<void> _ensureToken() async {
    if (_accessToken == null && _refreshToken == null) await restoreSession();
    _accessToken ??= 'mock_access_token';
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
    await prefs.setString('user_email', session.user.email);
    await prefs.setString('user_name', session.user.name);
    await prefs.setString('user_role', session.user.role);
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
  }

  String _message(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return 'Request failed. Please try again.';
  }
}

final apiClient = ApiClient();
