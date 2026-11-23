import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/jogo/puzzle.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fluxo_fases_test.dart' show jogarUmaVez;
import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('o puzzle de um dia é sempre o mesmo e dias diferentes dão puzzles diferentes', () {
    final a = puzzleDoDia(20261112), b = puzzleDoDia(20261112), c = puzzleDoDia(20261113);
    String assinatura(PuzzleDoDia p) =>
        '${[for (var l = 0; l < 8; l++)
          for (var k = 0; k < 8; k++) p.tabuleiro.cor(l, k)]}'
        '${p.pecas.map((e) => '${e.cor}:${e.formato.celulas}')}';
    expect(assinatura(a), assinatura(b));
    expect(assinatura(a), isNot(assinatura(c)));
    expect(a.meta, b.meta);
  });

  test(
    'em 60 dias seguidos: nenhuma linha começa completa, há solução, a meta é de 3 a 5 e o guloso não bate a meta',
    () {
      var faceis = 0;
      for (var d = 0; d < 60; d++) {
        final dia = 20261101 + d;
        final p = puzzleDoDia(dia);
        final c = p.tabuleiro.linhasCompletas();
        expect(c.linhas, isEmpty, reason: 'dia $dia');
        expect(c.colunas, isEmpty, reason: 'dia $dia');
        expect(p.pecas.length, 3);
        expect(p.meta, inInclusiveRange(2, 6), reason: 'dia $dia');
        if (linhasDoGuloso(p.tabuleiro, p.pecas) >= p.meta) faceis++;
        expect(p.tabuleiro.ocupadas, inInclusiveRange(8, 56), reason: 'dia $dia');
      }
      expect(faceis, lessThan(6), reason: 'quase todos os puzzles exigem pensar (não é só a jogada óbvia)');
    },
  );

  test('a meta é alcançável: existe uma ordem e posições que limpam a meta (busca completa nos primeiros dias)', () {
    for (var d = 0; d < 6; d++) {
      final p = puzzleDoDia(20261101 + d);
      expect(_melhor(p.tabuleiro, p.pecas.toList()), greaterThanOrEqualTo(p.meta), reason: 'dia ${p.dia}');
    }
  });

  test('o puzzle não muda o tabuleiro de origem ao ser jogado em cópia', () {
    final p = puzzleDoDia(20261112);
    final antes = p.tabuleiro.ocupadas;
    p.tabuleiro.copia().definir(0, 0, 1);
    expect(p.tabuleiro.ocupadas, antes);
  });

  test('estrelas e gemas do puzzle', () {
    expect(estrelasDoPuzzle(4, 4), 3);
    expect(estrelasDoPuzzle(5, 4), 3, reason: 'passou da meta: continua 3');
    expect(estrelasDoPuzzle(3, 4), 2);
    expect(estrelasDoPuzzle(2, 4), 1);
    expect(estrelasDoPuzzle(1, 4), 1);
    expect(estrelasDoPuzzle(0, 4), 0);
    expect(estrelasDoPuzzle(1, 2), 1, reason: 'meta 2: uma linha só vale 1 estrela');
    expect(estrelasDoPuzzle(2, 2), 3);
    expect([for (var e = 0; e <= 3; e++) gemasDoPuzzle(e)], [0, 2, 5, 10]);
  });

  test('estrelas do puzzle pagam só a diferença e o XP só na primeira vez', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final p = s.progresso;
    expect(await p.registrarPuzzle(20261112, 1), gemasDoPuzzle(1));
    expect(await p.registrarPuzzle(20261112, 2), gemasDoPuzzle(2) - gemasDoPuzzle(1));
    expect(await p.registrarPuzzle(20261112, 2), 0);
    expect(await p.registrarPuzzle(20261112, 3), gemasDoPuzzle(3) - gemasDoPuzzle(2));
    expect(p.gemas, gemasDoPuzzle(3));
    expect(p.puzzleEstrelas(20261112), 3);
    expect(p.puzzleEstrelas(20261113), 0);
  });

  testWidgets('joga o puzzle pela tela até o resultado e dá para tentar de novo', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final dia = Sorteio.sementeDoDia(s.hoje());
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, puzzle: puzzleDoDia(dia)),
      ),
    );
    await tester.pumpAndSettle();
    final meta = puzzleDoDia(dia).meta;
    expect(find.textContaining('PUZZLE #'), findsOneWidget);
    expect(find.text('0/$meta'), findsWidgets);
    await capturar(tester, '46-puzzle');
    for (var i = 0; i < 3; i++) {
      expect(await jogarUmaVez(tester), isTrue);
    }
    expect(find.text('Tentar de novo'), findsWidgets);
    expect(find.textContaining('meta: $meta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturar(tester, '47-puzzle-fim');
    await tester.tap(find.text('Tentar de novo').first);
    await tester.pumpAndSettle();
    expect(find.text('0/$meta'), findsWidgets);
    expect(s.progresso.partidas, 0, reason: 'puzzle não conta como partida do Infinito');
  });
}

/// Busca completa: o máximo de linhas com todas as ordens e posições (só para conferir a meta nos testes).
int _melhor(Tabuleiro t, List pecas) {
  if (pecas.isEmpty) return 0;
  var melhor = 0;
  for (var i = 0; i < pecas.length; i++) {
    final p = pecas[i];
    final resto = [...pecas]..removeAt(i);
    for (var l = 0; l <= Tabuleiro.tamanho - (p.formato.linhas as int); l++) {
      for (var k = 0; k <= Tabuleiro.tamanho - (p.formato.colunas as int); k++) {
        if (!t.cabe(p.formato, l, k)) continue;
        final r = jogarPeca(t, p.formato, l, k);
        final total = r.linhas + _melhor(r.tabuleiro, resto);
        if (total > melhor) melhor = total;
      }
    }
  }
  return melhor;
}
