import 'package:material_ui/material_ui.dart';

import '../jogo/figuras.dart';

/// Desenho de blocos de um mundo. Só os [pedacos] revelados aparecem coloridos; o resto fica um vulto escuro.
/// [destaque] (um pedaço) brilha: é o que acabou de ser revelado.
class FiguraWidget extends StatelessWidget {
  const FiguraWidget({
    super.key,
    required this.figura,
    required this.pedacos,
    this.destaque = const {},
    this.largura = 150,
  });

  final Figura figura;
  final Set<int> pedacos;
  final Set<int> destaque;
  final double largura;

  bool get completa => pedacos.length >= figura.comBloco.length;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: largura,
    height: largura * Figura.altura / Figura.colunas,
    child: CustomPaint(painter: _PintorDaFigura(figura, pedacos, destaque, completa)),
  );
}

class _PintorDaFigura extends CustomPainter {
  _PintorDaFigura(this.figura, this.pedacos, this.destaque, this.completa);

  final Figura figura;
  final Set<int> pedacos;
  final Set<int> destaque;
  final bool completa;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / Figura.colunas;
    for (var l = 0; l < Figura.altura; l++) {
      for (var k = 0; k < Figura.colunas; k++) {
        final pedaco = (l ~/ 2) * Figura.pedacosPorLinha + (k ~/ 2);
        final cor = figura.cor(l, k);
        final casa = Rect.fromLTWH(k * c + c * 0.06, l * c + c * 0.06, c * 0.88, c * 0.88);
        final r = RRect.fromRectAndRadius(casa, Radius.circular(c * 0.2));
        if (!pedacos.contains(pedaco)) {
          // Pedaço ainda escondido: casa apagada, só para mostrar o tamanho do desenho (pedaço vazio nem aparece).
          if (figura.comBloco.contains(pedaco)) canvas.drawRRect(r, Paint()..color = const Color(0x1AFFFFFF));
          continue;
        }
        if (cor == null) continue;
        final base = Color(cor);
        canvas.drawRRect(
          r.shift(Offset(0, c * 0.07)),
          Paint()..color = Color.lerp(base, const Color(0xFF000000), 0.35)!,
        );
        canvas.drawRRect(r, Paint()..color = base);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(casa.left + c * 0.12, casa.top + c * 0.1, c * 0.5, c * 0.14),
            Radius.circular(c * 0.07),
          ),
          Paint()..color = const Color(0x66FFFFFF),
        );
        if (destaque.contains(pedaco)) {
          canvas.drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = c * 0.1
              ..color = const Color(0xFFFFFFFF),
          );
        }
      }
    }
    if (completa) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x22FFD700), Color(0x00FFD700)])
              .createShader(Offset.zero & size),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDaFigura old) =>
      old.figura != figura ||
      old.destaque.length != destaque.length ||
      old.destaque.any((e) => !destaque.contains(e)) ||
      old.completa != completa ||
      old.pedacos.length != pedacos.length;
}
