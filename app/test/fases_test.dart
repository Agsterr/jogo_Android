import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jogador automático simples: prefere limpar linhas, quebrar pedras e encostar peças.
/// Se ele vence, uma pessoa também vence.
({bool venceu, int estrelas, String motivo}) jogarSozinho(Fase fase) {
  final p = fase.novaPartida();
  while (!fase.concluida(p) && !fase.semPecas(p) && !p.fimDeJogo) {
    if (!jogada(p)) break;
  }
  return (
    venceu: fase.concluida(p),
    estrelas: fase.concluida(p) ? fase.estrelas(p) : 0,
    motivo: '${fase.progresso(p)}/${fase.alvo} ${p.fimDeJogo ? 'sem espaço' : 'sem peças'}',
  );
}

/// Faz a melhor jogada pela nota gulosa. Devolve `false` se nada coube.
bool jogada(Partida p) {
  final melhor = melhorJogada(p);
  if (melhor == null) return false;
  p.colocar(melhor.$1, melhor.$2, melhor.$3);
  return true;
}

/// Melhor (peça, linha, coluna) pela nota gulosa, ou `null` se nada cabe.
(int, int, int)? melhorJogada(Partida p) {
  {
    (int, int, int)? melhor;
    var melhorNota = -1 << 30;
    for (var i = 0; i < p.mao.length; i++) {
      final peca = p.mao[i];
      if (peca == null) continue;
      for (var l = 0; l < Tabuleiro.tamanho; l++) {
        for (var k = 0; k < Tabuleiro.tamanho; k++) {
          if (!p.tabuleiro.cabe(peca.formato, l, k)) continue;
          final cheias = p.tabuleiro.linhasCompletasCom(peca.formato, l, k);
          var nota = (cheias.linhas.length + cheias.colunas.length) * 100;
          for (final ll in cheias.linhas) {
            nota += 150 * List.generate(8, (kk) => p.tabuleiro.cor(ll, kk)).where((c) => c == Tabuleiro.pedra).length;
          }
          for (final kk in cheias.colunas) {
            nota += 150 * List.generate(8, (ll) => p.tabuleiro.cor(ll, kk)).where((c) => c == Tabuleiro.pedra).length;
          }
          for (final c in peca.formato.celulas) {
            // Preencher linha/coluna que tem pedra aproxima de quebrá-la.
            for (var x = 0; x < 8; x++) {
              if (p.tabuleiro.cor(l + c.linha, x) == Tabuleiro.pedra) nota += 5;
              if (p.tabuleiro.cor(x, k + c.coluna) == Tabuleiro.pedra) nota += 5;
            }
            for (final (dl, dk) in [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
              final ll = l + c.linha + dl, kk = k + c.coluna + dk;
              final fora = ll < 0 || kk < 0 || ll >= 8 || kk >= 8;
              if (fora || p.tabuleiro.cor(ll, kk) != null) nota += 3;
              if (!fora && p.tabuleiro.cor(ll, kk) == Tabuleiro.pedra) nota += 6;
            }
          }
          nota -= 25 * _buracosDepois(p.tabuleiro, peca.formato, l, k);
          if (nota > melhorNota) {
            melhorNota = nota;
            melhor = (i, l, k);
          }
        }
      }
    }
    return melhor;
  }
}

/// Casas vazias cercadas (onde quase nenhuma peça entra) depois de colocar a peça.
int _buracosDepois(Tabuleiro t, Formato f, int l, int k) {
  final c = t.copia();
  for (final cel in f.celulas) {
    c.definir(l + cel.linha, k + cel.coluna, 0);
  }
  final cheias = c.linhasCompletas();
  for (final ll in cheias.linhas) {
    for (var kk = 0; kk < 8; kk++) {
      c.definir(ll, kk, null);
    }
  }
  for (final kk in cheias.colunas) {
    for (var ll = 0; ll < 8; ll++) {
      c.definir(ll, kk, null);
    }
  }
  var buracos = 0;
  bool cheia(int a, int b) => a < 0 || b < 0 || a >= 8 || b >= 8 || c.cor(a, b) != null;
  for (var a = 0; a < 8; a++) {
    for (var b = 0; b < 8; b++) {
      if (c.cor(a, b) == null && cheia(a - 1, b) && cheia(a + 1, b) && cheia(a, b - 1) && cheia(a, b + 1)) buracos++;
    }
  }
  return buracos;
}

void main() {
  test('fases são sempre iguais e as pedras não repetem casa', () {
    for (var n = 1; n <= Fase.total; n++) {
      final a = Fase.numero(n), b = Fase.numero(n);
      expect((a.objetivo, a.alvo, a.pecas), (b.objetivo, b.alvo, b.pecas));
      expect(a.pedras, b.pedras);
      expect(a.pedras.toSet(), hasLength(a.pedras.length));
    }
  });

  test('todas as fases podem ser vencidas (jogador automático)', () {
    final relatorio = <String>[];
    for (var n = 1; n <= Fase.total; n++) {
      final f = Fase.numero(n);
      final r = jogarSozinho(f);
      relatorio.add(
        '$n ${f.objetivo.name} ${f.alvo}/${f.pecas}p: ${r.venceu ? '${r.estrelas}★' : 'PERDEU ${r.motivo}'}',
      );
    }
    printOnFailure(relatorio.join('\n'));
    expect(relatorio.where((l) => l.contains('PERDEU')), isEmpty);
  });

  test('estrelas pelas peças que sobram', () {
    final f = Fase.numero(1);
    final p = Partida(semente: 1);
    expect(f.estrelas(p), 3);
    p.jogadas = f.pecas - 1;
    expect(f.estrelas(p), 1);
  });
}
