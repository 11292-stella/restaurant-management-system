import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prodotto.dart';
import '../providers/cart_provider.dart';

class DettaglioProdottoScreen extends ConsumerStatefulWidget {
  final Prodotto prodotto;

  const DettaglioProdottoScreen({super.key, required this.prodotto});

  @override
  ConsumerState<DettaglioProdottoScreen> createState() =>
      _DettaglioProdottoScreenState();
}

class _DettaglioProdottoScreenState
    extends ConsumerState<DettaglioProdottoScreen> {
  int _quantita = 1;
  final _controllerNote = TextEditingController();

  @override
  void dispose() {
    _controllerNote.dispose();
    super.dispose();
  }

  void _aggiungiAlCarrello() {
    ref
        .read(cartProvider.notifier)
        .aggiungiConDettagli(
          widget.prodotto,
          _quantita,
          _controllerNote.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final prodotto = widget.prodotto;
    final colore = Theme.of(context).colorScheme.primary;
    final totaleRiga = prodotto.prezzo * _quantita;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: colore,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: prodotto.immagineUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey.shade200),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.restaurant,
                    size: 48,
                    color: colore.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prodotto.nome,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '€ ${prodotto.prezzo.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      color: colore,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    prodotto.descrizione,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Quantità',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        key: const Key('btn_meno_quantita_dettaglio'),
                        onPressed: _quantita > 1
                            ? () => setState(() => _quantita--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: colore,
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '$_quantita',
                          key: const Key('txt_quantita_dettaglio'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('btn_piu_quantita_dettaglio'),
                        onPressed: () => setState(() => _quantita++),
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: colore,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Note (facoltative)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('campo_note_prodotto'),
                    controller: _controllerNote,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Es. senza olio, senza sale...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            key: const Key('btn_aggiungi_al_carrello'),
            onPressed: _aggiungiAlCarrello,
            style: ElevatedButton.styleFrom(
              backgroundColor: colore,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Aggiungi al carrello · € ${totaleRiga.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
