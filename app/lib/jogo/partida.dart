import 'marcos.dart';
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
    this.marcos = const [],
    this.joias = 0,
    this.bombas = 0,
    this.rachados = 0,
    this.descongelados = 0,
    this.raios = 0,
  });

  final int pontos;
  final int linhasLimpas;
  final int linhasDeUmaCor;
  final int combo;
  final bool tabuleiroLimpo;
  final List<BlocoRemovido> removidos;
  final int pedrasQuebradas;

  /// Metas de pontos alcançadas nesta jogada (só no Infinito).
  final List<Marco> marcos;

  /// Blocos especiais que saíram nesta jogada.
  /// [rachados]: gelo já descongelado que saiu agora (dá gema); [descongelados]: gelo que só rachou nesta jogada.
  final int joias, bombas, rachados, descongelados, raios;

  int get gemas => linhasDeUmaCor + (tabuleiroLimpo ? 3 : 0) + joias + rachados;
}

/// Regras de uma partida. Sem Flutter: dá para testar tudo em Dart puro.
class Partida {
  /// [inicial] é o tabuleiro de partida das fases (com pedras).
  Partida({required this.semente, Tabuleiro? inicial, this.cores = totalCores})
    : _sorteio = Sorteio(semente),
      tabuleiro = inicial ?? Tabuleiro() {
    _novaMao();
  }

  Partida._salva(this._sorteio, {this.semente = 0, this.cores = totalCores}) : tabuleiro = Tabuleiro();

  /// Semente do sorteio das peças desta partida (0 em partidas salvas antes de guardarmos a semente).
  final int semente;

  /// Quantas cores as peças podem ter.
  final int cores;

  /// Modo Infinito: tem metas de pontos e as peças ficam maiores a cada meta. Fases, Desafio e Arena (mesmas peças para
  /// todos) deixam desligado.
  bool rampa = false;

  /// Metas já pagas. Fora do "Desfazer" de propósito: desfazer e jogar de novo não paga a meta duas vezes.
  int marcosPagos = 0;

  /// Nível das peças: sobe a cada meta paga, até [Marcos.nivelMaximoDasPecas].
  int get nivel => rampa ? (marcosPagos < Marcos.nivelMaximoDasPecas ? marcosPagos : Marcos.nivelMaximoDasPecas) : 0;

  /// Para salvar no aparelho (o "Desfazer" não é salvo).
  Map<String, Object?> paraJson() => {
    'sorteio': _sorteio.estado,
    'semente': semente,
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
                if (p.especial > 0) ...{'esp': p.especial, 'ec': p.celulaEspecial},
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
    'rampa': rampa,
    'marcosPagos': marcosPagos,
    'cores': cores,
    'linhasDeUmaCor': linhasDeUmaCor,
    'maiorCombo': maiorCombo,
  };

