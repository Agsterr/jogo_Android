import 'package:encaixa/telas/estatisticas_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('guarda as últimas 10 partidas, linhas e jogadas', () async {
    final s = await servicosDeTeste();
    final p = s.progresso;
    for (var i = 1; i <= 12; i++) {
      await p.fimDePartida(i * 100);
    }
    expect(p.ultimasPartidas, [for (var i = 3; i <= 12; i++) i * 100]);
    await p.registrarJogada(linhas: 2, combo: 1);
    await p.registrarJogada(linhas: 0, combo: 0);
    await p.registrarJogada(linhas: 3, combo: 2);
    expect(p.linhasTotal, 5);
    expect(p.jogadasTotal, 3);
  });

  testWidgets('tela de estatísticas vazia e cheia', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final vazio = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(vazio, tela: EstatisticasTela(servicos: vazio)));
    await tester.pumpAndSettle();
    expect(find.text('Jogue uma partida para ver o gráfico'), findsOneWidget);

    final s = await servicosDeTeste(
      valores: {
        'partidas': 42,
        'recorde': 9120,
        'linhasTotal': 530,
        'jogadasTotal': 1210,
        'comboMax': 7,
        'linhasMax': 4,
        'sequenciaMax': 12,
        'ultimas': ['1200', '3400', '2100', '5600', '800', '4300', '7700', '9120', '3000', '6100'],
      },
    );
    await tester.pumpWidget(appDeTeste(s, tela: EstatisticasTela(servicos: s)));
    await tester.pumpAndSettle();
    expect(find.text('530'), findsOneWidget);
    expect(find.text('x7'), findsOneWidget);
    await capturar(tester, '55-estatisticas');
    expect(tester.takeException(), isNull);
  });
}
