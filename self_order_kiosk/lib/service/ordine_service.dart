import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/models/ordine.dart';

import 'api_client.dart';
import 'auth_service.dart' show ApiException;

/// Una riga del carrello da inviare al backend (OrdineRigaInputDto).
/// Il prezzo NON si manda: lo legge e lo calcola il server.
class OrdineRigaInput {
  final int prodottoId;
  final int quantita;

  OrdineRigaInput({required this.prodottoId, required this.quantita});

  Map<String, dynamic> toJson() => {
    'prodottoId': prodottoId,
    'quantita': quantita,
  };
}

/// Valori dell'enum StatoOrdine del backend (salvato come intero)
class StatoOrdineValue {
  static const int inAttesa = 0;
  static const int inPreparazione = 1;
  static const int pronto = 2;
  static const int consegnato = 3;
  static const int annullato = 4;
}

class OrdineService {
  final ApiClient _client;

  OrdineService(this._client);

  /// POST /api/Ordine: crea ordine + righe, il server calcola il totale.
  Future<Ordine> creaOrdine(String cliente, List<OrdineRigaInput> righe) async {
    try {
      final response = await _client.dio.post(
        '/api/Ordine',
        data: {
          'cliente': cliente,
          'righe': righe.map((r) => r.toJson()).toList(),
        },
      );
      return Ordine.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// GET /api/Ordine/{id}
  Future<Ordine> getById(int id) async {
    try {
      final response = await _client.dio.get('/api/Ordine/$id');
      return Ordine.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// PUT /api/Ordine/{id}/stato: il body è solo il numero dello stato (es. 2)
  Future<void> aggiornaStato(int id, int nuovoStato) async {
    try {
      await _client.dio.put('/api/Ordine/$id/stato', data: nuovoStato);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final ordineServiceProvider = Provider<OrdineService>(
  (ref) => OrdineService(ref.read(apiClientProvider)),
);
