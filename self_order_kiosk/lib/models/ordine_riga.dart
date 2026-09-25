class OrdineRiga {
  final int id;
  final int ordineId;
  final int prodottoId;
  final int quantita;
  final double prezzoUnitario;

  OrdineRiga({
    required this.id,
    required this.ordineId,
    required this.prodottoId,
    required this.quantita,
    required this.prezzoUnitario,
  });

  factory OrdineRiga.fromJson(Map<String, dynamic> json) {
    return OrdineRiga(
      id: json['id'],
      ordineId: json['ordineId'],
      prodottoId: json['prodottoId'],
      quantita: json['quantita'],
      prezzoUnitario: (json['prezzoUnitario'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'prodottoId': prodottoId, 'quantita': quantita};
  }
}
