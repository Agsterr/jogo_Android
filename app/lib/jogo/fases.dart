import 'dart:math' as math;

import 'partida.dart';
import 'peca.dart';
import 'robo.dart';
import 'sorteio.dart';
import 'tabuleiro.dart';

enum Objetivo {
  linhas('Limpe {} linhas'),
  pontos('Faça {} pontos'),
  pedras('Quebre as {} pedras'),
  umaCor('Limpe {} linhas de uma cor só'),
  combo('Faça um combo x{}');

  const Objetivo(this.modelo);

  final String modelo;
}

/// Uma fase do modo Fases. Gerada por fórmula e calibrada pelo [Robo]:
/// o limite de peças é o que o robô precisou mais uma folga que diminui fase a fase.
/// Assim toda fase tem solução e a dificuldade sobe de forma controlada.
class Fase {
  const Fase._(this.numero, this.objetivo, this.alvo, this.pecas, this.inicial, this.cores, this.semente);

  static const total = 140;
  static const porMundo = 20;
  static const mundos = ['Doce', 'Oceano', 'Vulcão', 'Floresta', 'Gelo', 'Deserto', 'Galáxia'];

  final int numero;
  final Objetivo objetivo;
  final int alvo;

  /// Limite de peças.
  final int pecas;

  /// Casas já ocupadas no começo: (linha, coluna, cor). Pedras usam `Tabuleiro.pedra`.
  final List<(int, int, int)> inicial;

  /// Cores das peças (fases de "uma cor" usam só 3).
  final int cores;
  final int semente;

  int get mundo => (numero - 1) ~/ porMundo;
  int get pedras => inicial.where((c) => c.$3 == Tabuleiro.pedra).length;
  String get texto {
    final t = objetivo.modelo.replaceAll('{}', '$alvo');
    return alvo == 1 ? t.replaceAll('linhas', 'linha').replaceAll('pedras', 'pedra') : t;
  }

  /// Fase de "chefe": a última de cada mundo, mais apertada.
  bool get chefe => numero % porMundo == 0;

  static final _cache = <int, Fase>{};

  factory Fase.numero(int n) {
    assert(n >= 1 && n <= total);
    return _cache[n] ??= _gerar(n);
  }

  Partida novaPartida() {
    final t = Tabuleiro();
    for (final (l, k, cor) in inicial) {
      t.definir(l, k, cor);
    }
    return Partida(semente: semente, inicial: t, cores: cores);
  }

  int progresso(Partida p) => switch (objetivo) {
    Objetivo.linhas => p.linhas,
    Objetivo.pontos => p.pontos,
    Objetivo.pedras => pedras - p.tabuleiro.pedras,
    Objetivo.umaCor => p.linhasDeUmaCor,
    Objetivo.combo => p.maiorCombo,
  };

  bool concluida(Partida p) => progresso(p) >= alvo;
  int pecasRestantes(Partida p) => pecas - p.jogadas;
  bool semPecas(Partida p) => pecasRestantes(p) <= 0;

  /// 3 estrelas sobrando 30% das peças, 2 sobrando 15%.
  int estrelas(Partida p) {
    final sobra = pecasRestantes(p) / pecas;
    return sobra >= 0.3 ? 3 : (sobra >= 0.15 ? 2 : 1);
  }

  // ---------- geração ----------

  /// Ordem dos objetivos: as primeiras fases ensinam um de cada vez.
  static Objetivo _objetivo(int n) {
    const inicio = [
      Objetivo.linhas,
      Objetivo.pontos,
      Objetivo.linhas,
      Objetivo.pedras,
      Objetivo.pontos,
      Objetivo.pedras,
      Objetivo.linhas,
      Objetivo.combo,
      Objetivo.pedras,
      Objetivo.umaCor,
    ];
    if (n <= inicio.length) return inicio[n - 1];
    if (n % porMundo == 0) return Objetivo.pedras; // chefe
    return Objetivo.values[(n * 7) % Objetivo.values.length];
  }

