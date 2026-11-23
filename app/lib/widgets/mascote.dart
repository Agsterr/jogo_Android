import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tema.dart';

enum Humor { feliz, festa, triste, uau }

/// "Quadrinho", o mascote do Encaixa: um bloco simpático desenhado em código (sem imagens).
class Mascote extends StatelessWidget {
  const Mascote({super.key, this.humor = Humor.feliz, this.tamanho = 72, this.cor});

  final Humor humor;
  final double tamanho;

  /// Cor do corpo (padrão: a primeira cor do tema de peças).
  final Color? cor;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Quadrinho, o mascote',
    child: SizedBox.square(
      dimension: tamanho,
      child: CustomPaint(painter: _PintorMascote(humor, cor ?? Cores.pecas[3])),
    ),
  );
}

class _PintorMascote extends CustomPainter {
  _PintorMascote(this.humor, this.cor);

  final Humor humor;
  final Color cor;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final corpo = Rect.fromLTWH(w * 0.1, w * 0.14, w * 0.8, w * 0.76);
    final escura = Color.lerp(cor, Colors.black, 0.4)!;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(corpo.shift(Offset(0, w * 0.05)), Radius.circular(w * 0.2)),
        Paint()..color = escura,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(corpo, Radius.circular(w * 0.2)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(cor, Colors.white, 0.4)!, cor],
          ).createShader(corpo),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, w * 0.2, w * 0.35, w * 0.07), Radius.circular(w * 0.04)),
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );

    final olho = Paint()..color = const Color(0xFF241046);
    final branco = Paint()..color = Colors.white;
    final yOlho = w * 0.46;
    for (final x in [w * 0.34, w * 0.66]) {
      if (humor == Humor.uau) {
        // olhos arregalados
        canvas
          ..drawCircle(Offset(x, yOlho), w * 0.1, branco)
          ..drawCircle(
            Offset(x, yOlho),
            w * 0.1,
            Paint()
              ..color = const Color(0xFF241046)
              ..style = PaintingStyle.stroke
              ..strokeWidth = w * 0.03,
          )
          ..drawCircle(Offset(x, yOlho), w * 0.045, olho);
      } else if (humor == Humor.festa) {
        // olhos fechados sorrindo (arco para cima)
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, yOlho), width: w * 0.16, height: w * 0.14),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF241046)
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.045
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas
          ..drawCircle(Offset(x, yOlho), w * 0.075, olho)
          ..drawCircle(Offset(x - w * 0.02, yOlho - w * 0.025), w * 0.025, branco);
      }
    }
    // bochechas
    for (final x in [w * 0.22, w * 0.78]) {
      canvas.drawCircle(Offset(x, w * 0.6), w * 0.05, Paint()..color = const Color(0xFFFF5FA2).withValues(alpha: 0.5));
    }
    final boca = Paint()
      ..color = const Color(0xFF241046)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final centro = Offset(w * 0.5, w * 0.64);
    switch (humor) {
      case Humor.feliz:
        canvas.drawArc(Rect.fromCenter(center: centro, width: w * 0.22, height: w * 0.14), 0, math.pi, false, boca);
      case Humor.festa:
        canvas.drawArc(
          Rect.fromCenter(center: centro, width: w * 0.26, height: w * 0.22),
          0,
          math.pi,
          true,
          Paint()..color = const Color(0xFF241046),
        );
        // estrelinhas de festa
        for (final (dx, dy) in [(0.1, 0.1), (0.9, 0.08), (0.04, 0.5), (0.96, 0.46)]) {
          _estrela(canvas, Offset(w * dx, w * dy), w * 0.07, Paint()..color = Cores.ouro);
        }
      case Humor.uau:
        canvas
          ..drawOval(
            Rect.fromCenter(center: centro.translate(0, w * 0.02), width: w * 0.14, height: w * 0.18),
            Paint()..color = const Color(0xFF241046),
          )
          ..drawCircle(Offset(w * 0.9, w * 0.1), w * 0.05, Paint()..color = Cores.ouro);
      case Humor.triste:
        canvas.drawArc(
          Rect.fromCenter(center: centro.translate(0, w * 0.06), width: w * 0.2, height: w * 0.12),
          math.pi,
          math.pi,
          false,
          boca,
        );
    }
  }

  void _estrela(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final raio = i.isEven ? r : r * 0.4;
      final a = i * math.pi / 4 - math.pi / 2;
      final ponto = Offset(c.dx + raio * math.cos(a), c.dy + raio * math.sin(a));
      i == 0 ? path.moveTo(ponto.dx, ponto.dy) : path.lineTo(ponto.dx, ponto.dy);
    }
    canvas.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(_PintorMascote antigo) => antigo.humor != humor || antigo.cor != cor;
}

/// Frase do mascote para o fim da partida: depende de como o jogador foi em relação ao recorde.
String fraseDoMascote({required bool novoRecorde, required int pontos, required int recorde}) {
  if (novoRecorde) return 'Você se superou! Esse é seu novo recorde!';
  if (recorde > 0 && pontos >= recorde * 0.8) return 'Quase lá! Mais uma e você bate o recorde!';
  if (recorde > 0 && pontos >= recorde * 0.4) return 'Boa partida! Cada jogada ensina algo.';
  return 'Vamos de novo? Eu acredito em você!';
}

Humor humorDoFim({required bool novoRecorde, required int pontos, required int recorde}) {
  if (novoRecorde) return Humor.festa;
  if (recorde > 0 && pontos < recorde * 0.4) return Humor.triste;
  return Humor.feliz;
}

/// Dicas que o mascote dá durante a partida.
const dicasDoMascote = [
  'Dica: deixe espaço livre para as peças grandes.',
  'Dica: limpar várias linhas de uma vez vale muito mais!',
  'Dica: uma linha toda da mesma cor dá gema e bônus.',
  'Dica: combos seguidos multiplicam os pontos. Não deixe esfriar!',
  'Dica: olhe as 3 peças antes de jogar a primeira.',
  'Dica: o Martelo e a Bomba salvam partidas complicadas.',
];

/// O que o mascote diz depois de uma jogada, ou `null` se não tem nada a dizer.
///
/// [elogioNivel] vai de 0 (sem elogio) a 4; [semLimpar] é quantas jogadas seguidas sem limpar linha;
/// [ocupadas] é quantas casas do tabuleiro (de 64) estão cheias.
({String texto, Humor humor})? falaAposJogada({
  required int elogioNivel,
  String? elogioTexto,
  required int semLimpar,
  required int ocupadas,
  required int jogadas,
}) {
  if (elogioNivel >= 3 && elogioTexto != null) return (texto: '$elogioTexto Uau!', humor: Humor.uau);
  if (elogioNivel >= 1 && elogioTexto != null) return (texto: elogioTexto, humor: Humor.festa);
  if (ocupadas >= 50) return (texto: 'Cuidado, o tabuleiro está quase cheio!', humor: Humor.triste);
  if (semLimpar > 0 && semLimpar % 5 == 0) {
    return (texto: dicasDoMascote[(jogadas ~/ 5) % dicasDoMascote.length], humor: Humor.feliz);
  }
  return null;
}
