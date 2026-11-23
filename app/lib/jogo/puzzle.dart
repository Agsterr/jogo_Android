import 'peca.dart';
import 'sorteio.dart';
import 'tabuleiro.dart';

/// Puzzle do dia: um tabuleiro já montado e 3 peças fixas, iguais para todo mundo. O jogador coloca as 3 peças e vale
/// limpar o máximo de linhas. Cada puzzle nasce de uma **solução plantada** (as peças em posições que completam as
/// linhas), então sempre há uma jogada que atinge a [meta]. É a mesma conta para todos, sem servidor.
class PuzzleDoDia {
  const PuzzleDoDia({required this.dia, required this.tabuleiro, required this.pecas, required this.meta});

  /// Dia (aaaammdd) em que este puzzle vale.
  final int dia;

  /// Tabuleiro de partida. Use [Tabuleiro.copia] antes de jogar.
  final Tabuleiro tabuleiro;
  final List<Peca> pecas;

  /// Linhas (e colunas) que a solução plantada limpa.
  final int meta;
}

/// Estrelas pelo que o jogador limpou: 3 = a meta, 2 = só uma a menos (mínimo 2 linhas), 1 = pelo menos uma linha.
int estrelasDoPuzzle(int linhasLimpas, int meta) {
  if (linhasLimpas >= meta) return 3;
  if (linhasLimpas >= meta - 1 && linhasLimpas >= 2) return 2;
  if (linhasLimpas >= 1) return 1;
  return 0;
}

/// Gemas pela melhor marca do dia (acumulado): 1 estrela 2, 2 estrelas 5, 3 estrelas 10.
int gemasDoPuzzle(int estrelas) => switch (estrelas) {
  3 => 10,
  2 => 5,
  1 => 2,
  _ => 0,
};

/// Linhas e colunas completas que um lance gera e o tabuleiro depois de limpá-las.
({Tabuleiro tabuleiro, int linhas}) jogarPeca(Tabuleiro t, Formato f, int linha, int coluna) {
  final novo = t.copia();
  for (final c in f.celulas) {
    novo.definir(linha + c.linha, coluna + c.coluna, 0);
  }
  final completas = novo.linhasCompletas();
  for (final l in completas.linhas) {
    for (var k = 0; k < Tabuleiro.tamanho; k++) {
      novo.definir(l, k, null);
    }
  }
  for (final k in completas.colunas) {
    for (var l = 0; l < Tabuleiro.tamanho; l++) {
      novo.definir(l, k, null);
    }
  }
  return (tabuleiro: novo, linhas: completas.linhas.length + completas.colunas.length);
}

/// O jogador "esperto demais" que escolhe, peça por peça e na ordem da mão, a jogada que limpa mais agora. Serve para
/// recusar puzzles fáceis (se a jogada óbvia já bate a meta, não é puzzle).
int linhasDoGuloso(Tabuleiro inicial, List<Peca> pecas) {
  var t = inicial.copia();
  var total = 0;
  for (final p in pecas) {
    var melhor = -1;
    ({Tabuleiro tabuleiro, int linhas})? escolha;
    for (var l = 0; l <= Tabuleiro.tamanho - p.formato.linhas; l++) {
      for (var k = 0; k <= Tabuleiro.tamanho - p.formato.colunas; k++) {
        if (!t.cabe(p.formato, l, k)) continue;
        final r = jogarPeca(t, p.formato, l, k);
        if (r.linhas > melhor) {
          melhor = r.linhas;
          escolha = r;
        }
      }
    }
    if (escolha == null) break;
    t = escolha.tabuleiro;
    total += escolha.linhas;
  }
  return total;
}

final _guardados = <int, PuzzleDoDia>{};

/// O puzzle de um dia. Sempre o mesmo para o mesmo [dia] (o último fica guardado, porque gerar custa um pouco).
PuzzleDoDia puzzleDoDia(int dia) {
  if (_guardados[dia] case final guardado?) return guardado;
  final novo = _gerar(dia);
  if (_guardados.length > 4) _guardados.clear();
  return _guardados[dia] = novo;
}

PuzzleDoDia _gerar(int dia) {
  PuzzleDoDia? reserva;
  for (var tentativa = 0; tentativa < 400; tentativa++) {
    final p = _tentar(dia, Sorteio(dia * 977 + tentativa));
    if (p == null) continue;
    reserva ??= p;
    if (p.meta >= 3 && p.meta <= 5 && linhasDoGuloso(p.tabuleiro, p.pecas) < p.meta) return p;
  }
  return reserva ?? _tentar(dia, Sorteio(1))!;
}