  factory Partida.deJson(Map<String, Object?> j) {
    final p = Partida._salva(
      Sorteio.doEstado(j['sorteio']! as int),
      semente: (j['semente'] as int?) ?? 0,
      cores: (j['cores'] as int?) ?? totalCores,
    );
    final casas = (j['casas']! as List).cast<int?>();
    for (var i = 0; i < casas.length; i++) {
      p.tabuleiro.definir(i ~/ Tabuleiro.tamanho, i % Tabuleiro.tamanho, casas[i]);
    }
    p
      ..mao = [
        for (final m in j['mao']! as List)
          if (m case {'cor': final int cor, 'celulas': final List c})
            Peca(
              Formato([for (var i = 0; i < c.length; i += 2) (linha: c[i] as int, coluna: c[i + 1] as int)]),
              cor,
              especial: (m['esp'] as int?) ?? 0,
              celulaEspecial: (m['ec'] as int?) ?? 0,
            )
          else
            null,
      ]
      ..pontos = j['pontos']! as int
      ..combo = j['combo']! as int
      .._semLimpar = j['semLimpar']! as int
      ..continuou = j['continuou']! as bool
      ..jogadas = (j['jogadas'] as int?) ?? 0
      ..rampa = (j['rampa'] as bool?) ?? false
      ..linhas = (j['linhas'] as int?) ?? 0
      ..linhasDeUmaCor = (j['linhasDeUmaCor'] as int?) ?? 0
      ..maiorCombo = (j['maiorCombo'] as int?) ?? 0;
    // Partida salva antes das metas existirem: não paga retroativamente as que já passou.
    p.marcosPagos = (j['marcosPagos'] as int?) ?? Marcos.novas(p.pontos, 0).length;
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

  /// Jogadas seguidas sem limpar linha (o mascote dá dica a cada 5).
  int get semLimpar => _semLimpar;
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

    for (var i = 0; i < peca.formato.celulas.length; i++) {
      final c = peca.formato.celulas[i];
      final codigo = peca.especial > 0 && i == peca.celulaEspecial ? peca.especial * 10 + peca.cor : peca.cor;
      tabuleiro.definir(linha + c.linha, coluna + c.coluna, codigo);
    }
    final completas = tabuleiro.linhasCompletas();
    final casas = <(int, int)>{
      for (final l in completas.linhas)
        for (var k = 0; k < Tabuleiro.tamanho; k++) (l, k),
      for (final k in completas.colunas)
        for (var l = 0; l < Tabuleiro.tamanho; l++) (l, k),
    };
    final deUmaCor =
        [
          for (final l in completas.linhas) List.generate(Tabuleiro.tamanho, (k) => tabuleiro.cor(l, k)),
          for (final k in completas.colunas) List.generate(Tabuleiro.tamanho, (l) => tabuleiro.cor(l, k)),
        ].where((cores) {
          // O curinga vale por qualquer cor: fica de fora da comparação.
          final bases = cores.where((c) => !Tabuleiro.ehCuringa(c!)).map((c) => Tabuleiro.base(c!)).toSet();
          return bases.length == 1 && bases.first != Tabuleiro.pedra;
        }).length;
    // Bomba: ao sair com a linha, leva junto os blocos (menos pedras) da área 3x3 em volta dela.
    final todas = {...casas};
    var bombas = 0;
    for (final (l, k) in casas) {
      if (!Tabuleiro.ehBomba(tabuleiro.cor(l, k)!)) continue;
      bombas++;
      for (var dl = -1; dl <= 1; dl++) {
        for (var dk = -1; dk <= 1; dk++) {
          final vl = l + dl, vk = k + dk;
          if (vl < 0 || vk < 0 || vl >= Tabuleiro.tamanho || vk >= Tabuleiro.tamanho) continue;
          final c = tabuleiro.cor(vl, vk);
          if (c != null && c != Tabuleiro.pedra) todas.add((vl, vk));
        }
      }
    }
    // Raio: leva junto a outra linha ou coluna inteira que passa por ele (menos pedras).
    var raios = 0;
    for (final (l, k) in casas) {
      if (!Tabuleiro.ehRaio(tabuleiro.cor(l, k)!)) continue;
      raios++;
      for (var i = 0; i < Tabuleiro.tamanho; i++) {
        for (final (vl, vk) in [(l, i), (i, k)]) {
          final c = tabuleiro.cor(vl, vk);
          if (c != null && c != Tabuleiro.pedra) todas.add((vl, vk));
        }
      }
    }
    // Gelo: a primeira linha só descongela o bloco (vira "rachado" e fica); a segunda tira de verdade.
    final congelados = todas.where((c) => Tabuleiro.ehGelo(tabuleiro.cor(c.$1, c.$2)!)).toList();
    for (final (l, k) in congelados) {
      todas.remove((l, k));
    }
    final removidos = [for (final (l, k) in todas) (linha: l, coluna: k, cor: tabuleiro.cor(l, k)!)];
    final joias = removidos.where((b) => Tabuleiro.ehJoia(b.cor)).length;
    final rachados = removidos.where((b) => Tabuleiro.ehRachado(b.cor)).length;
    for (final (l, k) in todas) {
      tabuleiro.definir(l, k, null);
    }
    for (final (l, k) in congelados) {
      tabuleiro.definir(l, k, Tabuleiro.rachado * 10 + Tabuleiro.base(tabuleiro.cor(l, k)!));
    }

    final linhas = completas.linhas.length + completas.colunas.length;
    var ganho = peca.formato.celulas.length;
    final limpo = linhas > 0 && tabuleiro.vazio;
    if (linhas > 0) {
      combo++;
      _semLimpar = 0;
      ganho +=
          10 * linhas * linhas * combo +
          20 * deUmaCor +
          (limpo ? 300 : 0) +
          30 * joias +
          15 * bombas +
          15 * raios +
          20 * rachados;
    } else if (++_semLimpar >= folgaCombo) {
      combo = 0;
    }
    pontos += ganho;
    jogadas++;
    this.linhas += linhas;
    linhasDeUmaCor += deUmaCor;
    if (combo > maiorCombo) maiorCombo = combo;
    final novosMarcos = rampa ? Marcos.novas(pontos, marcosPagos) : const <Marco>[];
    marcosPagos += novosMarcos.length;

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
      marcos: novosMarcos,
      joias: joias,
      bombas: bombas,
      rachados: rachados,
      descongelados: congelados.length,
      raios: raios,
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

  /// Martelo: o bloco da casa pode ser tirado? Pedra não: ela só quebra completando a linha, senão o reforço
  /// venceria a fase.
  bool podeMartelar(int linha, int coluna) {
    if (linha < 0 || coluna < 0 || linha >= Tabuleiro.tamanho || coluna >= Tabuleiro.tamanho) return false;
    final cor = tabuleiro.cor(linha, coluna);
    return cor != null && cor != Tabuleiro.pedra;
  }

  /// Casas com bloco (sem pedras) no quadrado 3x3 centrado em (linha, coluna).
  List<({int linha, int coluna})> blocosDaBomba(int linha, int coluna) => [
    for (var l = linha - 1; l <= linha + 1; l++)
      for (var k = coluna - 1; k <= coluna + 1; k++)
        if (podeMartelar(l, k)) (linha: l, coluna: k),
  ];

  /// Tira um bloco. Devolve o que saiu (para a animação) ou lista vazia se não dava. Não conta linha nem ponto.
  List<BlocoRemovido> martelar(int linha, int coluna) =>
      _tirar([(linha: linha, coluna: coluna)].where((c) => podeMartelar(c.linha, c.coluna)));

  /// Bomba: tira os blocos do quadrado 3x3 em volta de (linha, coluna), menos as pedras.
  List<BlocoRemovido> explodir(int linha, int coluna) => _tirar(blocosDaBomba(linha, coluna));

  List<BlocoRemovido> _tirar(Iterable<({int linha, int coluna})> casas) {
    final removidos = [
      for (final c in casas) (linha: c.linha, coluna: c.coluna, cor: tabuleiro.cor(c.linha, c.coluna)!),
    ];
    if (removidos.isEmpty) return removidos;
    for (final b in removidos) {
      tabuleiro.definir(b.linha, b.coluna, null);
    }
    _anterior = null; // como o "Trocar": não dá para desfazer por cima de um reforço
    return removidos;
  }

  /// Segunda chance (uma por partida): limpa os blocos das 4 linhas do meio e dá mão nova.
  /// As pedras das fases ficam: só se quebram completando a linha, senão a ajuda venceria a fase.
  bool continuar() {
    if (continuou) return false;
    continuou = true;
    for (var l = 2; l < 6; l++) {
      for (var k = 0; k < Tabuleiro.tamanho; k++) {
        if (tabuleiro.cor(l, k) != Tabuleiro.pedra) tabuleiro.definir(l, k, null);
      }
    }
    _anterior = null;
    _novaMao();
    return true;
  }

  /// Sorteia 3 peças; tenta algumas vezes para que pelo menos uma caiba.
  void _novaMao() {
    for (var tentativa = 0; tentativa < 30; tentativa++) {
      final nova = List<Peca?>.generate(tamanhoMao, (_) => Peca.sortear(_sorteio, cores, nivel));
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
