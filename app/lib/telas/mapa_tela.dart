import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/fases.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import 'jogo_tela.dart';

/// Mapa do modo Fases: trilha em curva, um mundo a cada 20 fases.
class MapaTela extends StatefulWidget {
  const MapaTela({super.key, required this.servicos});

  static const nomeDaRota = 'mapa';

  /// Mostra o mapa: volta para ele se já estiver aberto embaixo, senão abre (nunca empilha dois).
  static void abrir(BuildContext context, Servicos servicos) {
    final nav = Navigator.of(context);
    var achou = false;
    nav.popUntil((rota) {
      achou = rota.settings.name == nomeDaRota;
      return achou || rota.isFirst;
    });
    if (!achou) {
      nav.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: nomeDaRota),
          builder: (_) => MapaTela(servicos: servicos),
        ),
      );
    }
  }

  final Servicos servicos;

  @override
  State<MapaTela> createState() => _MapaTelaState();
}

class _MapaTelaState extends State<MapaTela> with SingleTickerProviderStateMixin {
  static const _alturaNo = 100.0, _alturaMundo = 90.0;

  late final _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  // Abre já mostrando a fase atual.
  late final _rolagem = ScrollController(initialScrollOffset: math.max(0, _topoDoNo(_atual) - 260));

  int get _atual => math.min(widget.servicos.progresso.faseLiberada, Fase.total);

  static double _topoDoNo(int n) => ((n - 1) ~/ Fase.porMundo + 1) * _alturaMundo + (n - 1) * _alturaNo;

