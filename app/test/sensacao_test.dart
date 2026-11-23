import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show dedoPara, partidaDeExemplo;

void main() {
  setUpAll(carregarFontes);

  test('a música começa desligada e o interruptor liga e desliga (e vai no código de progresso)', () async {
    final s = await servicosDeTeste();
    expect(s.progresso.musicaLigada, isFalse);
    await s.progresso.alternarMusica();
    expect(s.progresso.musicaLigada, isTrue);
    await s.progresso.alternarMusica();
    expect(s.progresso.musicaLigada, isFalse);
    s.sons.atualizarMusica(); // o dublê de som não faz nada, e não pode quebrar
  });

  testWidgets('interruptor de música na tela Como jogar', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 900));
    final s = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(s, tela: AjudaTela(servicos: s)));
    await tester.pump();
    expect(find.text('Música de fundo'), findsOneWidget);
    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();
    expect(s.progresso.musicaLigada, isTrue);
  });

  testWidgets('limpar linhas faz confete e, nas jogadas fortes, o tabuleiro treme (e some sozinho)', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    final partida = partidaDeExemplo();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partida),
      ),
    );
    await tester.pump();
    final peca = partida.mao[0]!;
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveTo(dedoPara(tester, peca, 6, 5));
    await tester.pump();
    await gesto.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await capturar(tester, '45-confete');
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('quem pediu menos animação no sistema não vê confete nem tremor, e o jogo funciona igual', (
    tester,
  ) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final s = await servicosDeTeste();
    final partida = partidaDeExemplo();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partida),
      ),
    );
    await tester.pump();
    final peca = partida.mao[0]!;
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveTo(dedoPara(tester, peca, 6, 5));
    await tester.pump();
    await gesto.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(partida.pontos, greaterThan(1240));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });
}