  static Fase _gerar(int n) {
    final dificuldade = (n - 1) / (total - 1); // 0 a 1
    final objetivo = _objetivo(n);
    // Folga sobre o que o robô precisou: 80% a mais no começo, 12% no fim; chefes mais apertados.
    final folga = 1.8 - 0.68 * dificuldade - (n % porMundo == 0 ? 0.08 : 0);
    var alvo = switch (objetivo) {
      Objetivo.linhas => 2 + (dificuldade * 14).round(),
      Objetivo.pontos => ((100 + dificuldade * 1500) / 50).round() * 50,
      Objetivo.pedras => 3 + (dificuldade * 9).round() + (n % porMundo == 0 ? 2 : 0),
      Objetivo.umaCor => 1 + (dificuldade * 3).round(),
      Objetivo.combo => 2 + (dificuldade * 4).round(),
    };
    final cores = objetivo == Objetivo.umaCor ? 3 : totalCores;
    // Blocos soltos no começo a partir do 2º mundo (até 14), deixando o tabuleiro "sujo".
    final soltos = n <= porMundo ? 0 : (dificuldade * 14).round();

    // Tenta variações até o robô vencer; se não der, alivia o alvo e tenta de novo.
    for (var tentativa = 0; ; tentativa++) {
      final semente = 7000000 + n * 7919 + tentativa * 104729;
      final inicial = _tabuleiroInicial(
        Sorteio(semente ~/ 3),
        pedras: objetivo == Objetivo.pedras ? alvo : 0,
        soltos: soltos,
        cores: cores,
      );
      final quantasPedras = inicial.where((c) => c.$3 == Tabuleiro.pedra).length;
      final alvoReal = objetivo == Objetivo.pedras ? quantasPedras : alvo;
      final fase = Fase._(n, objetivo, alvoReal, 999, inicial, cores, semente);
      final precisou = _pecasDoRobo(fase);
      if (precisou != null) {
        // Nunca menos de 10 peças: o robô às vezes tem sorte e a fase ficaria injusta.
        final limite = [precisou + 3, (precisou * folga).ceil(), 10].reduce(math.max);
        return Fase._(n, objetivo, alvoReal, limite, inicial, cores, semente);
      }
      if (tentativa % 8 == 7 && alvo > 1) alvo--;
      if (tentativa > 300) throw StateError('fase $n sem solução para o robô');
    }
  }

  /// Peças que o robô precisou para vencer (ou `null` se não venceu em 90).
  static int? _pecasDoRobo(Fase fase) {
    final p = fase.novaPartida();
    while (!fase.concluida(p) && p.jogadas < 90 && !p.fimDeJogo) {
      if (!Robo.jogar(p)) return null;
    }
    return fase.concluida(p) ? p.jogadas : null;
  }

  /// Pedras (no máximo 3 por linha/coluna) e blocos soltos, sem nenhuma linha completa.
  static List<(int, int, int)> _tabuleiroInicial(
    Sorteio sorteio, {
    required int pedras,
    required int soltos,
    required int cores,
  }) {
    const n = Tabuleiro.tamanho;
    final ocupadas = <(int, int), int>{};
    int naLinha(int l) => ocupadas.keys.where((c) => c.$1 == l).length;
    int naColuna(int k) => ocupadas.keys.where((c) => c.$2 == k).length;
    int pedrasNa(bool Function((int, int)) onde) =>
        ocupadas.entries.where((e) => onde(e.key) && e.value == Tabuleiro.pedra).length;

    var colocadas = 0;
    for (var i = 0; colocadas < pedras && i < 500; i++) {
      final l = sorteio.proximo(n), k = sorteio.proximo(n);
      if (ocupadas.containsKey((l, k))) continue;
      if (pedrasNa((c) => c.$1 == l) >= 3 || pedrasNa((c) => c.$2 == k) >= 3) continue;
      ocupadas[(l, k)] = Tabuleiro.pedra;
      colocadas++;
    }
    colocadas = 0;
    for (var i = 0; colocadas < soltos && i < 500; i++) {
      final l = sorteio.proximo(n), k = sorteio.proximo(n);
      if (ocupadas.containsKey((l, k)) || naLinha(l) >= n - 2 || naColuna(k) >= n - 2) continue;
      ocupadas[(l, k)] = sorteio.proximo(cores);
      colocadas++;
    }
    return [for (final MapEntry(key: (l, k), value: cor) in ocupadas.entries) (l, k, cor)];
  }
}
