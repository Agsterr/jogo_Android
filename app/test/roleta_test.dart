import 'package:encaixa/jogo/roleta.dart';
import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaSemEspaco;

void main() {
  setUpAll(carregarFontes);

  test('roleta tem prêmios ruins e bons, e o raro sai pouco', () {
    expect(Roleta.premios, contains(0));
    expect(Roleta.rotulo(Roleta.premios.indexOf(0)), 'Nada');
    final s = Sorteio(42);
    final saidas = List.generate(2000, (_) => Roleta.premios[Roleta.sortear(s)]);
    expect(saidas.where((p) => p == 0).length, greaterThan(500), reason: '"Nada" é comum');
    expect(saidas.where((p) => p == 25).length, lessThan(60), reason: '+25 é raro');
  });

  testWidgets('fim de partida abre a roleta; girar de novo pede anúncio; depois mostra o resultado', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 0, 'recorde': 99999}, roleta: true);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaSemEspaco()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Não, obrigado'));
    await tester.pumpAndSettle();
    expect(find.text('Roleta da partida'), findsWidgets);
    await capturar(tester, '24-roleta-partida');

    await tester.tap(find.text('GIRAR').first);
    await tester.pumpAndSettle();
    final depoisDoPrimeiro = s.progresso.gemas;
    expect(find.text('GIRAR DE NOVO'), findsWidgets, reason: 'segundo giro pede anúncio');
    await capturar(tester, '25-roleta-premio');

    await tester.tap(find.text('GIRAR DE NOVO').first); // nos testes o anúncio "assiste" na hora
    await tester.pumpAndSettle();
    expect(s.progresso.gemas, greaterThanOrEqualTo(depoisDoPrimeiro));
    await tester.tap(find.text('GIRAR DE NOVO').first);
    await tester.pumpAndSettle();
    expect(find.text('GIRAR DE NOVO'), findsNothing, reason: 'só 2 giros extras');

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Roleta da partida'), findsNothing);
    expect(find.text('Fim de jogo'), findsWidgets);
  });
}
