import 'package:encaixa/jogo/fases.dart';
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

  test('salvar e carregar devolve a mesma partida (e o mesmo sorteio)', () {
    final p = Partida(semente: 9)..mao = [Peca(_bloco, 3), Peca(_linha8, 1), null];
    p.colocar(0, 2, 2);
    final copia = Partida.deJson(p.paraJson());
    expect(copia.paraJson(), p.paraJson());
    copia.colocar(1, 5, 0);
    p.colocar(1, 5, 0);
    expect(copia.paraJson(), p.paraJson(), reason: 'próximas peças iguais');
  });

  test('segunda chance limpa os blocos mas NÃO as pedras', () {
    final p = Partida(semente: 5);
    for (var l = 0; l < 8; l++) {
      for (var k = 0; k < 8; k++) {
        if ((l + k).isOdd) p.tabuleiro.definir(l, k, 0);
      }
    }
    p.tabuleiro.definir(3, 4, Tabuleiro.pedra); // casa par: sem bloco em volta ocupando outra coisa
    p.tabuleiro.definir(7, 6, Tabuleiro.pedra); // fora das 4 linhas do meio
    p.mao = [
      Peca(Formato.desenho(['##']), 0),
      null,
      null,
    ];
    expect(p.continuar(), isTrue);
    expect(p.tabuleiro.cor(3, 4), Tabuleiro.pedra, reason: 'pedra no meio continua lá');
    expect(p.tabuleiro.cor(7, 6), Tabuleiro.pedra);
    expect(p.tabuleiro.cor(3, 3), isNull, reason: 'bloco comum some');
    expect(p.tabuleiro.pedras, 2);
  });

  test('combo de fase é seguido: uma jogada sem limpar zera; no Infinito aguenta 2 jogadas sem limpar', () {
    Partida montar(int folga) {
      final p = Partida(semente: 3)..folga = folga;
      for (var l = 0; l < 3; l++) {
        _quaseCheia(p.tabuleiro, l);
      }
      p.mao = [Peca(_bloco, 1), Peca(_bloco, 1), Peca(_bloco, 1)];
      return p;
    }

    // folga 1 (fases de combo): limpa, limpa, não limpa -> zera
    final fase = montar(1);
    expect(fase.colocar(0, 0, 7)!.combo, 1);
    expect(fase.colocar(1, 1, 7)!.combo, 2);
    expect(fase.combo, 2);
    fase.mao = [Peca(_bloco, 1), Peca(_bloco, 1), Peca(_bloco, 1)];
    fase.colocar(0, 5, 5); // não limpa
    expect(fase.combo, 0, reason: 'uma jogada sem limpar já zera na fase de combo');

    // folga 3 (resto do jogo): duas jogadas sem limpar ainda mantêm o combo
    final livre = montar(Partida.folgaCombo);
    expect(livre.colocar(0, 0, 7)!.combo, 1);
    livre.mao = [Peca(_bloco, 1), Peca(_bloco, 1), Peca(_bloco, 1)];
    livre.colocar(0, 5, 5);
    livre.colocar(1, 6, 6);
    expect(livre.combo, 1, reason: '2 jogadas sem limpar: combo ainda vivo');
    livre.colocar(2, 7, 0);
    expect(livre.combo, 0, reason: 'na 3ª sem limpar, zera');
  });

  test('progresso da fase de combo é a sequência de agora e a partida da fase não tem folga', () {
    final fase = Fase.numero(8);
    expect(fase.objetivo, Objetivo.combo);
    final p = fase.novaPartida();
    expect(p.folga, 1);
    expect(fase.progresso(p), 0);
    p.combo = 3;
    p.maiorCombo = 3;
    expect(fase.progresso(p), 3);
    p.combo = 0; // quebrou
    expect(fase.progresso(p), 0, reason: 'a barra volta a zero quando a sequência quebra, mesmo com maiorCombo antigo');
  });

  test('fase de combo x4: 4 jogadas seguidas que limpam completam o objetivo (cada limpada conta 1, 2, 3, 4)', () {
    final fase = Fase.numero(8);
    final p = fase.novaPartida();
    // tabuleiro livre, com 5 linhas quase cheias (falta a última casa)
    for (var l = 0; l < Tabuleiro.tamanho; l++) {
      for (var k = 0; k < Tabuleiro.tamanho; k++) {
        p.tabuleiro.definir(l, k, null);
      }
    }
    for (var l = 0; l < 5; l++) {
      _quaseCheia(p.tabuleiro, l);
    }
    final vistos = <int>[];
    for (var i = 0; i < 4; i++) {
      p.mao = [Peca(_bloco, 1), Peca(_bloco, 1), Peca(_bloco, 1)];
      expect(p.colocar(0, i, 7), isNotNull);
      vistos.add(fase.progresso(p));
    }
    expect(vistos, [1, 2, 3, 4]);
    expect(fase.concluida(p), isTrue);
  });
}
