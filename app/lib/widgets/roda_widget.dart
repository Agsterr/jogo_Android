import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tema.dart';

/// Roda que gira até uma fatia escolhida. Usada na Roda da sorte e na roleta da partida.
///
/// Quem usa guarda uma `GlobalKey<RodaGiratoriaState>` e chama [RodaGiratoriaState.girarPara].
class RodaGiratoria extends StatefulWidget {
  const RodaGiratoria({super.key, required this.rotulos, required this.cores});

  /// Texto de cada fatia, no sentido horário a partir do topo.
  final List<String> rotulos;
  final List<Color> cores;

  @override
  State<RodaGiratoria> createState() => RodaGiratoriaState();
}

class RodaGiratoriaState extends State<RodaGiratoria> with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  double _de = 0, _ate = 0;

  bool get girando => _giro.isAnimating;

  /// Gira 5 voltas e para com o meio da [fatia] embaixo do ponteiro.
  Future<void> girarPara(int fatia) async {
    final angulo = 2 * math.pi / widget.rotulos.length;
    setState(() {
      _de = _ate % (2 * math.pi);
      _ate = -(fatia * angulo + angulo / 2) - 2 * math.pi * 5;
    });
    await _giro.forward(from: 0);
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          top: 18,
          child: AnimatedBuilder(
            animation: _giro,
            builder: (context, _) => Transform.rotate(
              angle: _de + (_ate - _de) * Curves.easeOutCubic.transform(_giro.value),
              child: CustomPaint(painter: _PintorRoda(widget.rotulos, widget.cores)),
            ),
          ),
        ),
        const CustomPaint(size: Size(40, 42), painter: _Ponteiro()),
      ],
    ),
  );
}

/// Fatias coloridas com o texto, aro com luzes e miolo.
class _PintorRoda extends CustomPainter {
  const _PintorRoda(this.rotulos, this.cores);

  final List<String> rotulos;
  final List<Color> cores;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    final fatia = 2 * math.pi / rotulos.length;
    final rFatia = r * 0.9;
    final area = Rect.fromCircle(center: c, radius: rFatia);
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2A0B5E));
    for (var i = 0; i < rotulos.length; i++) {
      final inicio = -math.pi / 2 + i * fatia;
      final cor = cores[i % cores.length];
      canvas
        ..drawArc(
          area,
          inicio,
          fatia,
          true,
          Paint()..shader = RadialGradient(colors: [Color.lerp(cor, Colors.white, 0.35)!, cor]).createShader(area),
        )
        ..drawArc(
          area,
          inicio,
          fatia,
          true,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white.withValues(alpha: 0.7),
        );
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(inicio + fatia / 2 + math.pi / 2);
      final texto = TextPainter(
        text: TextSpan(
          text: rotulos[i],
          style: TextStyle(
            fontFamily: fonteJogo,
            fontSize: r * (rotulos[i].length > 3 ? 0.13 : 0.17),
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 2), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      texto.paint(canvas, Offset(-texto.width / 2, -rFatia * 0.82));
      canvas.restore();
    }
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.95,
        r * 0.025,
        Paint()..color = i.isEven ? Cores.ouro : Colors.white,
      );
    }
    canvas
      ..drawCircle(c, r * 0.16, Paint()..color = Colors.white)
      ..drawCircle(c, r * 0.12, Paint()..color = Cores.destaque);
  }

  @override
  bool shouldRepaint(_PintorRoda antigo) => antigo.rotulos != rotulos;
}

class _Ponteiro extends CustomPainter {
  const _Ponteiro();

  @override
  void paint(Canvas canvas, Size s) {
    final caminho = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close();
    canvas
      ..drawShadow(caminho, Colors.black, 4, false)
      ..drawPath(caminho, Paint()..color = Cores.ouro)
      ..drawPath(
        caminho,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white,
      );
  }

  @override
  bool shouldRepaint(_Ponteiro antigo) => false;
}
