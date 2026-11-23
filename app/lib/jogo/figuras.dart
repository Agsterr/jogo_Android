import 'fases.dart';

/// Figura de um mundo do modo Fases: um desenho de 10x8 blocos, em 20 pedaços (5x4, cada um com 2x2 blocos).
/// Cada fase vencida revela um pedaço, na ordem das fases. Ao vencer o chefe a figura está completa.
/// Só visual: nada aqui muda o jogo.
class Figura {
  const Figura(this.nome, this.linhas, this.paleta);

  final String nome;

  /// 8 linhas de 10 letras; `.` é vazio e cada letra de [paleta] é uma cor.
  final List<String> linhas;

  /// Letra → cor ARGB.
  final Map<String, int> paleta;

  static const colunas = 10, altura = 8;

  /// Pedaços em cada direção (20 no total = fases de um mundo).
  static const pedacosPorLinha = 5, pedacosPorColuna = 4;

  /// Cor do bloco (`null` = vazio).
  int? cor(int linha, int coluna) {
    final c = linhas[linha][coluna];
    return c == '.' ? null : paleta[c];
  }

  /// Pedaços (0 a 19) que têm ao menos um bloco, em ordem. Os vazios não aparecem nunca.
  List<int> get comBloco => [
    for (var p = 0; p < pedacosPorLinha * pedacosPorColuna; p++)
      if (_temBloco(p)) p,
  ];

  bool _temBloco(int pedaco) {
    final l0 = (pedaco ~/ pedacosPorLinha) * 2, k0 = (pedaco % pedacosPorLinha) * 2;
    return [
      for (var a = 0; a < 2; a++)
        for (var b = 0; b < 2; b++) cor(l0 + a, k0 + b),
    ].any((c) => c != null);
  }

  /// Quantos pedaços com bloco aparecem depois de [feitas] fases do mundo (de 0 a 20): o desenho é revelado aos poucos
  /// e fica inteiro na 20ª.
  int _aparecem(int feitas) => (feitas * comBloco.length / Fase.porMundo).ceil();

  /// Pedaços visíveis depois de [feitas] fases vencidas no mundo.
  Set<int> visiveis(int feitas) => comBloco.take(_aparecem(feitas)).toSet();

  /// Pedaços que a [feitas]-ésima fase do mundo acabou de revelar (pode ser nenhum).
  Set<int> novos(int feitas) => visiveis(feitas).difference(visiveis(feitas - 1));

  /// Mundo (0 a 14) a que a fase pertence.
  static int mundoDaFase(int numero) => (numero - 1) ~/ Fase.porMundo;

  /// Posição da fase no seu mundo (1 a 20).
  static int posicaoNoMundo(int numero) => (numero - 1) % Fase.porMundo + 1;

  static Figura doMundo(int mundo) => todas[mundo % todas.length];

  /// Fases vencidas no [mundo], dado quantas estrelas cada fase tem (0 = ainda não venceu).
  static int feitasNoMundo(int mundo, int Function(int fase) estrelas) => [
    for (var i = 1; i <= Fase.porMundo; i++)
      if (estrelas(mundo * Fase.porMundo + i) > 0) i,
  ].length;

