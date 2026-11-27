import 'package:material_ui/material_ui.dart';

import '../idioma.dart';
import '../jogo/tabuleiro.dart';
import '../tema.dart';

/// Desenho de exemplo que acompanha uma dica: mini tabuleiros "antes e depois".
enum ExemploDaDica { linhas, pedras, umaCor, combo, pontos }

/// Um mini tabuleiro: `.` vazio, `0` a `5` cor, `S` pedra, `?` casa que a peça vai preencher (destacada).
typedef _Grade = List<String>;

class _Quadro {
  const _Quadro(this.grade, this.legenda, {this.depois = false});

  final _Grade grade;
  final String legenda;

  /// O quadro mostra o resultado (linha sumiu).
  final bool depois;
}

List<List<_Quadro>> _passos(ExemploDaDica e) => switch (e) {
  ExemploDaDica.linhas || ExemploDaDica.pontos => [
    [
      const _Quadro(['.....', '.....', '012?3'], 'Falta 1 bloco'),
      const _Quadro(['.....', '.....', '.....'], 'A linha some!', depois: true),
    ],
  ],
  ExemploDaDica.pedras => [
    [
      const _Quadro(['.....', '.....', 'S12?3'], 'Pedra na linha'),
      const _Quadro(['.....', '.....', '.....'], 'A pedra quebra!', depois: true),
    ],
  ],
  ExemploDaDica.umaCor => [
    [
      const _Quadro(['.....', '.....', '22?22'], 'Mesma cor'),
      const _Quadro(['.....', '.....', '.....'], 'Bônus +1 gema', depois: true),
    ],
  ],
  ExemploDaDica.combo => [
    [
      const _Quadro(['.....', '.....', '04?12'], '1ª jogada: limpa'),
      const _Quadro(['.....', '.....', '3?514'], '2ª jogada: Combo x2'),
      const _Quadro(['.....', '.....', '2?025'], '3ª jogada: Combo x3'),
    ],
  ],
};

/// Mini tabuleiros com setas, para explicar a dica sem texto demais.
class ExemploDaDicaWidget extends StatelessWidget {
  const ExemploDaDicaWidget({super.key, required this.exemplo, required this.cor});

  final ExemploDaDica exemplo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final quadros = _passos(exemplo).first;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < quadros.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(top: 18, left: 2, right: 2),
                child: Icon(Icons.arrow_forward_rounded, color: cor, size: 20),
              ),
            Flexible(child: _Mini(quadros[i], cor)),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.quadro, this.cor);

  final _Quadro quadro;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    const celula = 15.0;
    final linhas = quadro.grade.length, colunas = quadro.grade.first.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Cores.painel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: quadro.depois ? Cores.ouro : cor.withValues(alpha: 0.7), width: 1.5),
          ),
          child: SizedBox(
            width: colunas * celula,
            height: linhas * celula,
            child: CustomPaint(painter: _PintorMini(quadro.grade, cor)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t(quadro.legenda),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, height: 1.15, color: quadro.depois ? Cores.ouro : Cores.textoFraco),
        ),
      ],
    );
  }
}

class _PintorMini extends CustomPainter {
  _PintorMini(this.grade, this.cor);

  final _Grade grade;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / grade.first.length;
    for (var l = 0; l < grade.length; l++) {
      for (var k = 0; k < grade[l].length; k++) {
        final r = Rect.fromLTWH(k * c + 0.5, l * c + 0.5, c - 1, c - 1);
        final ch = grade[l][k];
        if (ch == '.') {
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Cores.casa);
        } else if (ch == '?') {
          // A peça que vai encaixar: bloco meio transparente com contorno branco.
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Cores.casa);
          pintarBloco(canvas, r, Cores.pecas[3], opacidade: 0.6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(3)),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.white,
          );
        } else if (ch == 'S') {
          pintarCasa(canvas, r, Tabuleiro.pedra);
        } else {
          pintarCasa(canvas, r, int.parse(ch));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PintorMini antigo) => false;
}
