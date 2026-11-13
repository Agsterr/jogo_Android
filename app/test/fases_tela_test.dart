import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/telas/mapa_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  final progressoNoMeio = <String, Object>{
    'gemas': 42,
    'faseLiberada': 13,
    for (var n = 1; n < 13; n++) 'estrelas_$n': [3, 2, 3, 1][n % 4],
  };

  testWidgets('mapa mostra estrelas, fase atual e cadeados', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: progressoNoMeio);
    await tester.pumpWidget(appDeTeste(s, tela: MapaTela(servicos: s)));
    await tester.pump();
    expect(find.text('13'), findsWidgets);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    await capturar(tester, '9-mapa');
  });

  testWidgets('fase de pedras: objetivo, peças e vitória', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: progressoNoMeio);
    final fase = Fase.numero(4);
    expect(fase.objetivo, Objetivo.pedras);
    final partida = fase.novaPartida();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase, partida: partida),
      ),
    );
    await tester.pump();
    expect(find.text(fase.texto), findsOneWidget);
    expect(find.text('Peças: ${fase.pecas}'), findsOneWidget);
    await capturar(tester, '10-fase-pedras');
  });

  testWidgets('vencer a fase dá estrelas e libera a próxima', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: progressoNoMeio);
    final fase = Fase.numero(13); // pontos
    final partida = fase.novaPartida()
      ..pontos = fase.alvo - 1
      ..mao = [
        Peca(Formato.desenho(['#']), 2),
        null,
        null,
      ];
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase, partida: partida),
      ),
    );
    await tester.pump();
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveBy(const Offset(0, -260));
    await gesto.up();
    await tester.pumpAndSettle();
    expect(find.text('Fase 13 concluída!'), findsOneWidget);
    expect(s.progresso.faseLiberada, 14);
    expect(s.progresso.estrelasDaFase(13), 3);
    await capturar(tester, '11-fase-vencida');
  });

  testWidgets('sem peças oferece +5 peças', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 20});
    final fase = Fase.numero(7); // linhas
    final partida = fase.novaPartida()
      ..jogadas = fase.pecas - 1
      ..mao = [
        Peca(Formato.desenho(['#']), 2),
        null,
        null,
      ];
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase, partida: partida),
      ),
    );
    await tester.pump();
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveBy(const Offset(0, -260));
    await gesto.up();
    await tester.pump();
    expect(find.text('Acabaram as peças!'), findsOneWidget);
    await capturar(tester, '12-fase-sem-pecas');
    await tester.tap(find.text('Usar 10 gemas'));
    await tester.pump();
    expect(find.text('Peças: 5'), findsOneWidget);
    expect(s.progresso.gemas, 10);
  });

  testWidgets('fases novas: uma cor (3 cores) e avançada com pedras e blocos soltos', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 42});
    for (final (n, nome) in [(14, '20-fase-uma-cor'), (121, '21-fase-galaxia')]) {
      final fase = Fase.numero(n);
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: JogoTela(key: ValueKey(n), servicos: s, fase: fase),
        ),
      );
      await tester.pump();
      expect(find.text(fase.texto), findsOneWidget);
      await capturar(tester, nome);
    }
  });

  testWidgets('ajuda "abrir espaço" não quebra a pedra nem vence a fase', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 20});
    final fase = Fase.numero(4); // pedras
    final partida = fase.novaPartida();
    final pedras = partida.tabuleiro.pedras;
    for (var l = 0; l < 8; l++) {
      for (var k = 0; k < 8; k++) {
        if ((l + k).isOdd && partida.tabuleiro.cor(l, k) == null) partida.tabuleiro.definir(l, k, 1);
      }
    }
    partida.mao = [
      Peca(Formato.desenho(['##', '##']), 2),
      null,
      null,
    ];
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase, partida: partida),
      ),
    );
    await tester.pump();
    expect(find.text('Sem espaço!'), findsOneWidget);
    await tester.tap(find.text('Usar 10 gemas').first);
    await tester.pump();
    expect(partida.tabuleiro.pedras, pedras, reason: 'nenhuma pedra some com a ajuda');
    expect(fase.concluida(partida), isFalse);
    expect(find.textContaining('concluída'), findsNothing);
  });
}
