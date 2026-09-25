import 'package:self_order_kiosk/models/ordine_riga.dart';

class Ordine {
  final int id;
  final String cliente;
  final String dataOra;
  final double totale;
  final int statoOrdine;
  final List<OrdineRiga> righe;

  Ordine({
    required this.id,
    required this.cliente,
    required this.dataOra,
    required this.totale,
    required this.statoOrdine,
    required this.righe,
  });

  factory Ordine.fromJson(Map<String, dynamic> json) {
    return Ordine(
      id: json['id'],
      cliente: json['cliente'],
      dataOra: json['dataOra'],
      totale: (json['totale'] as num).toDouble(),
      statoOrdine: json['statoOrdine'],
      righe: (json['righe'] as List)
          .map((r) => OrdineRiga.fromJson(r))
          .toList(),
    );
  }
}
