import 'package:encaixa/jogo/missoes.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaDeExemplo;

void main() {
  setUpAll(carregarFontes);

  test('gemas do Relâmpago: 1 a cada 150 pontos, no máximo 15', () {
    expect(gemasDoRelampago(0), 0);
    expect(gemasDoRelampago(149), 0);
    expect(gemasDoRelampago(150), 1);
    expect(gemasDoRelampago(1500), 10);
    expect(gemasDoRelampago(99999), 15);
  });

  test('o recorde do Relâmpago é separado do recorde geral e conta como partida', () async {
    final s = await servicosDeTeste(valores: {'recorde': 9000});
    final p = s.progresso;
    expect(await p.fimDoRelampago(800), isTrue);
    expect(await p.fimDoRelampago(500), isFalse);
    expect(p.relampagoMelhor, 800);
    expect(p.recorde, 9000, reason: 'não mexe no recorde geral');
    expect(p.partidas, 2);
  });

  testWidgets('o tempo só corre depois da primeira jogada e, ao zerar, a partida acaba com prêmio', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final partida = partidaDeExemplo();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partida, relampago: true, duracao: const Duration(seconds: 3)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(' 0:03'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text(' 0:03'), findsOneWidget, reason: 'sem jogada o relógio não anda');
    await capturar(tester, '33-relampago');

    // primeira jogada: o relógio começa
    final caixa = tester.getTopLeft(find.byKey(const ValueKey('mao-0')));
    expect(caixa, isNotNull);
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela));
    (estado as dynamic).iniciarRelogioParaTeste();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(' 0:02'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Tempo esgotado'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsWidgets);
    expect(s.progresso.partidas, 1);
    expect(tester.takeException(), isNull);
    await capturar(tester, '34-relampago-fim');
    await tester.pumpAndSettle();
  });
}
