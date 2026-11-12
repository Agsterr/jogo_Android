import 'partida.dart';
import 'peca.dart';
import 'tabuleiro.dart';

/// Jogador automático guloso. Serve para calibrar as fases (limite de peças) e nos testes:
/// se ele vence com folga, uma pessoa também vence.
abstract final class Robo {
  /// Faz a melhor jogada. Devolve `false` se nada coube.
  static bool jogar(Partida p) {
    final melhor = melhorJogada(p);
    if (melhor == null) return false;
    p.colocar(melhor.$1, melhor.$2, melhor.$3);
    return true;
  }

  /// Melhor (peça, linha, coluna) pela nota, ou `null` se nada cabe.
  static (int, int, int)? melhorJogada(Partida p) {
    (int, int, int)? melhor;
    var melhorNota = -1 << 30;
    final t = p.tabuleiro;
    for (var i = 0; i < p.mao.length; i++) {
      final peca = p.mao[i];
      if (peca == null) continue;
      for (var l = 0; l < Tabuleiro.tamanho; l++) {
        for (var k = 0; k < Tabuleiro.tamanho; k++) {
          if (!t.cabe(peca.formato, l, k)) continue;
          final nota = _nota(t, peca, l, k);
          if (nota > melhorNota) {
            melhorNota = nota;
            melhor = (i, l, k);
          }
        }
      }
    }
    return melhor;
  }

  static int _nota(Tabuleiro t, Peca peca, int l, int k) {
    const n = Tabuleiro.tamanho;
    final cheias = t.linhasCompletasCom(peca.formato, l, k);
    var nota = (cheias.linhas.length + cheias.colunas.length) * 100;
    int pedrasEm(Iterable<int?> casas) => casas.where((c) => c == Tabuleiro.pedra).length;
    for (final ll in cheias.linhas) {
      nota += 150 * pedrasEm(List.generate(n, (kk) => t.cor(ll, kk)));
    }
    for (final kk in cheias.colunas) {
      nota += 150 * pedrasEm(List.generate(n, (ll) => t.cor(ll, kk)));
    }
    for (final c in peca.formato.celulas) {
      final cl = l + c.linha, ck = k + c.coluna;
      final linha = List.generate(n, (x) => t.cor(cl, x)), coluna = List.generate(n, (x) => t.cor(x, ck));
      // Encher linha/coluna com pedra aproxima de quebrá-la.
      nota += 5 * (pedrasEm(linha) + pedrasEm(coluna));
      // Manter linha/coluna de uma cor só (bônus e objetivo "uma cor").
      for (final casas in [linha, coluna]) {
        final cores = casas.whereType<int>().toSet();
        if (cores.length == 1 && cores.first == peca.cor) nota += 4 * casas.whereType<int>().length;
      }
      for (final (dl, dk) in const [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
        final ll = cl + dl, kk = ck + dk;
        final fora = ll < 0 || kk < 0 || ll >= n || kk >= n;
        if (fora || t.cor(ll, kk) != null) nota += 3;
        if (!fora && t.cor(ll, kk) == Tabuleiro.pedra) nota += 6;
      }
    }
    return nota - 25 * _buracosDepois(t, peca.formato, l, k);
  }

  /// Casas vazias cercadas (onde quase nenhuma peça entra) depois de colocar a peça.
  static int _buracosDepois(Tabuleiro t, Formato f, int l, int k) {
    const n = Tabuleiro.tamanho;
    final c = t.copia();
    for (final cel in f.celulas) {
      c.definir(l + cel.linha, k + cel.coluna, 0);
    }
    final cheias = c.linhasCompletas();
    for (final ll in cheias.linhas) {
      for (var kk = 0; kk < n; kk++) {
        c.definir(ll, kk, null);
      }
    }
    for (final kk in cheias.colunas) {
      for (var ll = 0; ll < n; ll++) {
        c.definir(ll, kk, null);
      }
    }
    bool cheia(int a, int b) => a < 0 || b < 0 || a >= n || b >= n || c.cor(a, b) != null;
    var buracos = 0;
    for (var a = 0; a < n; a++) {
      for (var b = 0; b < n; b++) {
        if (!cheia(a, b) && cheia(a - 1, b) && cheia(a + 1, b) && cheia(a, b - 1) && cheia(a, b + 1)) buracos++;
      }
    }
    return buracos;
  }
}
