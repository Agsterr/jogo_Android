import 'peca.dart';
import 'sorteio.dart';
import 'tabuleiro.dart';

/// Bloco que saiu do tabuleiro (para a animação).
typedef BlocoRemovido = ({int linha, int coluna, int cor});

/// O que aconteceu numa jogada; a tela usa para animar e dar gemas.
class Jogada {
  const Jogada({
    required this.pontos,
    required this.linhasLimpas,
    required this.linhasDeUmaCor,
    required this.combo,
    required this.tabuleiroLimpo,
    required this.removidos,
    this.pedrasQuebradas = 0,
  });

  final int pontos;
  final int linhasLimpas;
  final int linhasDeUmaCor;
  final int combo;
  final bool tabuleiroLimpo;
  final List<BlocoRemovido> removidos;
  final int pedrasQuebradas;

  int get gemas => linhasDeUmaCor + (tabuleiroLimpo ? 3 : 0);
}

/// Regras de uma partida. Sem Flutter: dá para testar tudo em Dart puro.
class Partida {
  /// [inicial] é o tabuleiro de partida das fases (com pedras).
  Partida({required int semente, Tabuleiro? inicial, this.cores = totalCores})
    : _sorteio = Sorteio(semente),
      tabuleiro = inicial ?? Tabuleiro() {
    _novaMao();
  }

  Partida._salva(this._sorteio, {this.cores = totalCores}) : tabuleiro = Tabuleiro();

  /// Quantas cores as peças podem ter.
  final int cores;

  /// Para salvar no aparelho (o "Desfazer" não é salvo).
  Map<String, Object?> paraJson() => {
    'sorteio': _sorteio.estado,
    'casas': [
      for (var l = 0; l < Tabuleiro.tamanho; l++)
        for (var k = 0; k < Tabuleiro.tamanho; k++) tabuleiro.cor(l, k),
    ],
    'mao': [
      for (final p in mao)
        p == null
            ? null
            : {
                'cor': p.cor,
                'celulas': [
                  for (final c in p.formato.celulas) ...[c.linha, c.coluna],
                ],
              },
    ],
    'pontos': pontos,
    'combo': combo,
    'semLimpar': _semLimpar,
    'continuou': continuou,
    'jogadas': jogadas,
    'linhas': linhas,
    'cores': cores,
    'linhasDeUmaCor': linhasDeUmaCor,
    'maiorCombo': maiorCombo,
  };

  factory Partida.deJson(Map<String, Object?> j) {
    final p = Partida._salva(Sorteio.doEstado(j['sorteio']! as int), cores: (j['cores'] as int?) ?? totalCores);
    final casas = (j['casas']! as List).cast<int?>();
    for (var i = 0; i < casas.length; i++) {
      p.tabuleiro.definir(i ~/ Tabuleiro.tamanho, i % Tabuleiro.tamanho, casas[i]);
    }
    p
      ..mao = [
        for (final m in j['mao']! as List)
          if (m case {'cor': final int cor, 'celulas': final List c})
            Peca(Formato([for (var i = 0; i < c.length; i += 2) (linha: c[i] as int, coluna: c[i + 1] as int)]), cor)
          else
            null,
      ]
      ..pontos = j['pontos']! as int
      ..combo = j['combo']! as int
      .._semLimpar = j['semLimpar']! as int
      ..continuou = j['continuou']! as bool
      ..jogadas = (j['jogadas'] as int?) ?? 0
      ..linhas = (j['linhas'] as int?) ?? 0
      ..linhasDeUmaCor = (j['linhasDeUmaCor'] as int?) ?? 0
      ..maiorCombo = (j['maiorCombo'] as int?) ?? 0;
    return p;
  }

  static const int tamanhoMao = 3;

  /// Jogadas seguidas sem limpar linha que ainda mantêm o combo.
  static const int folgaCombo = 3;

  final Sorteio _sorteio;
  Tabuleiro tabuleiro;

  /// Peças colocadas nesta partida (as fases têm limite).
  int jogadas = 0;

  /// Linhas e colunas limpas na partida toda.
  int linhas = 0;

  /// Linhas de uma cor só limpas e maior combo da partida (objetivos das fases).
  int linhasDeUmaCor = 0;
  int maiorCombo = 0;
  List<Peca?> mao = const [];
  int pontos = 0;
  int combo = 0;
  int _semLimpar = 0;
  bool continuou = false;
  _Estado? _anterior;

  bool get podeDesfazer => _anterior != null;

  bool get fimDeJogo => mao.whereType<Peca>().every((p) => !tabuleiro.cabeEmAlgumLugar(p.formato));

  bool podeColocar(int indice, int linha, int coluna) {
    final peca = mao[indice];
    return peca != null && tabuleiro.cabe(peca.formato, linha, coluna);
  }

