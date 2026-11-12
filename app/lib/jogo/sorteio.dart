/// Gerador pseudoaleatório pequeno e determinístico (mulberry32).
///
/// Usado no lugar de `dart:math Random` porque o Desafio do dia precisa
/// sortear exatamente as mesmas peças para todo mundo, em qualquer versão.
class Sorteio {
  Sorteio(int semente) : _estado = semente & 0xFFFFFFFF;

  Sorteio._copia(this._estado);

  int _estado;

  Sorteio copia() => Sorteio._copia(_estado);

  /// Volta ao estado de uma cópia (usado pelo "Desfazer").
  void restaurarDe(Sorteio outro) => _estado = outro._estado;

  /// Próximo inteiro em `[0, maximo)`.
  int proximo(int maximo) {
    _estado = (_estado + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _estado;
    t = _mul(t ^ (t >> 15), t | 1);
    t ^= (t + _mul(t ^ (t >> 7), t | 61)) & 0xFFFFFFFF;
    t = (t ^ (t >> 14)) & 0xFFFFFFFF;
    return t % maximo;
  }

  static int _mul(int a, int b) => (a * b) & 0xFFFFFFFF;

  /// Semente do Desafio do dia: muda à meia-noite e é igual para todos.
  static int sementeDoDia(DateTime dia) => dia.year * 10000 + dia.month * 100 + dia.day;
}
