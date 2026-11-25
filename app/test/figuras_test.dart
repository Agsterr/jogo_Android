import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/figuras.dart';
import 'package:encaixa/telas/mapa_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fluxo_fases_test.dart' show jogarPelaTela;
import 'suporte/capturas.dart';

import 'package:encaixa/telas/jogo_tela.dart';

void main() {
  setUpAll(carregarFontes);

  test('há uma figura por mundo e todas são 10x8 com cores definidas', () {
    expect(Figura.todas.length, Fase.mundos.length);
    for (final f in Figura.todas) {
      expect(f.linhas.length, Figura.altura, reason: f.nome);
      for (final l in f.linhas) {
        expect(l.length, Figura.colunas, reason: '${f.nome}: $l');
        for (final c in l.split('')) {
          if (c != '.') expect(f.paleta.containsKey(c), isTrue, reason: '${f.nome}: letra $c sem cor');
        }
      }
      expect(f.comBloco.length, inInclusiveRange(10, 20), reason: '${f.nome}: figura pequena demais');
    }
  });

  test('o desenho aparece aos poucos, só com pedaços que têm bloco, e fica inteiro na 20ª fase', () {
    for (final f in Figura.todas) {
      expect(f.visiveis(0), isEmpty, reason: f.nome);
      expect(f.visiveis(20).length, f.comBloco.length, reason: f.nome);
      var anterior = 0;
      for (var n = 1; n <= 20; n++) {
        final agora = f.visiveis(n).length;
        expect(agora - anterior, inInclusiveRange(0, 1), reason: '${f.nome} fase $n');
        expect(f.novos(n).length, agora - anterior);
        anterior = agora;
      }
    }
    expect(Figura.posicaoNoMundo(21), 1);
    expect(Figura.mundoDaFase(21), 1);
    expect(Figura.feitasNoMundo(0, (n) => n <= 7 ? 3 : 0), 7);
    expect(Figura.feitasNoMundo(1, (n) => n <= 7 ? 3 : 0), 0);
  });

  testWidgets('mapa mostra a figura do mundo com pedaços revelados', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 780));
    final s = await servicosDeTeste(valores: {'faseLiberada': 14, for (var n = 1; n <= 13; n++) 'estrelas_$n': 2});
    await tester.pumpWidget(appDeTeste(s, tela: MapaTela(servicos: s)));
    await tester.pump(const Duration(seconds: 1));
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 4000));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('13/20'), findsOneWidget);
    await capturar(tester, '53-mapa-figura');
    expect(tester.takeException(), isNull);
  });

  testWidgets('vencer o chefe pela primeira vez completa a figura e dá um baú', (tester) async {
    final s = await servicosDeTeste(valores: {'faseLiberada': 20, for (var n = 1; n <= 19; n++) 'estrelas_$n': 1});
    final antes = s.progresso.baus;
    await s.progresso.concluirFase(20, 2);
    expect(s.progresso.baus, antes + 1);
    await s.progresso.concluirFase(20, 3);
    expect(s.progresso.baus, antes + 1, reason: 'só na primeira vez');
    await s.progresso.concluirFase(5, 3);
    expect(s.progresso.baus, antes + 1);
  });

  testWidgets('fase vencida mostra a figura com o pedaço novo', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 780));
    final s = await servicosDeTeste();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: Fase.numero(1)),
      ),
    );
    await tester.pumpAndSettle();
    await jogarPelaTela(tester);
    expect(find.text('Fase 1 concluída!'), findsOneWidget);
    expect(s.progresso.rodadas, 1, reason: 'fase vencida conta como rodada para a política de anúncios');
    expect(s.progresso.partidas, 0);
    await capturar(tester, '54-fase-figura');
    expect(tester.takeException(), isNull);
  });
}
