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

/// Fundo com degradê usado em todas as telas.
class FundoJogo extends StatelessWidget {
  const FundoJogo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: Cores.fundo),
    child: child,
  );
}
