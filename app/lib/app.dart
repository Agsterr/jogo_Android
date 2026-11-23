import 'package:material_ui/material_ui.dart';

import 'idioma.dart';
import 'servicos/servicos.dart';
import 'tema.dart';
import 'telas/inicio_tela.dart';

class EncaixaApp extends StatelessWidget {
  const EncaixaApp({super.key, required this.servicos});

  final Servicos servicos;

  static final tema = temaDoJogo();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: servicos.progresso,
    builder: (context, _) => MaterialApp(
      title: 'Encaixa',
      debugShowCheckedModeBanner: false,
      theme: tema,
      // Trocar o idioma refaz todas as telas (a chave muda), já com os textos novos.
      builder: (context, child) => KeyedSubtree(key: ValueKey(Idioma.atual), child: child!),
      home: InicioTela(servicos: servicos),
    ),
  );
}

/// Fundo de todas as telas: degradê violeta com manchas de luz rosa e ciano.
class FundoJogo extends StatelessWidget {
  const FundoJogo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final f = Cores.fundoDoBau;
    final topo = f?[0] ?? Cores.fundoTopo, base = f?[1] ?? Cores.fundoBase;
    final rosa = f?[2] ?? Cores.brilhoRosa, ciano = f?[3] ?? Cores.brilhoCiano;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [topo, base]),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.9, -0.85),
            radius: 0.9,
            colors: [rosa.withValues(alpha: 0.45), rosa.withValues(alpha: 0)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-1, 0.75),
              radius: 0.9,
              colors: [ciano.withValues(alpha: 0.32), ciano.withValues(alpha: 0)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
