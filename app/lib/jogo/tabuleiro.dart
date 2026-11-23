import 'peca.dart';

/// Grade 8x8. Cada casa guarda a cor do bloco ou `null` quando vazia.
class Tabuleiro {
  Tabuleiro() : _casas = List<int?>.filled(tamanho * tamanho, null);
  Tabuleiro._(this._casas);

  static const int tamanho = 8;

  /// Bloco de pedra das fases: não vem da mão, some quando a linha dele é limpa.
  static const int pedra = totalCores;

  /// Blocos especiais do Infinito: o código é `tipo * 10 + cor`. Bomba (10 a 15) explode a área 3x3 quando a linha
  /// dela é limpa; joia (20 a 25) dá gema e pontos extras.
  static const int bomba = 1;
  static const int joia = 2;

  /// Gelo (30 a 35): a primeira linha que o atinge só descongela (vira "rachado"); curinga (50 a 55) vale por qualquer
  /// cor na linha de uma cor só; rachado (40 a 45) é o gelo já descongelado e dá gema ao sair.
  static const int gelo = 3;
  static const int rachado = 4;
  static const int curinga = 5;

  static bool ehGelo(int codigo) => codigo ~/ 10 == gelo;
  static bool ehRachado(int codigo) => codigo ~/ 10 == rachado;
  static bool ehCuringa(int codigo) => codigo ~/ 10 == curinga;

  static bool ehBomba(int codigo) => codigo ~/ 10 == bomba;
  static bool ehJoia(int codigo) => codigo ~/ 10 == joia;

  /// A cor (0 a 5) de uma casa, também nas casas especiais. A pedra continua sendo [pedra].
  static int base(int codigo) => codigo >= 10 ? codigo % 10 : codigo;

  final List<int?> _casas;

  Tabuleiro copia() => Tabuleiro._(List.of(_casas));

  int? cor(int linha, int coluna) => _casas[linha * tamanho + coluna];
  void definir(int linha, int coluna, int? cor) => _casas[linha * tamanho + coluna] = cor;

  bool get vazio => _casas.every((c) => c == null);
  int get pedras => _casas.where((c) => c == pedra).length;
  int get ocupadas => _casas.where((c) => c != null).length;

  bool cabe(Formato formato, int linha, int coluna) {
    for (final c in formato.celulas) {
      final l = linha + c.linha, k = coluna + c.coluna;
      if (l < 0 || k < 0 || l >= tamanho || k >= tamanho) return false;
      if (cor(l, k) != null) return false;
    }
    return true;
  }

  bool cabeEmAlgumLugar(Formato formato) {
    for (var l = 0; l <= tamanho - formato.linhas; l++) {
      for (var k = 0; k <= tamanho - formato.colunas; k++) {
        if (cabe(formato, l, k)) return true;
      }
    }
    return false;
  }

  /// Linhas e colunas que ficariam completas se a peça fosse colocada ali.
  ({List<int> linhas, List<int> colunas}) linhasCompletasCom(Formato formato, int linha, int coluna) {
    final teste = copia();
    for (final c in formato.celulas) {
      teste.definir(linha + c.linha, coluna + c.coluna, 0);
    }
    return teste.linhasCompletas();
  }

  ({List<int> linhas, List<int> colunas}) linhasCompletas() => (
    linhas: [
      for (var l = 0; l < tamanho; l++)
        if (List.generate(tamanho, (k) => cor(l, k)).every((c) => c != null)) l,
    ],
    colunas: [
      for (var k = 0; k < tamanho; k++)
        if (List.generate(tamanho, (l) => cor(l, k)).every((c) => c != null)) k,
    ],
  );
}
