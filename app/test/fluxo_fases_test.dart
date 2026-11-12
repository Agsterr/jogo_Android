import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/widgets/tabuleiro_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fases_test.dart' as f;
import 'suporte/capturas.dart';

/// Joga a fase pela tela, arrastando com o dedo, usando a escolha do jogador automático.
Future<void> jogarPelaTela(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    if (find.textContaining('concluída').evaluate().isNotEmpty) return;
    if (find.text('Tentar de novo').evaluate().isNotEmpty) return;
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela));
    final partida = (estado as dynamic).partidaParaTeste;
    final escolha = f.melhorJogada(partida);
    if (escolha == null) return;
    final (indice, linha, coluna) = escolha;
    final peca = partida.mao[indice]!;
    final caixa = tester.renderObject<RenderBox>(find.byType(TabuleiroWidget));
    final casa = caixa.size.width / Tabuleiro.tamanho;
    final alvo =
        caixa.localToGlobal(Offset(coluna * casa, linha * casa)) +
        Offset(peca.formato.colunas * casa / 2, peca.formato.linhas * casa + casa * 1.2);
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(ValueKey('mao-$indice'))));
    await gesto.moveTo(alvo);
    await tester.pump();
    await gesto.up();
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(carregarFontes);

  testWidgets('vence a fase 1 pela tela, vai para a 2 e o mapa libera', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(s));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pump(const Duration(seconds: 1)); // o mapa tem animação contínua (fase atual pulsa)
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('1').first);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('FASE 1'), findsOneWidget);
    await jogarPelaTela(tester);
    expect(find.text('Fase 1 concluída!'), findsOneWidget);
    expect(s.progresso.faseLiberada, 2);
    await tester.tap(find.text('Próxima fase').first);
    await tester.pumpAndSettle();
    expect(find.text('FASE 2'), findsOneWidget);
    expect(find.text(Fase.numero(2).texto), findsOneWidget);
  });
}
