import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// Schermata "attract" del totem: slideshow a tutto schermo con le immagini
/// sponsor (zoom lento + dissolvenza) e invito a toccare. Al tocco in un
/// punto qualsiasi parte il login automatico e poi si apre il menu.
///
/// Le immagini si leggono da soli dalle cartelle:
/// - `assets/sponsor/`  → slide dello slideshow
/// - `assets/logo/`     → primo file trovato = logo al centro
/// (entrambe vanno dichiarate nel pubspec.yaml)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _intervallo = Duration(seconds: 6);
  static const _estensioni = ['.jpg', '.jpeg', '.png', '.webp'];

  late final AnimationController _pulsazione;
  Timer? _timer;

  List<String> _slide = [];
  String? _logo;
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    _pulsazione = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _caricaAsset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulsazione.dispose();
    super.dispose();
  }

  Future<void> _caricaAsset() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final immagini =
        manifest
            .listAssets()
            .where((p) => _estensioni.any(p.toLowerCase().endsWith))
            .toList()
          ..sort();

    if (!mounted) return;
    setState(() {
      _slide = immagini.where((p) => p.startsWith('assets/sponsor/')).toList();
      _logo = immagini.where((p) => p.startsWith('assets/logo/')).firstOrNull;
    });
    _avviaSlideshow();
  }

  void _avviaSlideshow() {
    _timer?.cancel();
    if (_slide.length < 2) return;
    _timer = Timer.periodic(_intervallo, (_) {
      if (!mounted) return;
      setState(() => _indice = (_indice + 1) % _slide.length);
    });
  }

  Future<void> _apriMenu() async {
    _timer?.cancel(); // niente slideshow "dietro" mentre si ordina
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AvvioGate()));
    if (mounted) _avviaSlideshow();
  }

  @override
  Widget build(BuildContext context) {
    final colore = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: const Key('splash_touch_area'),
        behavior: HitTestBehavior.opaque,
        onTap: _apriMenu,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Slide: dissolvenza tra una e l'altra (cambia la Key)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              child: _SlideView(
                key: ValueKey(_indice),
                asset: _slide.isEmpty ? null : _slide[_indice],
                durata: _intervallo + const Duration(seconds: 1),
              ),
            ),

            // 2) Sfumature scure sopra/sotto per far leggere il testo
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0, 0.25, 0.5, 1],
                ),
              ),
            ),

            // 3) Logo al centro dello schermo
            Align(
              alignment: Alignment.center,
              child: _Logo(asset: _logo),
            ),

            // 4) Invito e indicatori in basso
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: Tween(begin: 0.94, end: 1.06).animate(
                      CurvedAnimation(
                        parent: _pulsazione,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colore.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'TOCCA PER ORDINARE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_slide.length > 1)
                    _Indicatori(totale: _slide.length, attivo: _indice),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final String? asset;
  final Duration durata;

  const _SlideView({super.key, required this.asset, required this.durata});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 1.12),
      duration: durata,
      curve: Curves.linear,
      builder: (context, scala, child) =>
          Transform.scale(scale: scala, child: child),
      child: SizedBox.expand(
        child: asset == null
            ? const _SfondoPlaceholder()
            : Image.asset(
                asset!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const _SfondoPlaceholder(),
              ),
      ),
    );
  }
}

class _SfondoPlaceholder extends StatelessWidget {
  const _SfondoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4527A0), Color(0xFF1A237E)],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant, size: 120, color: Colors.white24),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? asset;

  const _Logo({required this.asset});

  @override
  Widget build(BuildContext context) {
    const testo = Text(
      'Self Order Kiosk',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );

    if (asset == null) return testo;
    return Image.asset(
      asset!,
      height: 180,
      errorBuilder: (context, error, stack) => testo,
    );
  }
}

class _Indicatori extends StatelessWidget {
  final int totale;
  final int attivo;

  const _Indicatori({required this.totale, required this.attivo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < totale; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == attivo ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == attivo ? Colors.white : Colors.white54,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
      ],
    );
  }
}
