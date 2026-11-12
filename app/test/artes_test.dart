import 'package:encaixa/tema.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// Ícone e imagem de destaque da Play Store, com o mesmo desenho do jogo.
/// Gere com: flutter test test/artes_test.dart --dart-define=CAPTURAS=true (salva em docs/artes)
void main() {
  setUpAll(carregarFontes);

  Future<void> desenhar(WidgetTester tester, Size tamanho, Widget arte, String nome) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = tamanho;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(appDeTeste(await servicosDeTeste(), tela: Material(type: MaterialType.transparency, child: arte)));
    await tester.pump();
    await capturar(tester, nome, pasta: '../docs/artes');
  }

  testWidgets('ícone 512', (tester) async {
    await desenhar(
      tester,
      const Size(512, 512),
      const DecoratedBox(
        decoration: BoxDecoration(gradient: Cores.fundo),
        child: CustomPaint(painter: _Icone(), size: Size.infinite),
      ),
      'icone-512',
    );
  });

  // Frente do ícone adaptativo (fundo transparente; a área segura é o círculo de 66% do centro).
  testWidgets('ícone adaptativo (frente) 432', (tester) async {
    await desenhar(
      tester,
      const Size(432, 432),
      const Padding(padding: EdgeInsets.all(56), child: CustomPaint(painter: _Icone(), size: Size.infinite)),
      'icone-adaptativo-frente',
    );
  });

  testWidgets('imagem de destaque 1024x500', (tester) async {
    await desenhar(
      tester,
      const Size(1024, 500),
      const DecoratedBox(
        decoration: BoxDecoration(gradient: Cores.fundo),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _Pilha())),
            Align(
              alignment: Alignment(-0.75, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Logo(tamanho: 96),
                  SizedBox(height: 12),
                  Text(
                    'Encaixe. Limpe. Combine as cores.',
                    style: TextStyle(fontSize: 30, color: Cores.texto, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      'destaque-1024x500',
    );
  });
}

/// Peça em "T" centralizada, com margem para o recorte redondo do Android.
class _Icone extends CustomPainter {
  const _Icone();

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.width * 0.22;
    final x = (s.width - 3 * c) / 2, y = (s.height - 2 * c) / 2;
    pintarBloco(canvas, Rect.fromLTWH(x, y, c, c), Cores.blocos[0]);
    pintarBloco(canvas, Rect.fromLTWH(x + c, y, c, c), Cores.blocos[2]);
    pintarBloco(canvas, Rect.fromLTWH(x + 2 * c, y, c, c), Cores.blocos[4]);
    pintarBloco(canvas, Rect.fromLTWH(x + c, y + c, c, c), Cores.blocos[5]);
  }

  @override
  bool shouldRepaint(_Icone antigo) => false;
}

/// Blocos empilhados no lado direito da imagem de destaque.
class _Pilha extends CustomPainter {
  const _Pilha();

  @override
  void paint(Canvas canvas, Size s) {
    const desenho = ['....3', '...33', '.2224', '11.44', '15554'];
    final c = s.height / 6.5;
    final x0 = s.width - c * 5.6, y0 = s.height - c * 5.3;
    for (var l = 0; l < desenho.length; l++) {
      for (var k = 0; k < 5; k++) {
        final ch = desenho[l][k];
        if (ch == '.') continue;
        pintarBloco(canvas, Rect.fromLTWH(x0 + k * c, y0 + l * c, c * 0.94, c * 0.94), Cores.blocos[int.parse(ch)]);
      }
    }
  }

  @override
  bool shouldRepaint(_Pilha antigo) => false;
}
