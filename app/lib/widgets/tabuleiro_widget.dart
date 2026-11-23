import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../jogo/partida.dart';
import '../jogo/peca.dart';
import '../jogo/tabuleiro.dart';
import '../tema.dart';

/// Onde a peça arrastada cairia agora.
class Previa {
  const Previa(
    this.peca,
    this.linha,
    this.coluna, {
    required this.valida,
    this.linhas = const [],
    this.colunas = const [],
  });

  final Peca peca;
  final int linha, coluna;
  final bool valida;
  final List<int> linhas, colunas;
}

/// Desenha a grade, a prévia da peça e a animação dos blocos que somem.
class TabuleiroWidget extends StatefulWidget {
  const TabuleiroWidget({super.key, required this.tabuleiro, this.previa, this.removidos = const [], this.geracao = 0});

  final Tabuleiro tabuleiro;
  final Previa? previa;
  final List<BlocoRemovido> removidos;

  /// Muda a cada jogada que limpou linhas; dispara a animação.
  final int geracao;

  @override
  State<TabuleiroWidget> createState() => _TabuleiroWidgetState();
}

class _TabuleiroWidgetState extends State<TabuleiroWidget> with SingleTickerProviderStateMixin {
  late final _animacao = AnimationController(vsync: this, duration: const Duration(milliseconds: 750), value: 1);

  @override
  void didUpdateWidget(TabuleiroWidget antigo) {
    super.didUpdateWidget(antigo);
    if (widget.geracao != antigo.geracao && widget.removidos.isNotEmpty) _animacao.forward(from: 0);
  }

  @override
  void dispose() {
    _animacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: AnimatedBuilder(
      animation: _animacao,
      builder: (context, _) => CustomPaint(
        painter: _Pintor(
          widget.tabuleiro,
          widget.previa,
          widget.removidos,
          _animacao.value,
          confete: !MediaQuery.of(context).disableAnimations,
        ),
      ),
    ),
  );
}

class _Pintor extends CustomPainter {
  _Pintor(this.tabuleiro, this.previa, this.removidos, this.t, {this.confete = true});

  /// Confete ao limpar linhas (desligado para quem pediu menos animação no sistema).
  final bool confete;

  final Tabuleiro tabuleiro;
  final Previa? previa;
  final List<BlocoRemovido> removidos;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const n = Tabuleiro.tamanho;
    final c = size.width / n;
    final folga = c * 0.05;
    Rect casa(int l, int k) => Rect.fromLTWH(k * c + folga, l * c + folga, c - 2 * folga, c - 2 * folga);

    final vazia = Paint()..color = Cores.casa;
    final p = previa;
    final cheias = p != null && p.valida ? {...p.linhas.map((l) => 'l$l'), ...p.colunas.map((k) => 'c$k')} : <String>{};

    for (var l = 0; l < n; l++) {
      for (var k = 0; k < n; k++) {
        final r = casa(l, k);
        final cor = tabuleiro.cor(l, k);
        if (cor == null) {
          canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(c * 0.18)), vazia);
        } else {
          // Linha prestes a sumir fica com a cor da peça: o jogador vê o que vai ganhar.
          final vaiSumir = cheias.contains('l$l') || cheias.contains('c$k');
          pintarCasa(canvas, r, vaiSumir ? p!.peca.cor : cor);
        }
      }
    }

    if (p != null) {
      for (final cel in p.peca.formato.celulas) {
        final l = p.linha + cel.linha, k = p.coluna + cel.coluna;
        if (l < 0 || k < 0 || l >= n || k >= n) continue;
        pintarBloco(
          canvas,
          casa(l, k),
          p.valida ? Cores.pecas[p.peca.cor] : Colors.white,
          opacidade: p.valida ? 0.55 : 0.18,
          indice: p.valida ? p.peca.cor : null,
        );
      }
    }

    if (t < 1) {
      // Os blocos encolhem na primeira parte da animação; o confete dura até o fim.
      final tb = (t / 0.56).clamp(0.0, 1.0);
      final escala = 1 - Curves.easeIn.transform(tb);
      for (final b in removidos) {
        final r = casa(b.linha, b.coluna);
        final menor = Rect.fromCenter(center: r.center, width: r.width * escala, height: r.height * escala);
        if (menor.width > 1) pintarCasa(canvas, menor, b.cor, opacidade: 1 - tb * 0.6);
      }
      if (confete) _pintarConfete(canvas, c, casa);
    }
  }

  /// Pedacinhos de cada bloco que sai voam para fora e caem. Os ângulos e as velocidades vêm de uma conta fixa
  /// (sem sorteio), então a mesma jogada sempre faz o mesmo desenho.
  void _pintarConfete(Canvas canvas, double c, Rect Function(int, int) casa) {
    final porBloco = removidos.length > 24 ? 4 : 8;
    final fase = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < removidos.length; i++) {
      final b = removidos[i];
      final centro = casa(b.linha, b.coluna).center;
      final base = b.cor < Cores.pecas.length
          ? Cores.pecas[b.cor]
          : (b.cor >= 10 && b.cor < 70 ? Cores.pecas[Tabuleiro.base(b.cor) % Cores.pecas.length] : Cores.pedra);
      for (var k = 0; k < porBloco; k++) {
        final h = (b.linha * 73 + b.coluna * 151 + k * 997 + i * 31) % 1000;
        final angulo = h / 1000 * 2 * math.pi;
        final alcance = c * (0.7 + (h % 7) / 7 * 1.3);
        final x = centro.dx + math.cos(angulo) * alcance * fase;
        final y = centro.dy + math.sin(angulo) * alcance * fase + c * 1.4 * t * t;
        final lado = c * 0.27 * (1 - t * 0.7) + 1.5;
        final cor = k.isEven ? base : Color.lerp(base, Colors.white, 0.6)!;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: lado, height: lado),
            Radius.circular(lado * 0.25),
          ),
          Paint()..color = cor.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Pintor antigo) => true;
}
