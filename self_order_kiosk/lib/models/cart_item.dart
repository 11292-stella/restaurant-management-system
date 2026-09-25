import 'prodotto.dart';

/// Una riga del carrello: un prodotto con la quantità scelta e una
/// nota facoltativa (es. "senza olio").
/// Il prezzo NON viene salvato qui: è solo per mostrare un totale
/// provvisorio a schermo, quello definitivo lo calcola sempre il server
/// quando l'ordine viene creato.
class CartItem {
  final Prodotto prodotto;
  final int quantita;
  final String note;

  const CartItem({
    required this.prodotto,
    required this.quantita,
    this.note = '',
  });

  CartItem copyWith({Prodotto? prodotto, int? quantita, String? note}) {
    return CartItem(
      prodotto: prodotto ?? this.prodotto,
      quantita: quantita ?? this.quantita,
      note: note ?? this.note,
    );
  }
}
