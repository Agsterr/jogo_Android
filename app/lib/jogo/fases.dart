import 'dart:math' as math;

import 'partida.dart';
import 'sorteio.dart';
import 'tabuleiro.dart';

enum Objetivo {
  linhas('Limpe {} linhas'),
  pontos('Faça {} pontos'),
  pedras('Quebre as {} pedras');

  const Objetivo(this.modelo);

  final String modelo;
}

/// Uma fase do modo Fases. Geradas por fórmula (sem arquivo de dados) e iguais para todos.
class Fase {
  const Fase._(this.numero, this.objetivo, this.alvo, this.pecas, this.pedras);

  static const total = 60;
  static const porMundo = 20;
  static const mundos = ['Doce', 'Oceano', 'Vulcão'];

  final int numero;
  final Objetivo objetivo;
  final int alvo;

  /// Limite de peças.
  final int pecas;

  /// Casas com pedra no começo (só nas fases de pedra).
  final List<(int, int)> pedras;

  int get mundo => (numero - 1) ~/ porMundo;
  int get semente => 7000000 + numero * 7919;
  String get texto => objetivo.modelo.replaceAll('{}', '$alvo');

  /// Curva de dificuldade: as primeiras ensinam, depois aperta aos poucos.
  factory Fase.numero(int n) {
    assert(n >= 1 && n <= total);
    final objetivo = n == 1 ? Objetivo.linhas : (n == 2 ? Objetivo.pontos : Objetivo.values[n % 3]);
    switch (objetivo) {
      case Objetivo.linhas:
        final alvo = 2 + n ~/ 5;
        return Fase._(n, objetivo, alvo, alvo * 3 + 6 - n ~/ 20, const []);
      case Objetivo.pontos:
        final alvo = ((60 + n * 4) / 50).round() * 50;
        return Fase._(n, objetivo, alvo, 17 + n ~/ 4, const []);
      case Objetivo.pedras:
        final pedras = _pedras(n, math.min(8, 3 + n ~/ 8));
        return Fase._(n, objetivo, pedras.length, 14 + pedras.length * 3, pedras);
    }
  }

  /// Pedras espalhadas, no máximo 3 por linha/coluna (para não ficar impossível).
  static List<(int, int)> _pedras(int n, int quantidade) {
    final sorteio = Sorteio(n * 104729);
    final pedras = <(int, int)>{};
    while (pedras.length < quantidade) {
      final l = sorteio.proximo(Tabuleiro.tamanho), k = sorteio.proximo(Tabuleiro.tamanho);
      final naLinha = pedras.where((p) => p.$1 == l).length, naColuna = pedras.where((p) => p.$2 == k).length;
      if (naLinha < 3 && naColuna < 3) pedras.add((l, k));
    }
    return pedras.toList();
  }

  Partida novaPartida() {
    final t = Tabuleiro();
    for (final (l, k) in pedras) {
      t.definir(l, k, Tabuleiro.pedra);
    }
    return Partida(semente: semente, inicial: t);
  }

  int progresso(Partida p) => switch (objetivo) {
    Objetivo.linhas => p.linhas,
    Objetivo.pontos => p.pontos,
    Objetivo.pedras => pedras.length - p.tabuleiro.pedras,
  };

  bool concluida(Partida p) => progresso(p) >= alvo;
  int pecasRestantes(Partida p) => pecas - p.jogadas;
  bool semPecas(Partida p) => pecasRestantes(p) <= 0;

  /// 3 estrelas sobrando 30% das peças, 2 sobrando 15%.
  int estrelas(Partida p) {
    final sobra = pecasRestantes(p) / pecas;
    return sobra >= 0.3 ? 3 : (sobra >= 0.15 ? 2 : 1);
  }
}