  @override
  void dispose() {
    _pulso.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  void _jogar(int n) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => JogoTela(servicos: widget.servicos, fase: Fase.numero(n)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.servicos.progresso;
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const TextoContornado('Fases', tamanho: 26),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: p,
                      builder: (context, _) => Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Cores.ouro, size: 28),
                          TextoContornado('${p.estrelasTotais}/${Fase.total * 3}', tamanho: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => ListenableBuilder(
                    listenable: p,
                    builder: (context, _) => SingleChildScrollView(controller: _rolagem, child: _mapa(c.maxWidth)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapa(double largura) {
    final p = widget.servicos.progresso;
    Offset centro(int n) => Offset(largura / 2 + math.sin(n * 0.85) * largura * 0.28, _topoDoNo(n) + _alturaNo / 2);
    final altura = _topoDoNo(Fase.total) + _alturaNo + 40;
    return SizedBox(
      height: altura,
      child: Stack(
        children: [
          // Faixa de cor de cada mundo.
          for (var m = 0; m < Fase.mundos.length; m++)
            Positioned(
              left: 0,
              right: 0,
              top: _topoDoNo(m * Fase.porMundo + 1) - _alturaMundo,
              height: _alturaMundo + Fase.porMundo * _alturaNo,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [corDoMundo(m).withValues(alpha: 0.28), corDoMundo(m).withValues(alpha: 0.05)],
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: CustomPaint(
              painter: _Trilha([for (var n = 1; n <= Fase.total; n++) centro(n)], liberadas: p.faseLiberada),
            ),
          ),
          for (var m = 0; m < Fase.mundos.length; m++)
            Positioned(
              left: 0,
              right: 0,
              top: _topoDoNo(m * Fase.porMundo + 1) - _alturaMundo + 16,
              child: Center(child: _FitaDoMundo(m)),
            ),
          for (var n = 1; n <= Fase.total; n++)
            Positioned(
              left: centro(n).dx - 50,
              top: centro(n).dy - 50,
              width: 100,
              height: 100,
              child: _NoFase(
                numero: n,
                estrelas: p.estrelasDaFase(n),
                liberada: n <= p.faseLiberada,
                pulso: n == _atual ? _pulso : null,
                aoTocar: () => _jogar(n),
              ),
            ),
        ],
      ),
    );
  }
}

Color corDoMundo(int mundo) => const [
  Color(0xFFFF2E7E), // Doce
  Color(0xFF00B4FF), // Oceano
  Color(0xFFFF6A00), // Vulcão
  Color(0xFF00C46A), // Floresta
  Color(0xFF7FD8FF), // Gelo
  Color(0xFFE0A030), // Deserto
  Color(0xFF8B5CFF), // Galáxia
][mundo % 7];

/// Caminho pontilhado ligando as fases (aceso até a fase atual).
class _Trilha extends CustomPainter {
  _Trilha(this.pontos, {required this.liberadas});

  final List<Offset> pontos;
  final int liberadas;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < pontos.length - 1; i++) {
      final a = pontos[i], b = pontos[i + 1];
      final acesa = i + 2 <= liberadas;
      final caminho = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
      canvas.drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..color = Colors.black.withValues(alpha: 0.25),
      );
      for (final m in caminho.computeMetrics()) {
        for (var d = 10.0; d < m.length - 10; d += 18) {
          final pos = m.getTangentForOffset(d)!.position;
          canvas.drawCircle(pos, 4.5, Paint()..color = acesa ? Cores.ouro : Colors.white.withValues(alpha: 0.35));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Trilha antigo) => antigo.liberadas != liberadas || antigo.pontos.length != pontos.length;
}

class _FitaDoMundo extends StatelessWidget {
  const _FitaDoMundo(this.mundo);

  final int mundo;

  @override
  Widget build(BuildContext context) {
    final cor = corDoMundo(mundo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(colors: [Color.lerp(cor, Colors.white, 0.25)!, cor]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: Color.lerp(cor, Colors.black, 0.45)!, offset: const Offset(0, 5)),
          BoxShadow(color: cor.withValues(alpha: 0.5), blurRadius: 18),
        ],
      ),
      child: TextoContornado(
        'Mundo ${mundo + 1} · ${Fase.mundos[mundo]}',
        tamanho: 20,
        contorno: Color.lerp(cor, Colors.black, 0.55)!,
      ),
    );
  }
}

class _NoFase extends StatelessWidget {
  const _NoFase({
    required this.numero,
    required this.estrelas,
    required this.liberada,
    required this.aoTocar,
    this.pulso,
  });

  final int numero, estrelas;
  final bool liberada;
  final VoidCallback aoTocar;

  /// Só a fase atual pulsa.
  final Animation<double>? pulso;

  @override
  Widget build(BuildContext context) {
    final atual = pulso != null;
    final cor = liberada ? corDoMundo((numero - 1) ~/ Fase.porMundo) : const Color(0xFF5B5480);
    final lado = atual ? 70.0 : 60.0;
    final botao = Semantics(
      button: true,
      label: 'Fase $numero',
      child: GestureDetector(
        onTap: liberada ? aoTocar : null,
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.4),
              colors: [Color.lerp(cor, Colors.white, 0.45)!, cor, Color.lerp(cor, Colors.black, 0.2)!],
              stops: const [0, 0.6, 1],
            ),
            border: Border.all(color: atual ? Colors.white : Colors.white.withValues(alpha: 0.45), width: 3),
            boxShadow: [
              BoxShadow(color: Color.lerp(cor, Colors.black, 0.5)!, offset: const Offset(0, 5)),
              if (atual) BoxShadow(color: cor.withValues(alpha: 0.9), blurRadius: 24, spreadRadius: 2),
            ],
          ),
          alignment: Alignment.center,
          child: liberada
              ? TextoContornado('$numero', tamanho: atual ? 28 : 24, contorno: Color.lerp(cor, Colors.black, 0.55)!)
              : const Icon(Icons.lock_rounded, color: Color(0xFFCFC8F0)),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (pulso case final p?)
          AnimatedBuilder(
            animation: p,
            builder: (context, child) => Transform.scale(scale: 1 + p.value * 0.08, child: child),
            child: botao,
          )
        else
          botao,
        if (liberada && estrelas > 0)
          Positioned(
            bottom: atual ? 0 : 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: i == 2 ? 24 : 20,
                    color: i <= estrelas ? Cores.ouro : const Color(0xFF3A2C78),
                    shadows: const [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 2))],
                  ),
              ],
            ),
          ),
        if (atual)
          Positioned(
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 3))],
              ),
              child: Text(
                'JOGAR',
                style: TextStyle(color: Color.lerp(cor, Colors.black, 0.4), fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
