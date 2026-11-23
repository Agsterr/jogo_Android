import 'package:encaixa/jogo/passe.dart';
import 'package:encaixa/jogo/temas.dart';
import 'package:encaixa/telas/passe_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('nível pelo XP e total da trilha', () {
    expect(nivelDoPasse(0), 0);
    expect(nivelDoPasse(99), 0);
    expect(nivelDoPasse(100), 1);
    expect(nivelDoPasse(1999), 19);
    expect(nivelDoPasse(2000), 20);
    expect(nivelDoPasse(99999), niveisDoPasse, reason: 'não passa do último nível');
    expect(totalDoPasse(assinante: false), 16 * 10 + 4 * 30);
    expect(totalDoPasse(assinante: true), 2 * totalDoPasse(assinante: false));
    expect(nomeDoMes(202611), 'novembro');
    expect(nomeDoMes(202601), 'janeiro');
  });

  test('XP sobe com Desafio e baú, resgatar paga uma vez e o assinante recebe o dobro', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final p = s.progresso;
    const dia = 20261112;
    await p.ganharXpDoPasse(dia, 250);
    expect(p.passeNivel(dia), 2);
    expect(p.passeProntos(dia), 2);
    expect(await p.pegarNivelDoPasse(dia, 3), 0, reason: 'ainda não chegou ao nível 3');
    expect(await p.pegarNivelDoPasse(dia, 1), 10);
    expect(await p.pegarNivelDoPasse(dia, 1), 0, reason: 'só uma vez');
    expect(p.passeProntos(dia), 1);
    await p.definirAssinante(true);
    expect(await p.pegarNivelDoPasse(dia, 2), 20, reason: 'Encaixa+ recebe o dobro');
    expect(p.gemas, 30);
  });

  test('Desafio dá 40 XP e o baú 30; só as 10 primeiras partidas do dia dão XP', () async {
    final s = await servicosDeTeste();
    final p = s.progresso;
    await p.concluirDesafio(20261112, 100);
    expect(p.passeXp(20261112), XpDoPasse.desafio);
    for (var i = 0; i < 15; i++) {
      await p.ganharXpDaPartida(20261112);
    }
    expect(p.passeXp(20261112), XpDoPasse.desafio + 10 * XpDoPasse.partida);
    await p.ganharXpDaPartida(20261113);
    expect(p.passeXp(20261113), XpDoPasse.desafio + 11 * XpDoPasse.partida, reason: 'novo dia, novas 10 partidas');
  });

  test('o passe recomeça quando o mês vira', () async {
    final s = await servicosDeTeste();
    final p = s.progresso;
    await p.ganharXpDoPasse(20261130, 500);
    expect(p.passeNivel(20261130), 5);
    expect(p.passeNivel(20261201), 0, reason: 'dezembro: trilha nova');
    await p.ganharXpDoPasse(20261201, 100);
    expect(p.passeNivel(20261201), 1);
    expect(p.passePegos(20261201), isEmpty);
  });

  test('nível 20 libera o tema Aurora para sempre', () async {
    final s = await servicosDeTeste(valores: {'passeMes': 202611, 'passeXp': 2000});
    final p = s.progresso;
    final aurora = TemaDeBlocos.todos.firstWhere((t) => t.passe);
    expect(p.temTema(aurora), isFalse);
    expect(await p.pegarNivelDoPasse(20261112, niveisDoPasse), 30);
    expect(p.temTema(aurora), isTrue);
    expect(p.passeNivel(20261201), 0);
    expect(p.temTema(aurora), isTrue, reason: 'continua no mês seguinte');
  });

  testWidgets('tela do passe (e com fonte grande)', (tester) async {
    for (final (fonte, nome) in [(1.0, '35-passe'), (1.5, '36-passe-fonte-grande')]) {
      telaDeCelular(tester, tamanho: const Size(360, 800), fonte: fonte);
      final s = await servicosDeTeste(
        valores: {
          'passeMes': 202611,
          'passeXp': 740,
          'passePegos': ['1', '2', '3'],
        },
      );
      await tester.pumpWidget(appDeTeste(s, tela: PasseTela(servicos: s)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Passe de novembro'), findsWidgets);
      expect(find.text('Nível 7 de 20'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturar(tester, nome);
      await tester.tap(find.text('Pegar').first);
      await tester.pump();
      expect(s.progresso.passePegos(20261112), contains(4));
      await tester.pumpWidget(const SizedBox());
    }
  });
}
