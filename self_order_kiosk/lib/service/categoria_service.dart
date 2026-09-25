import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/models/categoria.dart';

import 'api_client.dart';
import 'auth_service.dart' show ApiException;

/// Legge le categorie del menu da GET /api/Categoria
class CategoriaService {
  final ApiClient _client;

  CategoriaService(this._client);

  Future<List<Categoria>> getAll() async {
    try {
      final response = await _client.dio.get('/api/Categoria');
      return (response.data as List)
          .map((json) => Categoria.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final categoriaServiceProvider = Provider<CategoriaService>(
  (ref) => CategoriaService(ref.read(apiClientProvider)),
);

/// Provider pronto per le schermate: gestisce da solo loading / errore / dati.
/// In UI: ref.watch(categorieProvider).when(data: ..., loading: ..., error: ...)
final categorieProvider = FutureProvider<List<Categoria>>(
  (ref) => ref.read(categoriaServiceProvider).getAll(),
);