  /// Coloca a peça da mão. Devolve `null` se não couber.
  Jogada? colocar(int indice, int linha, int coluna) {
    if (!podeColocar(indice, linha, coluna)) return null;
    final peca = mao[indice]!;
    _anterior = _Estado(this);

    for (final c in peca.formato.celulas) {
      tabuleiro.definir(linha + c.linha, coluna + c.coluna, peca.cor);
    }
    final completas = tabuleiro.linhasCompletas();
    final casas = <(int, int)>{
      for (final l in completas.linhas)
        for (var k = 0; k < Tabuleiro.tamanho; k++) (l, k),
      for (final k in completas.colunas)
        for (var l = 0; l < Tabuleiro.tamanho; l++) (l, k),
    };
    final deUmaCor = [
      for (final l in completas.linhas) List.generate(Tabuleiro.tamanho, (k) => tabuleiro.cor(l, k)),
      for (final k in completas.colunas) List.generate(Tabuleiro.tamanho, (l) => tabuleiro.cor(l, k)),
    ].where((cores) => cores.toSet().length == 1 && cores.first != Tabuleiro.pedra).length;
    final removidos = [for (final (l, k) in casas) (linha: l, coluna: k, cor: tabuleiro.cor(l, k)!)];
    for (final (l, k) in casas) {
      tabuleiro.definir(l, k, null);
    }

    final linhas = completas.linhas.length + completas.colunas.length;
    var ganho = peca.formato.celulas.length;
    final limpo = linhas > 0 && tabuleiro.vazio;
    if (linhas > 0) {
      combo++;
      _semLimpar = 0;
      ganho += 10 * linhas * linhas * combo + 20 * deUmaCor + (limpo ? 300 : 0);
    } else if (++_semLimpar >= folgaCombo) {
      combo = 0;
    }
    pontos += ganho;
    jogadas++;
    this.linhas += linhas;
    linhasDeUmaCor += deUmaCor;
    if (combo > maiorCombo) maiorCombo = combo;

    mao = [...mao]..[indice] = null;
    if (mao.every((p) => p == null)) _novaMao();

    return Jogada(
      pontos: ganho,
      linhasLimpas: linhas,
      linhasDeUmaCor: deUmaCor,
      combo: linhas > 0 ? combo : 0,
      tabuleiroLimpo: limpo,
      removidos: removidos,
      pedrasQuebradas: removidos.where((b) => b.cor == Tabuleiro.pedra).length,
    );
  }

  /// Volta uma jogada (um nível só).
  bool desfazer() {
    final anterior = _anterior;
    if (anterior == null) return false;
    anterior.restaurar(this);
    _anterior = null;
    return true;
  }

  /// Reforço "Trocar": sorteia uma mão nova.
  void trocarMao() {
    _anterior = null;
    _novaMao();
  }

  /// Segunda chance (uma por partida): limpa as 4 linhas do meio e dá mão nova.
  bool continuar() {
    if (continuou) return false;
    continuou = true;
    for (var l = 2; l < 6; l++) {
      for (var k = 0; k < Tabuleiro.tamanho; k++) {
        tabuleiro.definir(l, k, null);
      }
    }
    _anterior = null;
    _novaMao();
    return true;
  }

  /// Sorteia 3 peças; tenta algumas vezes para que pelo menos uma caiba.
  void _novaMao() {
    for (var tentativa = 0; tentativa < 30; tentativa++) {
      final nova = List<Peca?>.generate(tamanhoMao, (_) => Peca.sortear(_sorteio, cores));
      mao = nova;
      if (nova.any((p) => tabuleiro.cabeEmAlgumLugar(p!.formato))) return;
    }
  }
}

class _Estado {
  _Estado(Partida p)
    : tabuleiro = p.tabuleiro.copia(),
      mao = List.of(p.mao),
      pontos = p.pontos,
      jogadas = p.jogadas,
      linhas = p.linhas,
      umaCor = p.linhasDeUmaCor,
      maiorCombo = p.maiorCombo,
      combo = p.combo,
      semLimpar = p._semLimpar,
      sorteio = p._sorteio.copia();

  final Tabuleiro tabuleiro;
  final List<Peca?> mao;
  final int pontos, jogadas, linhas, umaCor, maiorCombo, combo, semLimpar;
  final Sorteio sorteio;

  void restaurar(Partida p) {
    p
      ..tabuleiro = tabuleiro
      ..mao = mao
      ..pontos = pontos
      ..jogadas = jogadas
      ..linhas = linhas
      ..linhasDeUmaCor = umaCor
      ..maiorCombo = maiorCombo
      ..combo = combo
      .._semLimpar = semLimpar;
    p._sorteio.restaurarDe(sorteio);
  }
}
