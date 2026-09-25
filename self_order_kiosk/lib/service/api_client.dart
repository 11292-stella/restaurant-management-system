import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Client HTTP centrale dell'app.
/// - Punta al backend .NET
/// - Allega automaticamente il token JWT (Authorization: Bearer ...)
/// - Se il backend risponde 401, cancella il token salvato
class ApiClient {
  static const int _port = 5231;

  // Dall'emulatore Android "localhost" è l'emulatore stesso:
  // il PC host si raggiunge con 10.0.2.2. Su Windows (desktop) va bene localhost.
  static String get baseUrl {
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:$_port';
  }

  static const String _tokenKey = 'jwt_token';

  final FlutterSecureStorage _storage;
  late final Dio dio;

  ApiClient({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // Prima di ogni richiesta: se c'è un token, lo allego
        onRequest: (options, handler) async {
          final token = await readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        // Se il token è scaduto/non valido, lo butto via
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  // ---------- Gestione token ----------

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

/// Provider Riverpod: un'unica istanza di ApiClient condivisa da tutti i service.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
