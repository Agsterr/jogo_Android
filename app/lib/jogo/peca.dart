import 'sorteio.dart';

/// Uma célula relativa dentro da peça.
typedef Celula = ({int linha, int coluna});

/// Formato de peça (sem cor). Lista fixa, inspirada nos clássicos de blocos.
class Formato {
  const Formato(this.celulas, {this.peso = 2});

  final List<Celula> celulas;

  /// Chance relativa de sair no sorteio.
  final int peso;

  int get linhas => celulas.map((c) => c.linha).reduce(_max) + 1;
  int get colunas => celulas.map((c) => c.coluna).reduce(_max) + 1;

  static int _max(int a, int b) => a > b ? a : b;

  /// Monta um formato a partir de um desenho: `#` é bloco, `.` é vazio.
  factory Formato.desenho(List<String> linhas, {int peso = 2}) {
    final celulas = <Celula>[
      for (var l = 0; l < linhas.length; l++)
        for (var c = 0; c < linhas[l].length; c++)
          if (linhas[l][c] == '#') (linha: l, coluna: c),
    ];
    return Formato(celulas, peso: peso);
  }

  static final List<Formato> todos = [
    Formato.desenho(['#'], peso: 1),
    Formato.desenho(['##']),
    Formato.desenho(['#', '#']),
    Formato.desenho(['###'], peso: 3),
    Formato.desenho(['#', '#', '#'], peso: 3),
    Formato.desenho(['####']),
    Formato.desenho(['#', '#', '#', '#']),
    Formato.desenho(['#####'], peso: 1),
    Formato.desenho(['#', '#', '#', '#', '#'], peso: 1),
    Formato.desenho(['##', '##'], peso: 3),
    Formato.desenho(['###', '###', '###'], peso: 1),
    Formato.desenho(['##', '#.']),
    Formato.desenho(['##', '.#']),
    Formato.desenho(['#.', '##']),
    Formato.desenho(['.#', '##']),
    Formato.desenho(['#..', '#..', '###'], peso: 1),
    Formato.desenho(['###', '..#', '..#'], peso: 1),
    Formato.desenho(['###', '.#.']),
    Formato.desenho(['.#.', '###']),
    Formato.desenho(['##.', '.##']),
    Formato.desenho(['.##', '##.']),
    Formato.desenho(['#.', '#.', '##']),
    Formato.desenho(['##', '.#', '.#']),
  ];
}

/// Quantidade de cores de bloco (os tons ficam no tema).
const int totalCores = 6;

/// Peça na mão do jogador: formato + cor.
class Peca {
  const Peca(this.formato, this.cor);

  final Formato formato;
  final int cor;

  /// Sorteia uma peça usando só as [cores] primeiras cores (fases de "uma cor" usam menos).
  static Peca sortear(Sorteio sorteio, [int cores = totalCores]) {
    final pesoTotal = Formato.todos.fold(0, (s, f) => s + f.peso);
    var alvo = sorteio.proximo(pesoTotal);
    for (final f in Formato.todos) {
      if (alvo < f.peso) return Peca(f, sorteio.proximo(cores));
      alvo -= f.peso;
    }
    throw StateError('inalcançável');
  }
}
