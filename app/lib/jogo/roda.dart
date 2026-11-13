import 'sorteio.dart';

/// Roda da sorte diária: 1 giro grátis e mais [girosComAnuncio] vendo anúncio.
abstract final class Roda {
  /// Gemas de cada fatia (no sentido horário, a partir do topo).
  static const premios = [5, 10, 5, 20, 5, 50, 10, 15];

  /// Chance relativa de cada fatia (50 é raro).
  static const _pesos = [20, 14, 20, 8, 20, 2, 14, 10];

  static const girosComAnuncio = 2;
  static const girosPorDia = 1 + girosComAnuncio;

  /// Fatia sorteada no [giro] (0, 1, 2) do [dia]. Determinístico (dá para testar).
  static int sortear(int dia, int giro) {
    final total = _pesos.fold(0, (a, b) => a + b);
    var alvo = Sorteio(dia * 17 + giro * 101 + 3).proximo(total);
    for (var i = 0; i < _pesos.length; i++) {
      if (alvo < _pesos[i]) return i;
      alvo -= _pesos[i];
    }
    return 0;
  }
}
