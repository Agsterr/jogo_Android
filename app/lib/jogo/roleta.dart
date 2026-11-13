import 'sorteio.dart';

/// Roleta do fim de partida: prêmios bons e ruins ("Nada" existe de verdade).
abstract final class Roleta {
  /// Gemas de cada fatia (0 = "Nada"), no sentido horário a partir do topo.
  static const premios = [0, 3, 1, 10, 0, 5, 2, 25];
  static const _pesos = [20, 14, 20, 6, 16, 10, 13, 1];

  /// Giros extras (cada um com anúncio) depois do grátis.
  static const girosExtras = 2;

  static String rotulo(int fatia) => premios[fatia] == 0 ? 'Nada' : '+${premios[fatia]}';

  static int sortear(Sorteio sorteio) {
    final total = _pesos.fold(0, (a, b) => a + b);
    var alvo = sorteio.proximo(total);
    for (var i = 0; i < _pesos.length; i++) {
      if (alvo < _pesos[i]) return i;
      alvo -= _pesos[i];
    }
    return 0;
  }
}