PuzzleDoDia? _tentar(int dia, Sorteio rng) {
  // 1. Três peças pequenas ou médias.
  final pecas = <Peca>[];
  for (var i = 0; i < 40 && pecas.length < 3; i++) {
    final p = Peca.sortear(rng);
    if (p.formato.celulas.length <= 5) pecas.add(p);
  }
  if (pecas.length < 3) return null;

  // 2. Posições sem sobreposição no tabuleiro vazio: é a solução plantada.
  final ocupado = Tabuleiro();
  final posicoes = <(int, int)>[];
  for (final p in pecas) {
    (int, int)? lugar;
    for (var i = 0; i < 80 && lugar == null; i++) {
      final l = rng.proximo(Tabuleiro.tamanho - p.formato.linhas + 1);
      final k = rng.proximo(Tabuleiro.tamanho - p.formato.colunas + 1);
      if (ocupado.cabe(p.formato, l, k)) lugar = (l, k);
    }
    if (lugar == null) return null;
    for (final c in p.formato.celulas) {
      ocupado.definir(lugar.$1 + c.linha, lugar.$2 + c.coluna, 0);
    }
    posicoes.add(lugar);
  }

  // 3. Linhas e colunas que passam pelas peças; as que mais as cobrem entram primeiro.
  final candidatas = <(bool, int, int)>[]; // (éLinha, índice, quantas células das peças)
  for (var i = 0; i < Tabuleiro.tamanho; i++) {
    final naLinha = List.generate(Tabuleiro.tamanho, (k) => ocupado.cor(i, k)).where((c) => c != null).length;
    final naColuna = List.generate(Tabuleiro.tamanho, (l) => ocupado.cor(l, i)).where((c) => c != null).length;
    if (naLinha > 0) candidatas.add((true, i, naLinha));
    if (naColuna > 0) candidatas.add((false, i, naColuna));
  }
  if (candidatas.length < 3) return null;
  // Embaralha de forma fixa e depois ordena por cobertura (estável: o empate fica no embaralhado).
  for (var i = candidatas.length - 1; i > 0; i--) {
    final j = rng.proximo(i + 1);
    final tmp = candidatas[i];
    candidatas[i] = candidatas[j];
    candidatas[j] = tmp;
  }
  final ordenadas = [...candidatas]..sort((a, b) => b.$3.compareTo(a.$3));
  final quantas = 3 + rng.proximo(2);
  final escolhidas = ordenadas.take(quantas).toList();

  // 4. Enche as linhas escolhidas, menos onde as peças vão entrar.
  final tabuleiro = Tabuleiro();
  final protegidas = <(int, int)>{};
  for (var l = 0; l < Tabuleiro.tamanho; l++) {
    for (var k = 0; k < Tabuleiro.tamanho; k++) {
      if (ocupado.cor(l, k) != null) protegidas.add((l, k));
    }
  }
  final emLinhaEscolhida = <(int, int)>{};
  for (final (eLinha, indice, _) in escolhidas) {
    for (var i = 0; i < Tabuleiro.tamanho; i++) {
      final celula = eLinha ? (indice, i) : (i, indice);
      emLinhaEscolhida.add(celula);
      if (!protegidas.contains(celula)) tabuleiro.definir(celula.$1, celula.$2, rng.proximo(totalCores));
    }
  }

  // 5. Blocos soltos para atrapalhar, fora das linhas escolhidas e dos buracos.
  final soltos = 4 + rng.proximo(6);
  for (var i = 0; i < soltos * 4 && i < 80; i++) {
    final l = rng.proximo(Tabuleiro.tamanho), k = rng.proximo(Tabuleiro.tamanho);
    if (protegidas.contains((l, k)) || emLinhaEscolhida.contains((l, k)) || tabuleiro.cor(l, k) != null) continue;
    tabuleiro.definir(l, k, rng.proximo(totalCores));
    if (tabuleiro.ocupadas >= emLinhaEscolhida.length - protegidas.length + soltos) break;
  }
  // Nenhuma linha pode começar completa.
  final c = tabuleiro.linhasCompletas();
  if (c.linhas.isNotEmpty || c.colunas.isNotEmpty) return null;

  // 6. A meta é o que a solução plantada realmente limpa.
  var t = tabuleiro.copia();
  var meta = 0;
  for (var i = 0; i < 3; i++) {
    if (!t.cabe(pecas[i].formato, posicoes[i].$1, posicoes[i].$2)) return null;
    final r = jogarPeca(t, pecas[i].formato, posicoes[i].$1, posicoes[i].$2);
    t = r.tabuleiro;
    meta += r.linhas;
  }
  return PuzzleDoDia(dia: dia, tabuleiro: tabuleiro, pecas: pecas, meta: meta);
}
