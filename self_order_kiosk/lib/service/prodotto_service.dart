import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/models/prodotto.dart';

import 'api_client.dart';
import 'auth_service.dart' show ApiException;

/// Legge i prodotti del menu da GET /api/Prodotto
class ProdottoService {
  final ApiClient _client;

  ProdottoService(this._client);

  Future<List<Prodotto>> getAll() async {
    try {
      final response = await _client.dio.get('/api/Prodotto');
      return (response.data as List)
          .map((json) => Prodotto.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Il backend non ha un filtro per categoria: filtriamo lato app.
  /// Mostra solo i prodotti attivi (gli "esauriti" restano, la UI li disabiliterà).
  Future<List<Prodotto>> getByCategoria(int categoriaId) async {
    final tutti = await getAll();
    return tutti
        .where((p) => p.categoriaId == categoriaId && p.attivo)
        .toList();
  }
}

final prodottoServiceProvider = Provider<ProdottoService>(
  (ref) => ProdottoService(ref.read(apiClientProvider)),
);

/// Tutti i prodotti attivi (la schermata filtra poi per categoria selezionata)
final prodottiProvider = FutureProvider<List<Prodotto>>((ref) async {
  final tutti = await ref.read(prodottoServiceProvider).getAll();
  return tutti.where((p) => p.attivo).toList();
});
