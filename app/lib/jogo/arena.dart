import 'sorteio.dart';

/// Troféu da Arena: pontos mínimos na semana e prêmio em gemas.
class Trofeu {
  const Trofeu(this.nome, this.pontos, this.gemas);

  final String nome;
  final int pontos;
  final int gemas;
}

/// Arena da semana: as mesmas peças para todos de segunda a domingo; vale a melhor partida.
abstract final class Arena {
  static const trofeus = [
    Trofeu('Bronze', 500, 10),
    Trofeu('Prata', 1500, 25),
    Trofeu('Ouro', 3000, 50),
    Trofeu('Diamante', 6000, 100),
  ];

  /// Segunda-feira da semana de [dia], como aaaammdd (identifica a semana).
  static int semana(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    return Sorteio.sementeDoDia(d.subtract(Duration(days: d.weekday - DateTime.monday)));
  }

  /// Semente das peças da semana (diferente da do Desafio do dia).
  static int semente(DateTime dia) => semana(dia) * 13 + 5;

  /// Quando a semana acaba (próxima segunda 0h).
  static DateTime fim(DateTime dia) {
    final d = DateTime(dia.year, dia.month, dia.day);
    return d.add(Duration(days: 8 - d.weekday));
  }

  /// Melhor troféu para essa pontuação (ou `null`).
  static Trofeu? trofeuPara(int pontos) {
    Trofeu? melhor;
    for (final t in trofeus) {
      if (pontos >= t.pontos) melhor = t;
    }
    return melhor;
  }
}
