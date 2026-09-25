class Prodotto {
  final int id;
  final String nome;
  final String descrizione;
  final double prezzo;
  final bool attivo;
  final bool esaurito;
  final int categoriaId;
  final String? immagineUrl;

  Prodotto({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.prezzo,
    required this.attivo,
    required this.esaurito,
    required this.categoriaId,
    this.immagineUrl,
  });

  factory Prodotto.fromJson(Map<String, dynamic> json) {
    return Prodotto(
      id: json['id'],
      nome: json['nome'],
      descrizione: json['descrizione'],
      prezzo: (json['prezzo'] as num).toDouble(),
      attivo: json['attivo'],
      esaurito: json['esaurito'],
      categoriaId: json['categoriaId'],
      immagineUrl: json['immagineUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'prezzo': prezzo,
      'attivo': attivo,
      'esaurito': esaurito,
      'categoriaId': categoriaId,
      'immagineUrl': immagineUrl,
    };
  }
}
