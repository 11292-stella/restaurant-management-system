import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/service/ordine_service.dart';

import '../providers/cart_provider.dart';

import 'conferma_finale_screen.dart';

/// Ultimo passo prima dell'invio: chiede il nome del cliente, mostra il
/// riepilogo del carrello e crea l'ordine sul backend.
class RiepilogoScreen extends ConsumerStatefulWidget {
  const RiepilogoScreen({super.key});

  @override
  ConsumerState<RiepilogoScreen> createState() => _RiepilogoScreenState();
}

class _RiepilogoScreenState extends ConsumerState<RiepilogoScreen> {
  final _controllerNome = TextEditingController();
  bool _inviando = false;

  @override
  void dispose() {
    _controllerNome.dispose();
    super.dispose();
  }

  Future<void> _confermaOrdine() async {
    final carrello = ref.read(cartProvider);
    if (carrello.isEmpty) return;

    final nomeCliente = _controllerNome.text.trim();
    if (nomeCliente.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il nome del cliente')),
      );
      return;
    }

    final righe = carrello
        .map(
          (item) => OrdineRigaInput(
            prodottoId: item.prodotto.id,
            quantita: item.quantita,
          ),
        )
        .toList();

    setState(() => _inviando = true);

    try {
      final ordineService = ref.read(ordineServiceProvider);
      final ordine = await ordineService.creaOrdine(nomeCliente, righe);

      ref.read(cartProvider.notifier).svuota();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => ConfermaFinaleScreen(numeroOrdine: ordine.id),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante l'invio dell'ordine: $e")),
      );
    } finally {
      if (mounted) setState(() => _inviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrello = ref.watch(cartProvider);
    final totale = ref.watch(carrelloTotaleProvider);
    final colore = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Riepilogo ordine',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: colore,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('campo_nome_cliente'),
              controller: _controllerNome,
              decoration: InputDecoration(
                labelText: 'Nome cliente',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: carrello.length,
              itemBuilder: (context, index) {
                final item = carrello[index];
                final subtotale = item.prodotto.prezzo * item.quantita;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: CachedNetworkImage(
                              imageUrl: item.prodotto.immagineUrl ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey.shade200),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.restaurant,
                                  size: 20,
                                  color: colore.withOpacity(0.4),
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
                                item.prodotto.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (item.note.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Nota: ${item.note}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${item.quantita} x € ${item.prodotto.prezzo.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '€ ${subtotale.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colore,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        Text(
                          '€ ${totale.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      key: const Key('btn_conferma_ordine'),
                      onPressed: (_inviando || carrello.isEmpty)
                          ? null
                          : _confermaOrdine,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colore,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _inviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Conferma ordine',
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
