import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:flutter_test/flutter_test.dart';

final _linha8 = Formato.desenho(['########']);
final _bloco = Formato.desenho(['#']);

/// Preenche a linha [l] menos a última casa, com a cor [cor].
void _quaseCheia(Tabuleiro t, int l, {int cor = 0}) {
  for (var k = 0; k < Tabuleiro.tamanho - 1; k++) {
    t.definir(l, k, cor);
  }
}

void main() {
  test('sorteio é determinístico (Desafio do dia igual para todos)', () {
    final a = Sorteio(20261112), b = Sorteio(20261112);
    final sa = List.generate(50, (_) => a.proximo(1000));
    final sb = List.generate(50, (_) => b.proximo(1000));
    expect(sa, sb);
    expect(sa.toSet().length, greaterThan(40));
    expect(Sorteio.sementeDoDia(DateTime(2026, 11, 12)), 20261112);
  });

  test('mesma semente gera a mesma mão', () {
    String mao(Partida p) => p.mao.map((e) => '${Formato.todos.indexOf(e!.formato)}:${e.cor}').join(',');
    expect(mao(Partida(semente: 7)), mao(Partida(semente: 7)));
  });

  test('não coloca fora do tabuleiro nem em cima de bloco', () {
    final p = Partida(semente: 1)..mao = [Peca(_bloco, 0), null, null];
    expect(p.colocar(0, 0, 8), isNull);
    p.tabuleiro.definir(3, 3, 1);
    expect(p.colocar(0, 3, 3), isNull);
    expect(p.colocar(0, 3, 4), isNotNull);
  });

  test('completar uma linha limpa e pontua', () {
    final p = Partida(semente: 1);
    _quaseCheia(p.tabuleiro, 0, cor: 1);
    p.mao = [Peca(_bloco, 2), Peca(_bloco, 2), null];
    final j = p.colocar(0, 0, 7)!;
    expect(j.linhasLimpas, 1);
    expect(j.combo, 1);
    expect(j.linhasDeUmaCor, 0);
    expect(j.tabuleiroLimpo, isTrue);
    expect(j.pontos, 1 + 10 + 300);
    expect(p.tabuleiro.vazio, isTrue);
    expect(j.removidos, hasLength(8));
  });

  test('linha de uma cor só vale bônus e gema', () {
    final p = Partida(semente: 1);
    _quaseCheia(p.tabuleiro, 2, cor: 4);
    p.tabuleiro.definir(7, 7, 0); // para não limpar o tabuleiro todo
    p.mao = [Peca(_bloco, 4), Peca(_bloco, 1), null];
    final j = p.colocar(0, 2, 7)!;
    expect(j.linhasDeUmaCor, 1);
    expect(j.pontos, 1 + 10 + 20);
    expect(j.gemas, 1);
  });

  test('linha e coluna juntas valem mais (2 linhas = 40)', () {
    final p = Partida(semente: 1);
    _quaseCheia(p.tabuleiro, 7, cor: 1);
    for (var l = 0; l < 7; l++) {
      p.tabuleiro.definir(l, 7, 2);
    }
    p.tabuleiro.definir(0, 0, 3);
    p.mao = [Peca(_bloco, 5), Peca(_bloco, 5), null];
    final j = p.colocar(0, 7, 7)!;
    expect(j.linhasLimpas, 2);
    expect(j.pontos, 1 + 40);
  });

  test('combo cresce e some depois de 3 jogadas sem limpar', () {
    final p = Partida(semente: 1);
    p.tabuleiro.definir(7, 0, 0);
    p.mao = [Peca(_linha8, 1), Peca(_linha8, 2), Peca(_bloco, 3)];
    expect(p.colocar(0, 0, 0)!.combo, 1);
    expect(p.colocar(1, 0, 0)!.combo, 2);
    expect(p.colocar(2, 5, 5)!.combo, 0);
    expect(p.combo, 2, reason: 'ainda dentro da folga');
  });

  test('mão nova chega quando as 3 peças são usadas', () {
    final p = Partida(semente: 3)..mao = [Peca(_bloco, 0), null, null];
    p.colocar(0, 0, 0);
    expect(p.mao.whereType<Peca>(), hasLength(3));
  });

  test('desfazer volta tabuleiro, mão e pontos', () {
    final p = Partida(semente: 3)..mao = [Peca(_bloco, 0), Peca(_bloco, 1), null];
    p.colocar(0, 4, 4);
    expect(p.desfazer(), isTrue);
    expect(p.tabuleiro.vazio, isTrue);
    expect(p.pontos, 0);
    expect(p.mao.first, isNotNull);
    expect(p.desfazer(), isFalse, reason: 'só um nível');
  });

  test('fim de jogo quando nada cabe, e continuar uma vez só', () {
    final p = Partida(semente: 5);
    for (var l = 0; l < 8; l++) {
      for (var k = 0; k < 8; k++) {
        if ((l + k).isOdd) p.tabuleiro.definir(l, k, 0);
      }
    }
    p.mao = [
      Peca(Formato.desenho(['##']), 0),
      null,
      null,
    ];
    expect(p.fimDeJogo, isTrue);
    expect(p.continuar(), isTrue);
    expect(p.fimDeJogo, isFalse);
    expect(p.continuar(), isFalse);
  });

  test('prévia mostra as linhas que vão sumir', () {
    final t = Tabuleiro();
    _quaseCheia(t, 4);
    final r = t.linhasCompletasCom(_bloco, 4, 7);
    expect(r.linhas, [4]);
    expect(r.colunas, isEmpty);
  });
}
