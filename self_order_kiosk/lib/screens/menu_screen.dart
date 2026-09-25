import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/service/categoria_service.dart';
import 'package:self_order_kiosk/service/prodotto_service.dart';

import '../models/prodotto.dart';
import '../providers/cart_provider.dart';
import 'carrello_screen.dart';
import 'dettaglio_prodotto_screen.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorieAsync = ref.watch(categorieProvider);
    final prodottiAsync = ref.watch(prodottiProvider);
    final categoriaSelezionata = ref.watch(categoriaSelezionataProvider);
    final conteggioCarrello = ref.watch(carrelloConteggioProvider);
    final colore = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: colore,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: const Key('btn_apri_carrello'),
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CarrelloScreen()),
                  );
                },
              ),
              if (conteggioCarrello > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.redAccent,
                    child: Text(
                      '$conteggioCarrello',
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: categorieAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore categorie: $err')),
        data: (categorie) {
          return Column(
            children: [
              Container(
                color: Colors.white,
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _ChipCategoria(
                      key: const Key('cat_tutte'),
                      etichetta: 'Tutte',
                      selezionata: categoriaSelezionata == null,
                      colore: colore,
                      onTap: () =>
                          ref
                                  .read(categoriaSelezionataProvider.notifier)
                                  .state =
                              null,
                    ),
                    for (final categoria in categorie)
                      _ChipCategoria(
                        key: Key('cat_${categoria.id}'),
                        etichetta: categoria.nome,
                        selezionata: categoriaSelezionata == categoria.id,
                        colore: colore,
                        onTap: () =>
                            ref
                                    .read(categoriaSelezionataProvider.notifier)
                                    .state =
                                categoria.id,
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: prodottiAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Errore prodotti: $err')),
                  data: (prodotti) {
                    final filtrati = categoriaSelezionata == null
                        ? prodotti
                        : prodotti
                              .where(
                                (p) => p.categoriaId == categoriaSelezionata,
                              )
                              .toList();

                    if (filtrati.isEmpty) {
                      return const Center(
                        child: Text('Nessun prodotto in questa categoria'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: filtrati.length,
                      itemBuilder: (context, index) {
                        final prodotto = filtrati[index];
                        return _CardProdotto(
                          prodotto: prodotto,
                          colore: colore,
                          onTap: prodotto.esaurito
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DettaglioProdottoScreen(
                                      prodotto: prodotto,
                                    ),
                                  ),
                                ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChipCategoria extends StatelessWidget {
  final String etichetta;
  final bool selezionata;
  final Color colore;
  final VoidCallback onTap;

  const _ChipCategoria({
    super.key,
    required this.etichetta,
    required this.selezionata,
    required this.colore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: ChoiceChip(
        label: Text(etichetta),
        selected: selezionata,
        onSelected: (_) => onTap(),
        selectedColor: colore,
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(
          color: selezionata ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        elevation: selezionata ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class _CardProdotto extends StatelessWidget {
  final Prodotto prodotto;
  final Color colore;
  final VoidCallback? onTap;

  const _CardProdotto({
    required this.prodotto,
    required this.colore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabilitato = onTap == null;

    return Card(
      key: Key('prod_${prodotto.id}'),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: prodotto.immagineUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade300,
                child: Icon(
                  Icons.restaurant,
                  size: 32,
                  color: colore.withOpacity(0.4),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prodotto.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '€ ${prodotto.prezzo.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (disabilitato)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'ESAURITO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
