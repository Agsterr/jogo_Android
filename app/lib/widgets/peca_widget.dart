import 'package:material_ui/material_ui.dart';

import '../jogo/peca.dart';
import '../tema.dart';

/// Desenha uma peça com casas de [tamanhoCasa] pixels.
class PecaWidget extends StatelessWidget {
  const PecaWidget({super.key, required this.peca, required this.tamanhoCasa, this.apagada = false});

  final Peca peca;
  final double tamanhoCasa;

  /// Peça que não cabe em lugar nenhum fica apagada.
  final bool apagada;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: peca.formato.colunas * tamanhoCasa,
    height: peca.formato.linhas * tamanhoCasa,
    child: CustomPaint(painter: _Pintor(peca, apagada)),
  );
}

class _Pintor extends CustomPainter {
  _Pintor(this.peca, this.apagada);

  final Peca peca;
  final bool apagada;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / peca.formato.colunas;
    final folga = c * 0.05;
    final cor = apagada ? const Color(0xFF6B6390) : Cores.pecas[peca.cor];
    for (final cel in peca.formato.celulas) {
      pintarBloco(
        canvas,
        Rect.fromLTWH(cel.coluna * c + folga, cel.linha * c + folga, c - 2 * folga, c - 2 * folga),
        cor,
      );
    }
  }

  @override
  bool shouldRepaint(_Pintor antigo) => antigo.peca != peca || antigo.apagada != apagada;
}

/// Contador de gemas (usado no topo das telas).
class GemasChip extends StatelessWidget {
  const GemasChip({super.key, required this.gemas, this.aoTocar});

  final int gemas;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Cores.painel.withValues(alpha: 0.7),
    shape: const StadiumBorder(),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: aoTocar,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconeGema(tamanho: 20),
            const SizedBox(width: 6),
            Text('$gemas', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (aoTocar != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.add_circle, size: 18, color: Cores.gema),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Gema desenhada em código (losango facetado).
class IconeGema extends StatelessWidget {
  const IconeGema({super.key, this.tamanho = 18});

  final double tamanho;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamanho,
    child: const CustomPaint(painter: _PintorGema()),
  );
}

class _PintorGema extends CustomPainter {
  const _PintorGema();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final topo = Offset(w / 2, h * 0.05), esq = Offset(w * 0.05, h * 0.4), dir = Offset(w * 0.95, h * 0.4);
    final baixo = Offset(w / 2, h * 0.97);
    Path tri(Offset a, Offset b, Offset c) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();
    canvas
      ..drawPath(tri(topo, esq, dir), Paint()..color = const Color(0xFF9FFFF4))
      ..drawPath(tri(esq, baixo, Offset(w / 2, h * 0.4)), Paint()..color = Cores.gema)
      ..drawPath(tri(Offset(w / 2, h * 0.4), baixo, dir), Paint()..color = const Color(0xFF1FA89B));
  }

  @override
  bool shouldRepaint(_PintorGema antigo) => false;
}
