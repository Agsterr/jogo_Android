import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('abrirEspaco: tabuleiro cheio vira jogável de novo e nada de pedra/especial fica preso', () {
    var travados = 0;
    for (var semente = 1; semente <= 30; semente++) {
      final p = Partida(semente: semente);
      // tabuleiro quase cheio, sem nenhuma linha completa (xadrez)
      for (var l = 0; l < 8; l++) {
        for (var k = 0; k < 8; k++) {
          p.tabuleiro.definir(l, k, (l + k) % 2 == 0 ? 0 : null);
        }
      }
      if (!p.fimDeJogo) continue; // mão só com peça de 1 casa cabe no xadrez
      travados++;
      final tirados = p.abrirEspaco();
      expect(tirados, greaterThan(0));
      expect(p.fimDeJogo, isFalse, reason: 'semente $semente');
    }
    expect(travados, greaterThan(15));
  });

  testWidgets('o Zen nunca termina: ao travar abre espaço, sem gemas nem recorde', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final partida = Partida(semente: 7);
    for (var l = 0; l < 8; l++) {
      for (var k = 0; k < 8; k++) {
        partida.tabuleiro.definir(l, k, (l + k) % 2 == 0 ? 0 : null);
      }
    }
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, zen: true, partida: partida),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ZEN'), findsOneWidget);
    expect(find.text('Sem espaço!'), findsNothing, reason: 'partida travada guardada abre espaço sozinha');
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela));
    (estado as dynamic).abrirEspacoParaTeste();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Abrimos espaço!'), findsWidgets);
    expect(partida.fimDeJogo, isFalse);
    expect(s.progresso.gemas, 0);
    await capturar(tester, '48-zen');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
