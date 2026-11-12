import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/fases.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import 'jogo_tela.dart';

/// Mapa do modo Fases: caminho em zigue-zague, um mundo a cada 20 fases.
class MapaTela extends StatefulWidget {
  const MapaTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<MapaTela> createState() => _MapaTelaState();
}

class _MapaTelaState extends State<MapaTela> {
  static const _alturaNo = 92.0, _alturaMundo = 72.0;

  // Abre já mostrando a fase atual.
  late final _rolagem = ScrollController(
    initialScrollOffset: math.max(
      0,
      (_atual - 1) * _alturaNo + ((_atual - 1) ~/ Fase.porMundo + 1) * _alturaMundo - 220,
    ),
  );

  int get _atual => math.min(widget.servicos.progresso.faseLiberada, Fase.total);

  @override
  void dispose() {
    _rolagem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.servicos.progresso;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fases', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Cores.fundoTopo,
        actions: [
          ListenableBuilder(
            listenable: p,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Cores.ouro),
                  const SizedBox(width: 4),
                  Text(
                    '${p.estrelasTotais}/${Fase.total * 3}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FundoJogo(
        child: ListenableBuilder(
          listenable: p,
          builder: (context, _) => ListView(
            controller: _rolagem,
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              for (var n = 1; n <= Fase.total; n++) ...[
                if ((n - 1) % Fase.porMundo == 0) _CabecalhoMundo((n - 1) ~/ Fase.porMundo),
                SizedBox(
                  height: _alturaNo,
                  child: Align(
                    alignment: Alignment(math.sin(n * 0.9) * 0.6, 0),
                    child: _NoFase(
                      numero: n,
                      estrelas: p.estrelasDaFase(n),
                      liberada: n <= p.faseLiberada,
                      atual: n == _atual,
                      aoTocar: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => JogoTela(servicos: widget.servicos, fase: Fase.numero(n)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color corDoMundo(int mundo) => Cores.blocos[[5, 4, 1][mundo % 3]];

class _CabecalhoMundo extends StatelessWidget {
  const _CabecalhoMundo(this.mundo);

  final int mundo;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _MapaTelaState._alturaMundo,
    child: Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: corDoMundo(mundo).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: corDoMundo(mundo), width: 2),
        ),
        child: Text(
          'Mundo ${mundo + 1} · ${Fase.mundos[mundo]}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    ),
  );
}

class _NoFase extends StatelessWidget {
  const _NoFase({
    required this.numero,
    required this.estrelas,
    required this.liberada,
    required this.atual,
    required this.aoTocar,
  });

  final int numero, estrelas;
  final bool liberada, atual;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = liberada ? corDoMundo((numero - 1) ~/ Fase.porMundo) : const Color(0xFF4A4370);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Fase $numero',
          child: GestureDetector(
            onTap: liberada ? aoTocar : null,
            child: Container(
              width: atual ? 68 : 58,
              height: atual ? 68 : 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(cor, Colors.white, 0.3)!, cor],
                ),
                border: Border.all(color: atual ? Colors.white : Color.lerp(cor, Colors.black, 0.3)!, width: 3),
                boxShadow: [
                  if (atual) BoxShadow(color: cor.withValues(alpha: 0.8), blurRadius: 18),
                  const BoxShadow(color: Colors.black38, offset: Offset(0, 4)),
                ],
              ),
              alignment: Alignment.center,
              child: liberada
                  ? Text('$numero', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))
                  : const Icon(Icons.lock_rounded, color: Cores.textoFraco),
            ),
          ),
        ),
        if (liberada)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 3; i++)
                Icon(Icons.star_rounded, size: 18, color: i <= estrelas ? Cores.ouro : Cores.casa),
            ],
          ),
      ],
    );
  }
}
