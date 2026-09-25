import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import 'riepilogo_screen.dart';

/// Carrello del totem: elenco righe con +/-/rimuovi, nota modificabile,
/// totale provvisorio e passaggio al riepilogo. Il totale vero lo
/// calcola il server.
class CarrelloScreen extends ConsumerWidget {
  const CarrelloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrello = ref.watch(cartProvider);
    final totale = ref.watch(carrelloTotaleProvider);
    final notifier = ref.read(cartProvider.notifier);
    final colore = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Carrello',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: colore,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: carrello.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Il carrello è vuoto',
                    key: const Key('txt_carrello_vuoto'),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: carrello.length,
                    itemBuilder: (context, index) {
                      final item = carrello[index];
                      final id = item.prodotto.id;

                      return _RigaCarrello(
                        key: Key('cart_item_$id'),
                        prodottoId: id,
                        nome: item.prodotto.nome,
                        prezzo: item.prodotto.prezzo,
                        immagineUrl: item.prodotto.immagineUrl,
                        quantita: item.quantita,
                        note: item.note,
                        colore: colore,
                        onMeno: () => notifier.decrementaQuantita(id),
                        onPiu: () => notifier.incrementaQuantita(id),
                        onRimuovi: () => notifier.rimuovi(id),
                        onNotaCambiata: (nuovaNota) =>
                            notifier.aggiornaNota(id, nuovaNota),
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Totale',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                '€ ${totale.toStringAsFixed(2)}',
                                key: const Key('txt_carrello_totale'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            key: const Key('btn_vai_al_riepilogo'),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RiepilogoScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colore,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Procedi al riepilogo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RigaCarrello extends StatefulWidget {
  final int prodottoId;
  final String nome;
  final double prezzo;
  final String? immagineUrl;
  final int quantita;
  final String note;
  final Color colore;
  final VoidCallback onMeno;
  final VoidCallback onPiu;
  final VoidCallback onRimuovi;
  final ValueChanged<String> onNotaCambiata;

  const _RigaCarrello({
    super.key,
    required this.prodottoId,
    required this.nome,
    required this.prezzo,
    required this.immagineUrl,
    required this.quantita,
    required this.note,
    required this.colore,
    required this.onMeno,
    required this.onPiu,
    required this.onRimuovi,
    required this.onNotaCambiata,
  });

  @override
  State<_RigaCarrello> createState() => _RigaCarrelloState();
}

class _RigaCarrelloState extends State<_RigaCarrello> {
  bool _notaAperta = false;
  late final TextEditingController _controllerNota;

  @override
  void initState() {
    super.initState();
    _controllerNota = TextEditingController(text: widget.note);
    _notaAperta = widget.note.isNotEmpty;
  }

  @override
  void dispose() {
    _controllerNota.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.prodottoId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CachedNetworkImage(
                      imageUrl: widget.immagineUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.restaurant,
                          size: 22,
                          color: widget.colore.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '€ ${widget.prezzo.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: widget.colore,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _notaAperta = !_notaAperta),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          Icons.edit_note,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          widget.note.isEmpty
                              ? 'Aggiungi nota'
                              : 'Nota: ${widget.note}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('btn_rimuovi_$id'),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.grey.shade500,
                  onPressed: widget.onRimuovi,
                ),
              ],
            ),
            if (_notaAperta)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: Key('campo_note_$id'),
                  controller: _controllerNota,
                  onChanged: widget.onNotaCambiata,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Es. senza olio, senza sale...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('btn_meno_$id'),
                        icon: const Icon(Icons.remove),
                        iconSize: 18,
                        onPressed: widget.onMeno,
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${widget.quantita}',
                          key: Key('txt_quantita_$id'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        key: Key('btn_piu_$id'),
                        icon: const Icon(Icons.add),
                        iconSize: 18,
                        onPressed: widget.onPiu,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
