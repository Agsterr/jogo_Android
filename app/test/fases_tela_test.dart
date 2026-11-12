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
    final fase = Fase.numero(5);
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
    final fase = Fase.numero(6); // linhas
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
}
