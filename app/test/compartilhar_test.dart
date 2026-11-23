import 'dart:typed_data';

import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:encaixa/widgets/cartao_de_pontos.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

Tabuleiro _tabuleiroDeExemplo() {
  final t = Tabuleiro();
  for (var l = 3; l < 8; l++) {
    for (var k = 0; k < 8; k++) {
      if ((l * 3 + k * 5) % 7 != 0) t.definir(l, k, (l + k) % 6);
    }
  }
  t.definir(2, 4, Tabuleiro.pedra);
  return t;
}

void main() {
  setUpAll(carregarFontes);

  testWidgets('o cartão de compartilhar vira um PNG de 1080x1350', (tester) async {
    final cartao = CartaoDePontos(
      tabuleiro: _tabuleiroDeExemplo(),
      destaque: '4820',
      titulo: 'Desafio #12',
      detalhe: '31 linhas · Combo x5',
    );
    final Uint8List png = (await tester.runAsync(cartao.png))!;
    expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], reason: 'assinatura de PNG');
    expect(png.length, greaterThan(20000));
    final imagem = (await tester.runAsync(() => decodeImageFromList(png)))!;
    expect((imagem.width, imagem.height), (1080, 1350));
  });

  testWidgets('o cartão de compartilhar (visual)', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 450));
    await tester.pumpWidget(
      appDeTeste(
        await servicosDeTeste(),
        tela: Scaffold(
          body: SizedBox.expand(
            child: CustomPaint(
              painter: CartaoDePontos(
                tabuleiro: _tabuleiroDeExemplo(),
                destaque: '4820',
                titulo: 'Desafio #12',
                detalhe: '31 linhas · Combo x5',
              ),
            ),
          ),
        ),
      ),
    );
    await capturar(tester, '56-cartao-compartilhar');
  });
}
