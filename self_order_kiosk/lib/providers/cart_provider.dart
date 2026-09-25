import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/cart_item.dart';
import '../models/prodotto.dart';

/// Notifier del carrello: espone la lista di [CartItem] e i metodi
/// per modificarla. Ogni metodo ricrea la lista (non la modifica in
/// place) così Riverpod si accorge del cambiamento.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  /// Aggiunge un prodotto al carrello con quantità e nota scelte nel
  /// dettaglio. Se il prodotto è già in carrello, somma la quantità
  /// e sostituisce la nota con quella appena inserita.
  void aggiungiConDettagli(Prodotto prodotto, int quantita, String note) {
    final index = state.indexWhere((item) => item.prodotto.id == prodotto.id);
    if (index >= 0) {
      state = [
        for (final item in state)
          if (item.prodotto.id == prodotto.id)
            item.copyWith(quantita: item.quantita + quantita, note: note)
          else
            item,
      ];
    } else {
      state = [
        ...state,
        CartItem(prodotto: prodotto, quantita: quantita, note: note),
      ];
    }
  }

  /// Aggiunge un prodotto al carrello con quantità 1 e nessuna nota.
  /// Tenuto per compatibilità con eventuali aggiunte rapide.
  void aggiungiProdotto(Prodotto prodotto) {
    aggiungiConDettagli(prodotto, 1, '');
  }

  void incrementaQuantita(int prodottoId) {
    state = [
      for (final item in state)
        if (item.prodotto.id == prodottoId)
          item.copyWith(quantita: item.quantita + 1)
        else
          item,
    ];
  }

  /// Decrementa la quantità; se scende a zero la riga viene rimossa.
  void decrementaQuantita(int prodottoId) {
    final aggiornato = <CartItem>[];
    for (final item in state) {
      if (item.prodotto.id == prodottoId) {
        if (item.quantita > 1) {
          aggiornato.add(item.copyWith(quantita: item.quantita - 1));
        }
      } else {
        aggiornato.add(item);
      }
    }
    state = aggiornato;
  }

  /// Aggiorna solo la nota di una riga già in carrello (per modificarla
  /// direttamente dalla schermata carrello, senza tornare al dettaglio).
  void aggiornaNota(int prodottoId, String note) {
    state = [
      for (final item in state)
        if (item.prodotto.id == prodottoId) item.copyWith(note: note) else item,
    ];
  }

  void rimuovi(int prodottoId) {
    state = state.where((item) => item.prodotto.id != prodottoId).toList();
  }

  void svuota() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Categoria attualmente selezionata nel menu (null = "tutte").
final categoriaSelezionataProvider = StateProvider<int?>((ref) => null);

/// Totale provvisorio del carrello, solo per mostrarlo a schermo.
final carrelloTotaleProvider = Provider<double>((ref) {
  final carrello = ref.watch(cartProvider);
  return carrello.fold<double>(
    0.0,
    (somma, item) => somma + (item.prodotto.prezzo * item.quantita),
  );
});

/// Numero totale di articoli nel carrello (per il badge).
final carrelloConteggioProvider = Provider<int>((ref) {
  final carrello = ref.watch(cartProvider);
  return carrello.fold<int>(0, (somma, item) => somma + item.quantita);
});
