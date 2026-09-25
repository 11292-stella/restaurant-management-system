class Categoria {
  final int id;
  final String nome;
  final String descrizione;

  Categoria({required this.id, required this.nome, required this.descrizione});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nome: json['nome'],
      descrizione: json['descrizione'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'nome': nome, 'descrizione': descrizione};
  }
}
