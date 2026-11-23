/// Meta de pontos do modo Infinito: dá gemas e sobe o nível (as peças ficam maiores).
class Marco {
  const Marco(this.pontos, this.gemas);

  final int pontos;
  final int gemas;
}

abstract final class Marcos {
  static const todos = [
    Marco(1000, 3),
    Marco(2500, 5),
    Marco(5000, 10),
    Marco(10000, 20),
    Marco(20000, 40),
    Marco(40000, 80),
  ];

  /// O nível que mexe nas peças para de subir aqui (não fica impossível).
  static const nivelMaximoDasPecas = 4;

  /// Próxima meta para quem já pagou [pagos] metas, ou `null` se acabaram.
  static Marco? proximo(int pagos) => pagos < todos.length ? todos[pagos] : null;

  /// Metas que [pontos] já alcançou e que ainda não foram pagas.
  static List<Marco> novas(int pontos, int pagos) => [
    for (var i = pagos; i < todos.length && pontos >= todos[i].pontos; i++) todos[i],
  ];

  /// 1000 vira "1.000".
  static String formatar(int pontos) => pontos.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
}
