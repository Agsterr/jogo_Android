import 'package:encaixa/jogo/duelo.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fluxo_fases_test.dart' show jogarUmaVez;
import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('regras do duelo: vencedor, vez do jogador 2 e semente válida', () {
    expect(Duelo.vencedor(100, 50), 1);
    expect(Duelo.vencedor(50, 100), 2);
    expect(Duelo.vencedor(70, 70), 0);
    final d = Duelo.novo(DateTime(2026, 11, 23, 10));
    expect(d.semente, greaterThan(0));
    expect(d.jogador, 1);
    final v2 = d.vezDoJogador2(321);
    expect((v2.semente, v2.jogador, v2.pontosJ1), (d.semente, 2, 321));
  });

  testWidgets('os dois jogadores jogam com as mesmas peças, o resultado compara e nada vale gemas ou recorde', (
    tester,
  ) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final duelo = Duelo(semente: 4242);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, duelo: duelo),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOGADOR 1'), findsOneWidget);
    final mao1 = (tester.state<State<JogoTela>>(find.byType(JogoTela)) as dynamic).partidaParaTeste.mao
        .map((p) => p?.formato.celulas.length)
        .toList();
    await capturar(tester, '57-duelo');
    for (var i = 0; i < 300 && find.text('Passar para o Jogador 2').evaluate().isEmpty; i++) {
      if (!await jogarUmaVez(tester)) break;
    }
    expect(find.text('Passar para o Jogador 2'), findsWidgets);
    await capturar(tester, '58-duelo-vez-do-2');

    // Jogador 2 (a tela troca por uma nova, com as mesmas peças).
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(key: UniqueKey(), servicos: s, duelo: duelo.vezDoJogador2(120)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('JOGADOR 2'), findsOneWidget);
    final mao2 = (tester.state<State<JogoTela>>(find.byType(JogoTela)) as dynamic).partidaParaTeste.mao
        .map((p) => p?.formato.celulas.length)
        .toList();
    expect(mao2, mao1, reason: 'mesmas peças nas duas vezes');
    for (var i = 0; i < 300 && find.text('Revanche').evaluate().isEmpty; i++) {
      if (!await jogarUmaVez(tester)) break;
    }
    expect(find.text('Revanche'), findsWidgets);
    expect(find.textContaining('venceu').evaluate().isNotEmpty || find.text('Empate!').evaluate().isNotEmpty, isTrue);
    await capturar(tester, '59-duelo-resultado');
    expect(s.progresso.gemas, 0);
    expect(s.progresso.partidas, 0);
    expect(tester.takeException(), isNull);
  });
}
