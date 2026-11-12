import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fluxo_fases_test.dart' show jogarPelaTela, jogarUmaVez;
import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  testWidgets('tutorial da fase 1 acompanha as jogadas e some no fim', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(dicas: true);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: Fase.numero(1)),
      ),
    );
    await tester.pump();
    expect(find.textContaining('arraste até o tabuleiro'), findsOneWidget);
    await capturar(tester, '16-tutorial');
    // Primeira jogada: o balão passa para "encha uma linha".
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela)) as dynamic;
    estado.partidaParaTeste.tabuleiro.definir(7, 0, 1);
    await jogarUmaVez(tester);
    expect(find.textContaining('INTEIRA'), findsOneWidget);
    await capturar(tester, '16b-tutorial-linha');
    // Limpar uma linha leva ao último passo (objetivo e estrelas), que espera o ENTENDI.
    for (var i = 0; i < 12 && find.textContaining('Muito bem').evaluate().isEmpty; i++) {
      await jogarUmaVez(tester);
    }
    if (find.textContaining('Muito bem').evaluate().isNotEmpty) {
      await capturar(tester, '16c-tutorial-objetivo');
      await tester.tap(find.text('ENTENDI').first);
      await tester.pumpAndSettle();
    }
    await jogarPelaTela(tester);
    expect(find.byType(BalaoTutorial), findsNothing);
    expect(s.progresso.dicaVista('tutorial'), isTrue);
  });

  testWidgets('dica aparece na primeira vez do Infinito e não na segunda', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(dicas: true);
    await tester.pumpWidget(appDeTeste(s, tela: JogoTela(servicos: s)));
    await tester.pumpAndSettle();
    expect(find.text('Modo Infinito'), findsWidgets);
    await capturar(tester, '17-dica-infinito');
    await tester.tap(find.text('ENTENDI').first);
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(key: UniqueKey(), servicos: s),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Modo Infinito'), findsNothing);
  });

  testWidgets('tela Como jogar', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(s, tela: const AjudaTela()));
    await tester.pump();
    expect(find.text('Como jogar'), findsWidgets);
    await capturar(tester, '18-como-jogar');
  });
}
