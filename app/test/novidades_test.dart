import 'package:encaixa/jogo/amigo.dart';
import 'package:encaixa/jogo/conquistas.dart';
import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/telas/conquistas_tela.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/tema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaDeExemplo;

void main() {
  setUpAll(carregarFontes);
  tearDown(() => Cores.simbolos = false);

  group('desafio de amigo', () {
    test('código vai e volta, inclusive no meio de uma mensagem', () {
      final d = DesafioAmigo(semente: DateTime(2026, 11, 23).microsecondsSinceEpoch, pontos: 4200, infinito: true);
      final volta = DesafioAmigo.ler('Fiz 4200 no Encaixa! Cole:\n${d.codigo}\nbora?')!;
      expect(volta.semente, d.semente);
      expect(volta.pontos, 4200);
      expect(volta.infinito, isTrue);
      expect(DesafioAmigo.ler(d.codigo.toUpperCase())!.semente, d.semente, reason: 'maiúsculas e minúsculas');
    });

    test('texto sem código ou com código quebrado dá null', () {
      expect(DesafioAmigo.ler('oi, tudo bem?'), isNull);
      expect(DesafioAmigo.ler('ENCAIXA-AMIGO-zzz'), isNull);
      expect(DesafioAmigo.ler('ENCAIXA-AMIGO-0-100-f'), isNull, reason: 'semente 0 não vale');
      expect(DesafioAmigo.ler('ENCAIXA-AMIGO-abc-99999999999-f'), isNull);
    });

    test('a mesma semente dá a mesma mão inicial (e a semente fica na partida salva)', () {
      final a = Partida(semente: 12345), b = Partida(semente: 12345);
      expect(a.mao.map((p) => p?.cor).toList(), b.mao.map((p) => p?.cor).toList());
      expect(Partida.deJson(a.paraJson()).semente, 12345);
    });

    test('vencer paga gemas uma vez por desafio; perder ou empatar não paga', () async {
      final s = await servicosDeTeste(valores: {'gemas': 0});
      final p = s.progresso;
      const d = DesafioAmigo(semente: 777, pontos: 1000);
      expect(await p.concluirDesafioDeAmigo(d, 1000), 0, reason: 'empate');
      expect(await p.concluirDesafioDeAmigo(d, 900), 0);
      expect(await p.concluirDesafioDeAmigo(d, 1001), gemasPorVencerAmigo);
      expect(await p.concluirDesafioDeAmigo(d, 5000), 0, reason: 'já ganhou deste desafio');
      expect(p.gemas, gemasPorVencerAmigo);
      expect(p.estatisticas.amigosVencidos, 1);
    });
  });

  group('conquistas', () {
    test('ids únicos e metas positivas', () {
      final ids = Conquista.todas.map((c) => c.id).toSet();
      expect(ids.length, Conquista.todas.length);
      expect(Conquista.todas.every((c) => c.meta > 0 && c.gemas > 0), isTrue);
    });

    test('registrar jogada guarda o máximo; pegar paga uma vez só', () async {
      final s = await servicosDeTeste(valores: {'gemas': 0});
      final p = s.progresso;
      await p.registrarJogada(linhas: 2, combo: 1);
      await p.registrarJogada(linhas: 1, combo: 4);
      expect(p.estatisticas.linhasMax, 2);
      expect(p.estatisticas.comboMax, 4);
      expect(p.conquistasProntas, 2, reason: 'linhas-2 e combo-3 (partida-1 não: ainda 0 partidas)');
    });

    test('conquista alcançada vira "pronta" e o prêmio sai uma vez', () async {
      final s = await servicosDeTeste(valores: {'gemas': 0, 'partidas': 1});
      final p = s.progresso;
      expect(p.conquistasProntas, 1);
      expect(await p.pegarConquista('partida-50'), 0, reason: 'ainda não alcançou');
      expect(await p.pegarConquista('partida-1'), 5);
      expect(await p.pegarConquista('partida-1'), 0, reason: 'só uma vez');
      expect(p.conquistasProntas, 0);
      expect(p.gemas, 5);
    });

    test('sequência máxima e desafios feitos sobem ao concluir o Desafio', () async {
      final s = await servicosDeTeste(valores: {'sequencia': 2, 'desafioFeito': 20261111});
      await s.progresso.concluirDesafio(20261112, 100);
      expect(s.progresso.estatisticas.sequenciaMax, 3);
      expect(s.progresso.estatisticas.desafios, 1);
    });

    test('as novas chaves vão no código de progresso', () {
      for (final k in ['sequenciaMax', 'desafiosTotal', 'linhasMax', 'comboMax', 'amigosVencidos']) {
        expect(CodigoProgresso.vai(k), isTrue, reason: k);
      }
      for (final k in ['conquistas', 'amigosFeitos', 'simbolos']) {
        expect(CodigoProgresso.vai(k), isTrue, reason: k);
      }
    });

    testWidgets('tela de conquistas (e com fonte grande)', (tester) async {
      for (final (fonte, nome) in [(1.0, '29-conquistas'), (1.5, '30-conquistas-fonte-grande')]) {
        telaDeCelular(tester, tamanho: const Size(360, 800), fonte: fonte);
        final s = await servicosDeTeste(
          valores: {
            'partidas': 60,
            'recorde': 5400,
            'linhasMax': 3,
            'comboMax': 2,
            'faseLiberada': 14,
            'conquistas': ['partida-1'],
          },
        );
        await tester.pumpWidget(appDeTeste(s, tela: ConquistasTela(servicos: s)));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Conquistas'), findsWidgets);
        expect(tester.takeException(), isNull);
        await capturar(tester, nome);
        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('símbolos para daltônicos', () {
    test('o interruptor guarda e liga o desenho', () async {
      final s = await servicosDeTeste();
      expect(Cores.simbolos, isFalse);
      await s.progresso.alternarSimbolos();
      expect(s.progresso.simbolos, isTrue);
      expect(Cores.simbolos, isTrue);
      await s.progresso.alternarSimbolos();
      expect(Cores.simbolos, isFalse);
    });

    testWidgets('partida com símbolos ligados (visual)', (tester) async {
      telaDeCelular(tester, tamanho: const Size(360, 800));
      final s = await servicosDeTeste(valores: {'simbolos': true});
      expect(Cores.simbolos, isTrue);
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: JogoTela(servicos: s, partida: partidaDeExemplo()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await capturar(tester, '31-simbolos');
    });

    testWidgets('interruptor na tela Como jogar', (tester) async {
      telaDeCelular(tester, tamanho: const Size(360, 800));
      final s = await servicosDeTeste();
      await tester.pumpWidget(appDeTeste(s, tela: AjudaTela(servicos: s)));
      await tester.pump();
      expect(find.text('Símbolos nas peças'), findsOneWidget);
      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(s.progresso.simbolos, isTrue);
    });
  });

  testWidgets('desafio de amigo na tela: mostra a pontuação do amigo e a mesma mão', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    const amigo = DesafioAmigo(semente: 424242, pontos: 3000);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, amigo: amigo),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('AMIGO: 3000'), findsOneWidget);
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela));
    final partida = (estado as dynamic).partidaParaTeste as Partida;
    expect(partida.semente, 424242);
    expect(partida.mao.map((p) => p?.cor).toList(), Partida(semente: 424242).mao.map((p) => p?.cor).toList());
    expect(tester.takeException(), isNull);
    await capturar(tester, '32-desafio-de-amigo');
  });
}
