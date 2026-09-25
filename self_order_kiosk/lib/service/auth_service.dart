import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Errore "pulito" da mostrare in UI (al posto del DioException grezzo).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  /// Traduce un DioException in un messaggio leggibile.
  /// Il backend risponde con { "message": "...", "dataErrore": "..." } (ApiError).
  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return ApiException(data['message'], statusCode: e.response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('Impossibile contattare il server.');
    }
    return ApiException(
      'Errore imprevisto (${e.response?.statusCode ?? 'nessuna risposta'}).',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}

/// Gestisce il login: chiama POST /api/Auth/login e salva il token JWT.
class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  /// Fa il login e salva il token. Lancia ApiException se fallisce.
  Future<void> login(String username, String password) async {
    try {
      final response = await _client.dio.post(
        '/api/Auth/login',
        data: {'username': username, 'password': password},
      );

      // AuthResponseDto: { "token": "...", "user": { ... } }
      final token = response.data['token'] as String;
      await _client.saveToken(token);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() => _client.clearToken();

  Future<bool> isLoggedIn() => _client.hasToken();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.read(apiClientProvider)),
);
