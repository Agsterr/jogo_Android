import 'package:material_ui/material_ui.dart';

import 'servicos/servicos.dart';
import 'tema.dart';
import 'telas/inicio_tela.dart';

class EncaixaApp extends StatelessWidget {
  const EncaixaApp({super.key, required this.servicos});

  final Servicos servicos;

  static final tema = temaDoJogo();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Encaixa',
    debugShowCheckedModeBanner: false,
    theme: tema,
    home: InicioTela(servicos: servicos),
  );
}

/// Fundo de todas as telas: degradê violeta com manchas de luz rosa e ciano.
class FundoJogo extends StatelessWidget {
  const FundoJogo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: Cores.fundo),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.85),
          radius: 0.9,
          colors: [Cores.brilhoRosa.withValues(alpha: 0.45), Cores.brilhoRosa.withValues(alpha: 0)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, 0.75),
            radius: 0.9,
            colors: [Cores.brilhoCiano.withValues(alpha: 0.32), Cores.brilhoCiano.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    ),
  );
}