  static const todas = <Figura>[
    Figura(
      'Cupcake',
      ['....RR....', '..PPPPPP..', '.PPWPPWPP.', 'PPPPPPPPPP', '.YYYYYYYY.', '..YOYOYO..', '..YYYYYY..', '...YYYY...'],
      {'R': 0xFFFF2D55, 'P': 0xFFFF8FD0, 'W': 0xFFFFFFFF, 'Y': 0xFFFFC857, 'O': 0xFFE08A1E},
    ),
    Figura(
      'Peixinho',
      ['...CCCC...', 'D.CCCCCC..', 'DDCCWKCCC.', 'DDCCCCCCCC', 'DCCCCCCCC.', 'D.CCCCCC..', '...CCCC...', '..........'],
      {'C': 0xFF00D9FF, 'D': 0xFF2D6BFF, 'W': 0xFFFFFFFF, 'K': 0xFF14063F},
    ),
    Figura(
      'Vulcão',
      ['....OO....', '...ORRO...', '....RO....', '...GGGG...', '..GGGGGG..', '.GGGRRGGG.', 'GGGGRRGGGG', 'GGGGGGGGGG'],
      {'O': 0xFFFFB000, 'R': 0xFFFF3B1F, 'G': 0xFF6B5B73},
    ),
    Figura(
      'Pinheiro',
      ['....GG....', '...GGGG...', '..GGGGGG..', '...GGGG...', '..GGGGGG..', '.GGGGGGGG.', '....TT....', '....TT....'],
      {'G': 0xFF2BD96B, 'T': 0xFF9C6B3A},
    ),
    Figura(
      'Floco de neve',
      ['....WW....', '.W..WW..W.', '..W.WW.W..', '...WWWW...', 'WWWWIIWWWW', '...WWWW...', '..W.WW.W..', '.W..WW..W.'],
      {'W': 0xFFE8F6FF, 'I': 0xFF7BD0FF},
    ),
    Figura(
      'Cacto',
      ['....GG....', '..G.GG.G..', '..G.GG.G..', '..GGGGGG..', '....GG....', '....GG....', 'YYYYGGYYYY', 'YYYYYYYYYY'],
      {'G': 0xFF2BD96B, 'Y': 0xFFF2C46B},
    ),
    Figura(
      'Estrela',
      ['....YY....', '....YY....', 'YYYYYYYYYY', '.YYYYYYYY.', '..YYYYYY..', '..YYYYYY..', '.YYY..YYY.', '.YY....YY.'],
      {'Y': 0xFFFFD000},
    ),
    Figura(
      'Coração neon',
      ['.MM....MM.', 'MWMM..MMMM', 'MMMMMMMMMM', 'MMMMMMMMMM', '.MMMMMMMM.', '..MMMMMM..', '...MMMM...', '....MM....'],
      {'M': 0xFFFF2EC8, 'W': 0xFFFFD6F5},
    ),
    Figura(
      'Cristal',
      ['..CCCCCC..', '.CWCCCCCC.', 'CCCCCCCCCC', '.CCCCCCCC.', '..DDDDDD..', '...DDDD...', '....DD....', '..........'],
      {'C': 0xFF00E0FF, 'W': 0xFFFFFFFF, 'D': 0xFF2D7BFF},
    ),
    Figura(
      'Folha',
      ['......GGG.', '....GGGGG.', '..GGGGGGG.', '.GGGDGGGG.', '.GGDGGGG..', 'GGDGGGG...', 'D.GG......', 'D.........'],
      {'G': 0xFF2BD96B, 'D': 0xFF157A3D},
    ),
    Figura(
      'Nuvem',
      ['..........', '...WWW....', '..WWWWW.W.', '.WWWWWWWWW', 'WWWWWWWWWW', 'WWWWWWWWWW', '.SSSSSSSS.', '..........'],
      {'W': 0xFFFFFFFF, 'S': 0xFFBFD6FF},
    ),
    Figura(
      'Caveira',
      ['..WWWWWW..', '.WWWWWWWW.', 'WWWWWWWWWW', 'WKKWWWWKKW', 'WKKWWWWKKW', '.WWWKKWWW.', '..WWWWWW..', '..WKWKWKW.'],
      {'W': 0xFFF5F1FF, 'K': 0xFF14063F},
    ),
    Figura(
      'Robozinho',
      ['....RR....', '....GG....', '.GGGGGGGG.', '.GBBGGBBG.', '.GBBGGBBG.', '.GGGGGGGG.', '.GKKKKKKG.', '.GGGGGGGG.'],
      {'R': 0xFFFF3B5C, 'G': 0xFFAEB7D6, 'B': 0xFF00D9FF, 'K': 0xFF14063F},
    ),
    Figura(
      'Chama',
      ['....OO....', '....OO....', '...OOOO...', '..OORROO..', '.OORRRROO.', '.ORRYYRRO.', '.ORYYYYRO.', '..OYYYYO..'],
      {'O': 0xFFFF8A00, 'R': 0xFFFF3B1F, 'Y': 0xFFFFE066},
    ),
    Figura(
      'Arco-íris',
      ['..RRRRRR..', '.RRRRRRRR.', 'RROOOOOORR', 'ROOYYYYOOR', 'ROYYGGYYOR', 'ROYGBBGYOR', 'ROYG..GYOR', 'ROYG..GYOR'],
      {'R': 0xFFFF3B5C, 'O': 0xFFFF8A00, 'Y': 0xFFFFD000, 'G': 0xFF2BD96B, 'B': 0xFF3D8BFF},
    ),
  ];
}
