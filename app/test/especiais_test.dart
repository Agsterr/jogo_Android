import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:encaixa/widgets/mascote.dart';
import 'package:encaixa/servicos/servicos.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaDeExemplo;

/// Linha 7 cheia de blocos da cor 0, menos a coluna 3; o resto do tabuleiro vazio.
Partida _quaseLinha() {
  final p = Partida(semente: 1);
  for (var k = 0; k < Tabuleiro.tamanho; k++) {
    if (k != 3) p.tabuleiro.definir(7, k, 0);
  }
  return p;
}

class _Jogo extends StatelessWidget {
  const _Jogo(this.s, this.partida);

  final Servicos s;
  final Partida partida;

  @override
  Widget build(BuildContext context) => JogoTela(servicos: s, partida: partida);
}

void main() {
  setUpAll(carregarFontes);

  test('no nível 0 nunca sai bloco especial e o sorteio é o de sempre; do nível 1 em diante saem alguns', () {
    final a = Sorteio(99), b = Sorteio(99);
    for (var i = 0; i < 500; i++) {
      final p = Peca.sortear(a, totalCores, 0);
      expect(p.especial, 0);
      // O mesmo sorteio sem o parâmetro de nível: idêntico (nada foi gasto a mais).
      final q = Peca.sortear(b);
      expect(p.cor, q.cor);
      expect(p.formato.celulas.length, q.formato.celulas.length);
    }
    final s = Sorteio(7);
    var especiais = 0, bombas = 0, joias = 0;
    for (var i = 0; i < 2000; i++) {
      final p = Peca.sortear(s, totalCores, 1);
      if (p.especial > 0) {
        especiais++;
        expect(p.celulaEspecial, lessThan(p.formato.celulas.length));
        p.especial == 1 ? bombas++ : joias++;
      }
    }
    expect(especiais, inInclusiveRange(150, 330), reason: 'cerca de 12%');
    expect(bombas, greaterThan(joias));
    expect(joias, greaterThan(40));
  });

  test('só o Infinito usa especiais: Desafio, Arena e fases (rampa desligada) ficam sem', () {
    final p = Partida(semente: 20261112);
    expect(p.rampa, isFalse);
    expect(p.nivel, 0);
    for (var i = 0; i < 40; i++) {
      p.trocarMao();
      expect(p.mao.whereType<Peca>().every((x) => x.especial == 0), isTrue);
    }
  });

  test('bomba: ao completar a linha dela, limpa o 3x3 em volta (sem pedras) e dá pontos extras', () {
    final p = _quaseLinha();
    p.tabuleiro
      ..definir(6, 3, 2) // logo acima da bomba (dentro do 3x3)
      ..definir(6, 2, 2)
      ..definir(5, 6, 4) // longe: fica
      ..definir(6, 4, Tabuleiro.pedra); // pedra dentro do 3x3: fica
    final formato = Formato.desenho(['#']);
    p.mao = [Peca(formato, 1, especial: Tabuleiro.bomba), null, null];
    final jogada = p.colocar(0, 7, 3)!;
    expect(jogada.linhasLimpas, 1);
    expect(jogada.bombas, 1);
    expect(p.tabuleiro.cor(6, 3), isNull, reason: 'dentro do 3x3');
    expect(p.tabuleiro.cor(6, 2), isNull);
    expect(p.tabuleiro.cor(5, 6), 4, reason: 'fora do 3x3');
    expect(p.tabuleiro.cor(6, 4), Tabuleiro.pedra, reason: 'pedra nunca sai com a bomba');
    final simples = _quaseLinha();
    simples.tabuleiro.definir(5, 6, 4); // sobra um bloco, para não ganhar o bônus de tabuleiro limpo
    simples.mao = [Peca(formato, 1), null, null];
    final base = simples.colocar(0, 7, 3)!;
    expect(jogada.pontos, base.pontos + 15);
    expect(jogada.removidos.length, greaterThan(base.removidos.length));
  });

  test('joia: ao completar a linha dela, dá +1 gema e +30 pontos', () {
    final formato = Formato.desenho(['#']);
    final com = _quaseLinha()..mao = [Peca(formato, 0, especial: Tabuleiro.joia), null, null];
    final sem = _quaseLinha()..mao = [Peca(formato, 0), null, null];
    final j = com.colocar(0, 7, 3)!;
    final k = sem.colocar(0, 7, 3)!;
    expect(j.joias, 1);
    expect(j.pontos, k.pontos + 30);
    expect(j.gemas, k.gemas + 1);
  });

  test('bloco especial na linha de uma cor só ainda conta como "linha de uma cor"', () {
    final formato = Formato.desenho(['#']);
    final p = _quaseLinha()..mao = [Peca(formato, 0, especial: Tabuleiro.joia), null, null];
    expect(p.colocar(0, 7, 3)!.linhasDeUmaCor, 1);
  });

  test('a partida salva guarda o bloco especial da mão', () {
    final p = Partida(semente: 5);
    p.mao = [
      Peca(Formato.desenho(['##', '#.']), 2, especial: 1, celulaEspecial: 2),
      Peca(Formato.desenho(['#']), 3),
      null,
    ];
    final volta = Partida.deJson(p.paraJson());
    expect(volta.mao[0]!.especial, 1);
    expect(volta.mao[0]!.celulaEspecial, 2);
    expect(volta.mao[1]!.especial, 0);
    expect(volta.mao[2], isNull);
  });

  testWidgets('visual: bomba e joia no tabuleiro e na mão', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    final partida = partidaDeExemplo();
    partida.tabuleiro
      ..definir(6, 6, 12)
      ..definir(5, 1, 21)
      ..definir(3, 6, 14);
    partida.mao = [
      Peca(Formato.desenho(['###']), 4, especial: 1, celulaEspecial: 1),
      Peca(Formato.desenho(['##', '##']), 2, especial: 2, celulaEspecial: 3),
      Peca(Formato.desenho(['#', '#']), 0),
    ];
    await tester.pumpWidget(appDeTeste(s, tela: _Jogo(s, partida)));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    await capturar(tester, '37-especiais');
  });

  test('o mascote reage ao resultado da partida', () {
    expect(humorDoFim(novoRecorde: true, pontos: 500, recorde: 500), Humor.festa);
    expect(humorDoFim(novoRecorde: false, pontos: 900, recorde: 1000), Humor.feliz);
    expect(humorDoFim(novoRecorde: false, pontos: 100, recorde: 1000), Humor.triste);
    expect(humorDoFim(novoRecorde: false, pontos: 0, recorde: 0), Humor.feliz, reason: 'primeira partida não é triste');
    expect(fraseDoMascote(novoRecorde: true, pontos: 1, recorde: 1), contains('recorde'));
    expect(fraseDoMascote(novoRecorde: false, pontos: 850, recorde: 1000), contains('Quase'));
  });
}
