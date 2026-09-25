import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:self_order_kiosk/screens/menu_screen.dart';
import 'package:self_order_kiosk/screens/splash_screen.dart';
import 'package:self_order_kiosk/service/auth_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Self Order Kiosk',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen(),
    );
  }
}

/// ⚠️ PROVVISORIO: login automatico all'avvio con l'utente di test.
/// Da rivedere quando si decide tra login automatico (utente `kiosk`)
/// e schermata di login vera.
final avvioProvider = FutureProvider<void>((ref) async {
  await ref.read(authServiceProvider).login('mrossi', 'password123');
});

/// Aspetta il login, poi mostra il menu. Se il login fallisce (es. backend
/// spento) mostra l'errore con un bottone per riprovare.
class AvvioGate extends ConsumerWidget {
  const AvvioGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avvio = ref.watch(avvioProvider);

    return avvio.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Impossibile accedere: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('btn_riprova_avvio'),
                onPressed: () => ref.invalidate(avvioProvider),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
      data: (_) => const MenuScreen(),
    );
  }
}
