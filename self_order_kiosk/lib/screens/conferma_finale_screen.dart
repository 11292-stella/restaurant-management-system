import 'dart:async';

import 'package:flutter/material.dart';

import 'menu_screen.dart';

/// Schermata finale del totem: mostra il numero ordine e torna
/// automaticamente al menu dopo qualche secondo (comportamento da
/// kiosk), con anche un bottone per farlo subito.
class ConfermaFinaleScreen extends StatefulWidget {
  final int numeroOrdine;

  const ConfermaFinaleScreen({super.key, required this.numeroOrdine});

  @override
  State<ConfermaFinaleScreen> createState() => _ConfermaFinaleScreenState();
}

class _ConfermaFinaleScreenState extends State<ConfermaFinaleScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), _tornaAlMenu);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tornaAlMenu() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MenuScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 96),
            const SizedBox(height: 24),
            Text(
              'Ordine #${widget.numeroOrdine} confermato',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              key: const Key('btn_torna_al_menu'),
              onPressed: _tornaAlMenu,
              child: const Text('Torna al menu'),
            ),
          ],
        ),
      ),
    );
  }
}
