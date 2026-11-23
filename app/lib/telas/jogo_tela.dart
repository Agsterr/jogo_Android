import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../jogo/album.dart';
import '../jogo/amigo.dart';
import '../jogo/arena.dart';
import '../jogo/eventos.dart';
import '../jogo/elogios.dart';
import '../jogo/fases.dart';
import '../jogo/marcos.dart';
import '../jogo/missoes.dart';
import '../jogo/partida.dart';
import '../jogo/passe.dart';
import '../jogo/peca.dart';
import '../jogo/sorteio.dart';
import '../jogo/tabuleiro.dart';
import '../servicos/servicos.dart';
import '../servicos/sons.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/mascote.dart';
import '../widgets/peca_widget.dart';
import '../widgets/tabuleiro_widget.dart';
import 'loja_tela.dart';
import 'mapa_tela.dart';
import 'roleta_partida.dart';
import '../idioma.dart';

/// Preço dos reforços e da segunda chance, em gemas.
abstract final class Custos {
  static const desfazer = 3;
  static const trocar = 5;
  static const martelo = 4;
  static const bomba = 8;
  static const continuar = 10;
}

enum _Fim { segundaChance, resultado, faseVencida, faseFalhou }

/// Reforço de tabuleiro que espera o jogador tocar num alvo.
enum _Reforco { martelo, bomba }

class JogoTela extends StatefulWidget {
  const JogoTela({
    super.key,
    required this.servicos,
    this.diario = false,
    this.arena = false,
    this.fase,
    this.partida,
    this.amigo,
    this.relampago = false,
    this.duracao = const Duration(seconds: 60),
  });

  final Servicos servicos;

  /// Desafio do dia: semente fixa para todos.
  final bool diario;

  /// Arena da semana: semente fixa da semana, vale a melhor partida.
  final bool arena;

  /// Modo Fases: objetivo e limite de peças.
  final Fase? fase;

  /// Desafio de amigo: as mesmas peças dele, com a pontuação dele para bater.
  final DesafioAmigo? amigo;

  /// Modo Relâmpago: o tempo corre a partir da primeira jogada e a partida acaba quando ele zera.
  final bool relampago;

  /// Duração do Relâmpago (os testes usam menos).
  final Duration duracao;

  /// Partida pronta (usada nos testes e nas capturas de tela).
  final Partida? partida;

  @override
  State<JogoTela> createState() => _JogoTelaState();
}

class _JogoTelaState extends State<JogoTela> {
  final _chaveTabuleiro = GlobalKey();
  final _chavePalco = GlobalKey();
  late Partida _partida;
  late int _dia;

  int? _arrastando;
  Offset? _dedo;
  Previa? _previa;
  double _casa = 40;

  List<BlocoRemovido> _removidos = const [];
  int _geracao = 0;
  _AvisoDeJogada? _aviso;

  _Fim? _fim;
  bool _novoRecorde = false;
  int _gemasDesafio = 0;
  int _gemasAmigo = 0;
  int _gemasRelampago = 0;

  // Mascote durante a partida: comemora, avisa e dá dicas.
  String? _fala;
  Humor _humorMascote = Humor.feliz;
  Timer? _falaTimer;

  // Relâmpago: tempo que falta, contado em passos de 250 ms (assim os testes controlam o relógio).
  static const _passo = Duration(milliseconds: 250);
  Timer? _relogio;
  late int _restanteMs = widget.duracao.inMilliseconds;
  bool _comecou = false;
  ({Album album, Figurinha figurinha, bool completou})? _figurinhaNova;
  ({Faixa faixa, int gemas})? _faixaNova;
  int _bausNovos = 0;

  /// Fases: peças extras ganhas na ajuda (uma ajuda por tentativa).
  int _extras = 0;
  bool _ajudou = false;
  int _gemasFase = 0;

  Servicos get _s => widget.servicos;

  @override
  void dispose() {
    _relogio?.cancel();
    _falaTimer?.cancel();
    super.dispose();
  }

  void _iniciarRelogio() {
    if (!widget.relampago || _comecou) return;
    _comecou = true;
    _relogio = Timer.periodic(_passo, (_) {
      if (!mounted || _fim != null) return _relogio?.cancel();
      setState(() => _restanteMs = math.max(0, _restanteMs - _passo.inMilliseconds));
      if (_restanteMs == 0) _tempoEsgotado();
    });
  }

  void _mascoteDiz(String texto, Humor humor) {
    _falaTimer?.cancel();
    setState(() {
      _fala = texto;
      _humorMascote = humor;
    });
    _falaTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _fala = null;
          _humorMascote = Humor.feliz;
        });
      }
    });
  }

  void _tempoEsgotado() {
    _relogio?.cancel();
    if (_fim != null) return;
    _s.sons.tocar(Som.fim);
    _arrastando = null;
    _previa = null;
    setState(() => _fim = _Fim.resultado);
    _encerrar();
  }

  @visibleForTesting
  Partida get partidaParaTeste => _partida;

  @visibleForTesting
  void iniciarRelogioParaTeste() => _iniciarRelogio();

  @visibleForTesting
  void mascoteDizParaTeste(String texto, Humor humor) => _mascoteDiz(texto, humor);

  @override
  void initState() {
    super.initState();
    _dia = Sorteio.sementeDoDia(_s.hoje());
    _partida = widget.partida ?? _partidaSalva() ?? _novaPartida();
    if (_partida.fimDeJogo) _fim = _partida.continuou ? _Fim.resultado : _Fim.segundaChance;
    if (widget.fase?.numero == 1 && _s.mostrarDicas && !_s.progresso.dicaVista('tutorial')) _tutorial = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _dicaDeEntrada());
  }

  /// Explica o modo na primeira vez que o jogador entra nele.
  Future<void> _dicaDeEntrada() async {
    if (!mounted || _tutorial != null) return;
    final dica = switch (widget.fase?.objetivo) {
      Objetivo.pedras => Dicas.pedras,
      Objetivo.pontos => Dicas.pontos,
      Objetivo.umaCor => Dicas.umaCor,
      Objetivo.combo => Dicas.combo,
      Objetivo.linhas => null,
      null =>
        widget.arena
            ? Dicas.arena
            : (widget.diario ? Dicas.desafio : (widget.relampago ? Dicas.relampago : Dicas.infinito)),
    };
    if (dica != null) await mostrarDicaUmaVez(context, _s, dica);
    // Quem já conhece o modo vê, uma vez só, os reforços novos.
    if (mounted && _tutorial == null) await mostrarDicaUmaVez(context, _s, Dicas.reforcos);
  }

  // ---------- tutorial da fase 1 ----------

  /// Passo do tutorial (0: arrastar, 1: encher linha, 2: objetivo) ou `null` se não há tutorial.
  int? _tutorial;

  static List<String> get _textosTutorial => [
    t('Segure uma peça aqui embaixo e arraste até o tabuleiro.'),
    t('Isso! Agora encha uma linha ou coluna INTEIRA: ela some e dá pontos.'),
    t(
      'Muito bem! O objetivo da fase fica lá em cima. Cumpra antes de acabar as peças: quanto mais peças sobrarem, mais estrelas!',
    ),
  ];

  void _avancarTutorial(Jogada jogada) {
    final passo = _tutorial;
    if (passo == 0) _tutorial = 1;
    if (passo == 1 && jogada.linhasLimpas > 0) _tutorial = 2;
  }

  void _terminarTutorial() {
    _s.progresso.marcarDica('tutorial');
    setState(() => _tutorial = null);
  }

  /// Clássico e Desafio têm partidas salvas separadas.
  String get _chave => widget.arena
      ? 'arena'
      : (widget.diario ? 'desafio' : (widget.amigo != null ? 'amigo' : (widget.relampago ? 'relampago' : 'classico')));

  int get _semana => Arena.semana(_s.hoje());

  Partida? _partidaSalva() {
    if (widget.fase != null || widget.amigo != null || widget.relampago) return null; // estes sempre começam do zero
    final json = _s.progresso.partidaSalva(_chave);
    if (json == null || (widget.diario && json['dia'] != _dia)) return null;
    if (widget.arena && json['semana'] != _semana) return null;
    try {
      return Partida.deJson(json)..rampa = _infinito;
    } on Object {
      return null; // formato antigo ou corrompido: começa de novo
    }
  }

  void _salvar() => widget.fase != null || widget.amigo != null || widget.relampago
      ? null
      : _s.progresso.salvarPartida(_chave, {..._partida.paraJson(), 'dia': _dia, 'semana': _semana});

  /// Infinito: o único modo com metas de pontos e peças que ficam maiores (os outros têm peças iguais para todos).
  bool get _infinito =>
      widget.fase == null &&
      !widget.diario &&
      !widget.arena &&
      !widget.relampago &&
      (widget.amigo == null || widget.amigo!.infinito);

  Partida _novaPartida() =>
      (widget.fase?.novaPartida() ??
            Partida(
              semente: widget.amigo != null
                  ? widget.amigo!.semente
                  : widget.arena
                  ? Arena.semente(_s.hoje())
                  : (widget.diario ? _dia : DateTime.now().microsecondsSinceEpoch),
            ))
        ..rampa = _infinito;

  // ---------- arrastar e soltar ----------

  void _pegar(int indice, Offset global) {
    if (_partida.mao[indice] == null || _fim != null) return;
    HapticFeedback.selectionClick();
    setState(() => _arrastando = indice);
    _mover(global);
  }

  /// Canto superior esquerdo da peça arrastada (fica acima do dedo para ser vista).
  Offset _cantoDaPeca(Peca peca, Offset dedo) {
    final w = peca.formato.colunas * _casa, h = peca.formato.linhas * _casa;
    return dedo - Offset(w / 2, h + _casa * 1.2);
  }

  void _mover(Offset global) {
    final i = _arrastando;
    if (i == null) return;
    final peca = _partida.mao[i]!;
    final caixa = _chaveTabuleiro.currentContext?.findRenderObject() as RenderBox?;
    Previa? previa;
    if (caixa != null) {
      final local = caixa.globalToLocal(_cantoDaPeca(peca, global));
      final linha = (local.dy / _casa).round(), coluna = (local.dx / _casa).round();
      final perto = linha > -2 && coluna > -2 && linha < 9 && coluna < 9;
      if (perto && _partida.podeColocar(i, linha, coluna)) {
        final cheias = _partida.tabuleiro.linhasCompletasCom(peca.formato, linha, coluna);
        previa = Previa(peca, linha, coluna, valida: true, linhas: cheias.linhas, colunas: cheias.colunas);
      }
    }
    setState(() {
      _dedo = global;
      _previa = previa;
    });
  }

  void _soltar() {
    final i = _arrastando, previa = _previa;
    setState(() {
      _arrastando = null;
      _dedo = null;
      _previa = null;
    });
    if (i == null || previa == null) return;
    final jogada = _partida.colocar(i, previa.linha, previa.coluna);
    if (jogada == null) return;
    _aposJogada(jogada);
  }

  void _aposJogada(Jogada jogada) {
    final elogio = elogioDaJogada(jogada);
    if (elogio != null) {
      elogio.nivel >= 3 ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();
      _s.sons.tocar(switch (elogio.nivel) {
        1 => Som.linha,
        2 => Som.combo,
        3 => Som.incrivel,
        _ => Som.fantastico,
      });
      _removidos = jogada.removidos;
    } else {
      HapticFeedback.lightImpact();
      _s.sons.tocar(Som.encaixe);
    }
    final gemasDaJogada = jogada.gemas * multiplicadorDeGemas(_s.hoje());
    final gemasDasMetas = jogada.marcos.fold(0, (soma, m) => soma + m.gemas);
    if (jogada.marcos.isNotEmpty && elogio == null) _s.sons.tocar(Som.combo);
    if (elogio != null || jogada.marcos.isNotEmpty) {
      _geracao++;
      _aviso = _AvisoDeJogada(
        id: _geracao,
        titulo:
            (elogio != null ? t(elogio.texto) : null) ?? t('Meta {0}!', [Marcos.formatar(jogada.marcos.last.pontos)]),
        nivel: elogio?.nivel ?? 2,
        detalhes: [
          if (elogio != null && jogada.combo >= 2) t('Combo x{0}', [jogada.combo]),
          if (elogio != null) '+${jogada.pontos}',
          if (gemasDaJogada > 0) _textoGemas(gemasDaJogada),
          for (final m in jogada.marcos)
            if (elogio != null)
              t('Meta {0}! {1}', [Marcos.formatar(m.pontos), _textoGemas(m.gemas)])
            else
              _textoGemas(m.gemas),
          // Só avisa "peças maiores" enquanto o nível ainda sobe.
          if (jogada.marcos.isNotEmpty && _partida.marcosPagos <= Marcos.nivelMaximoDasPecas)
            t('Nível {0}: peças maiores', [_partida.marcosPagos + 1]),
        ],
      );
    }
    _iniciarRelogio();
    if (_tutorial == null && widget.fase == null) {
      final fala = falaAposJogada(
        elogioNivel: elogio?.nivel ?? 0,
        elogioTexto: elogio == null ? null : t(elogio.texto),
        semLimpar: _partida.semLimpar,
        ocupadas: _partida.tabuleiro.ocupadas,
        jogadas: _partida.jogadas,
      );
      if (fala != null) _mascoteDiz(fala.texto, fala.humor);
    }
    _s.progresso.registrarJogada(linhas: jogada.linhasLimpas, combo: jogada.combo);
    _s.progresso.ganharGemas(gemasDaJogada + gemasDasMetas);
    _s.progresso.contarMissoes(_dia, contagemDaJogada(jogada));
    _avancarTutorial(jogada);
    _salvar();
    setState(() {});
    // Primeira vez que aparece um bloco especial na mão: explica o que ele faz.
    if (_partida.mao.any((p) => p != null && p.especial > 0) && _fim == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) mostrarDicaUmaVez(context, _s, Dicas.especiais);
      });
    }
    if (widget.fase case final fase?) {
      _conferirFase(fase);
      return;
    }
    if (_partida.fimDeJogo) {
      _s.sons.tocar(Som.fim);
      if (widget.relampago) {
        _relogio?.cancel();
        _encerrar(); // sem segunda chance: o tempo é o limite
      } else if (_partida.continuou) {
        _encerrar();
      } else {
        setState(() => _fim = _Fim.segundaChance);
      }
    }
  }

  static String _formatarTempo(int ms) {
    final s = (ms / 1000).ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  String _textoGemas(int n) => '+$n ${t(n == 1 ? 'gema' : 'gemas')}';

  // ---------- fases ----------

  int _restantes(Fase fase) => fase.pecasRestantes(_partida) + _extras;

  Future<void> _conferirFase(Fase fase) async {
    if (fase.concluida(_partida)) {
      if (_tutorial != null) _terminarTutorial();
      _s.sons.tocar(Som.combo);
      // Quem precisou de ajuda leva no máximo 1 estrela.
      final estrelas = _ajudou ? 1 : fase.estrelas(_partida);
      final gemas = await _s.progresso.concluirFase(fase.numero, estrelas);
      if (gemas > 0) await _s.progresso.ganharXpDoPasse(_dia, XpDoPasse.fase(estrelas));
      await _s.progresso.contarMissoes(_dia, {
        TipoMissao.partidas: 1,
        TipoMissao.fases: 1,
        if (estrelas == 3) TipoMissao.tresEstrelas: 1,
      });
      if (mounted) {
        setState(() {
          _gemasFase = gemas;
          _fim = _Fim.faseVencida;
        });
        await mostrarRoletaDaPartida(context, _s);
      }
    } else if (_restantes(fase) <= 0 || _partida.fimDeJogo) {
      _s.sons.tocar(Som.fim);
      setState(() => _fim = _Fim.faseFalhou);
    }
  }

  /// Sem peças: +5 peças. Sem espaço: limpa o meio do tabuleiro.
  void _ajudarNaFase() => setState(() {
    _ajudou = true;
    if (_partida.fimDeJogo) {
      _partida.continuar();
    } else {
      _extras += 5;
    }
    _fim = null;
  });

  Future<void> _ajudaComAnuncio() async {
    if (await _s.anuncios.mostrarPremiado()) {
      _ajudarNaFase();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('Anúncio indisponível agora. Tente de novo.'))));
    }
  }

  Future<void> _ajudaComGemas() async {
    if (await _s.progresso.gastarGemas(Custos.continuar)) _ajudarNaFase();
  }

  Future<void> _irParaFase(int numero) async {
    await _intersticial();
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => JogoTela(servicos: _s, fase: Fase.numero(numero)),
      ),
    );
  }

  // ---------- reforços e fim ----------

  _Reforco? _reforcoAtivo;

  /// Martelo e Bomba: toque no botão, escolha o alvo no tabuleiro. Tocar no botão de novo cancela.
  void _alternarReforco(_Reforco reforco, int custo) {
    if (_fim != null) return;
    if (_reforcoAtivo == reforco) {
      setState(() => _reforcoAtivo = null);
      return;
    }
    if (_s.progresso.gemas < custo) {
      _abrirLoja();
      return;
    }
    setState(() => _reforcoAtivo = reforco);
  }

  void _avisarNoTabuleiro(String texto) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(texto), duration: const Duration(seconds: 2)));

  Future<void> _tocouNoTabuleiro(TapUpDetails toque) async {
    final reforco = _reforcoAtivo;
    final caixa = _chaveTabuleiro.currentContext?.findRenderObject() as RenderBox?;
    if (reforco == null || caixa == null || _fim != null) return;
    final local = caixa.globalToLocal(toque.globalPosition);
    final linha = (local.dy / _casa).floor(), coluna = (local.dx / _casa).floor();
    final martelo = reforco == _Reforco.martelo;
    if (martelo ? !_partida.podeMartelar(linha, coluna) : _partida.blocosDaBomba(linha, coluna).isEmpty) {
      _avisarNoTabuleiro(
        _partida.tabuleiro.cor(linha, coluna) == Tabuleiro.pedra
            ? t('Pedra só quebra completando a linha ou a coluna dela.')
            : (martelo ? t('Toque num bloco colorido.') : t('Não tem bloco colorido nessa área.')),
      );
      return;
    }
    if (!await _s.progresso.gastarGemas(martelo ? Custos.martelo : Custos.bomba)) {
      setState(() => _reforcoAtivo = null);
      _abrirLoja();
      return;
    }
    final removidos = martelo ? _partida.martelar(linha, coluna) : _partida.explodir(linha, coluna);
    HapticFeedback.mediumImpact();
    _s.sons.tocar(Som.linha);
    _removidos = removidos;
    _geracao++;
    _salvar();
    if (mounted) setState(() => _reforcoAtivo = null);
  }

  Future<void> _usarReforco(int custo, bool Function() acao) async {
    if (!await _s.progresso.gastarGemas(custo)) {
      _abrirLoja();
      return;
    }
    setState(() => acao());
    _salvar();
  }

  void _abrirLoja() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LojaTela(servicos: _s)));

  void _continuar() {
    setState(() {
      _partida.continuar();
      _salvar();
      _fim = null;
    });
  }

  Future<void> _continuarComAnuncio() async {
    if (await _s.anuncios.mostrarPremiado()) {
      _continuar();
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('Anúncio indisponível agora. Tente de novo.'))));
    }
  }

  Future<void> _continuarComGemas() async {
    if (await _s.progresso.gastarGemas(Custos.continuar)) _continuar();
  }

  Future<void> _encerrar() async {
    await _s.progresso.apagarPartida(_chave);
    final pontos = _partida.pontos;
    final recorde = widget.relampago
        ? await _s.progresso.fimDoRelampago(pontos)
        : await _s.progresso.fimDePartida(pontos);
    await _s.progresso.ganharXpDaPartida(_dia);
    // Ranking mundial: só o Infinito, o Desafio e a Arena (modos de pontuação cheia).
    if (widget.fase == null && !widget.relampago && widget.amigo == null) _s.ranking.enviar(pontos);
    final gemasRelampago = widget.relampago ? gemasDoRelampago(pontos) : 0;
    if (gemasRelampago > 0) await _s.progresso.ganharGemas(gemasRelampago);
    await _s.progresso.contarMissoes(_dia, {TipoMissao.partidas: 1, TipoMissao.pontos: pontos});
    if (widget.diario) _s.progresso.pegarBausNovos(); // zera: só conta o que este Desafio der
    final gemasDesafio = widget.diario ? await _s.progresso.concluirDesafio(_dia, pontos) : 0;
    final gemasAmigo = widget.amigo == null ? 0 : await _s.progresso.concluirDesafioDeAmigo(widget.amigo!, pontos);
    if (gemasAmigo > 0) await _s.progresso.ganharXpDoPasse(_dia, XpDoPasse.amigo);
    if (widget.diario) _figurinhaNova = _s.progresso.pegarFigurinhaRecente();
    if (widget.diario) _faixaNova = _s.progresso.pegarFaixaRecente();
    if (widget.diario) _bausNovos = _s.progresso.pegarBausNovos();
    if (widget.diario) _s.reagendarLembrete(); // hoje já jogou: o próximo lembrete passa para amanhã
    if (widget.arena) {
      await _s.progresso.registrarArena(_semana, pontos);
      await _s.progresso.contarMissao(_dia, TipoMissao.arena, 1);
    }
    if (!mounted) return;
    setState(() {
      _novoRecorde = recorde;
      _gemasDesafio = gemasDesafio;
      _gemasAmigo = gemasAmigo;
      _gemasRelampago = gemasRelampago;
      _fim = _Fim.resultado;
    });
    await mostrarRoletaDaPartida(context, _s);
  }

  Future<void> _intersticial() async {
    if (_s.progresso.livreDeAnuncios) return;
    await _s.anuncios.talvezIntersticial(partidasJogadas: _s.progresso.partidas);
  }

  Future<void> _jogarDeNovo() async {
    await _intersticial();
    setState(() {
      _partida = _novaPartida();
      _relogio?.cancel();
      _comecou = false;
      _restanteMs = widget.duracao.inMilliseconds;
      _fim = null;
      _novoRecorde = false;
      _removidos = const [];
      _aviso = null;
    });
  }

  Future<void> _irParaMapa() async {
    await _intersticial();
    if (mounted) MapaTela.abrir(context, _s);
  }

  Future<void> _sair() async {
    await _intersticial();
    if (mounted) Navigator.of(context).pop();
  }

  void _compartilhar() {
    final texto = widget.arena
        ? t(
            'Encaixa 🏆 Arena da semana\n⭐ {0} pontos{1}\nMesmas peças para todo mundo até domingo. Consegue me passar?\n{2}',
            [
              _partida.pontos,
              Arena.trofeuPara(_partida.pontos) == null ? '' : ' · ${t(Arena.trofeuPara(_partida.pontos)!.nome)}',
              linkDaLoja,
            ],
          )
        : widget.diario
        ? t('Encaixa 🧩 Desafio #{0}\n⭐ {1} pontos\nMesmas peças para todo mundo. Consegue me passar?\n{2}', [
            numeroDoDesafio(_s.hoje()),
            _partida.pontos,
            linkDaLoja,
          ])
        : widget.relampago
        ? t('Fiz {0} pontos em 60 segundos no Encaixa ⚡ Consegue me passar?\n{1}', [_partida.pontos, linkDaLoja])
        : t('Fiz {0} pontos no Encaixa 🧩 Consegue me passar?\n{1}', [_partida.pontos, linkDaLoja]);
    final codigo = widget.fase != null || _partida.semente <= 0
        ? null
        : DesafioAmigo(semente: _partida.semente, pontos: _partida.pontos, infinito: _infinito).codigo;
    final completo = codigo == null
        ? texto
        : t('{0}\n\nQuer jogar com as mesmas peças que eu? No Encaixa, toque em "Código de amigo" e cole:\n{1}', [
            texto,
            codigo,
          ]);
    SharePlus.instance.share(ShareParams(text: completo));
  }

  // ---------- tela ----------

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoJogo(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // Reserva espaço para topo, placar, mão (2,5 casas) e reforços.
            final reserva = _partida.rampa ? 282 : 250;
            final lado = math.min(c.maxWidth - 24, (c.maxHeight - reserva) / 1.33);
            _casa = lado / 8;
            // O mascote só aparece se sobrar espaço sem encolher o tabuleiro (telas altas).
            final cabeMascote = (c.maxHeight - reserva - 76) / 1.33 >= c.maxWidth - 24;
            return Stack(
              key: _chavePalco,
              children: [
                Column(
                  children: [
                    _barraDoTopo(),
                    _placar(),
                    const Spacer(),
                    _tabuleiro(lado),
                    if (cabeMascote && widget.fase == null && _fim == null && _tutorial == null) _faixaDoMascote(),
                    const Spacer(),
                    _mao(),
                    _reforcos(),
                    const SizedBox(height: 8),
                  ],
                ),
                if (_tutorial case final passo? when _fim == null)
                  Positioned(
                    left: 16,
                    right: 16,
                    // Passo 0: logo acima da mão. Passo 1: sobre o placar. Passo 2: abaixo do objetivo.
                    bottom: passo == 0 ? _casa * 2.5 + 16 + 70 : null,
                    top: passo == 0 ? null : (passo == 1 ? 44 : 150),
                    child: BalaoTutorial(
                      texto: _textosTutorial[passo],
                      mostrarMao: passo == 0,
                      aoEntender: passo == 2 ? _terminarTutorial : null,
                    ),
                  ),
                if (_arrastando != null && _dedo != null) _pecaNoDedo(),
                if (_fim != null) _painelDoFim(),
              ],
            );
          },
        ),
      ),
    ),
  );

  /// Quadrinho ao lado do tabuleiro, com um balão quando tem algo a dizer.
  Widget _faixaDoMascote() => SizedBox(
    height: 60,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          Mascote(humor: _humorMascote, tamanho: 48),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (atual, anteriores) =>
                  Stack(alignment: Alignment.centerLeft, children: [...anteriores, ?atual]),
              child: _fala == null
                  ? const SizedBox.shrink(key: ValueKey('sem-fala'))
                  : Container(
                      key: ValueKey(_fala),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Cores.painel.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _fala!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.15),
                      ),
                    ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _barraDoTopo() => ListenableBuilder(
    listenable: _s.progresso,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: t('Voltar'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          if (widget.fase case final fase?)
            Text(
              t('FASE {0}', [fase.numero]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          if (widget.arena)
            Text(
              t('ARENA DA SEMANA'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          if (widget.relampago)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _restanteMs <= 10000 && _comecou ? Cores.destaque : Cores.painel.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, size: 20),
                  Text(
                    ' ${_formatarTempo(_restanteMs)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          if (widget.amigo case final amigo?)
            Text(
              t('AMIGO: {0}', [amigo.pontos]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          if (widget.diario)
            Text(
              t('DESAFIO #{0}', [numeroDoDesafio(_s.hoje())]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          const Spacer(),
          GemasChip(gemas: _s.progresso.gemas, aoTocar: _abrirLoja),
        ],
      ),
    ),
  );

  Widget _placar() => widget.fase == null ? _placarDePontos() : _placarDaFase(widget.fase!);

  Widget _placarDaFase(Fase fase) {
    final feito = fase.progresso(_partida).clamp(0, fase.alvo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            fase.texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: feito / fase.alvo,
                    minHeight: 12,
                    backgroundColor: Cores.casa,
                    color: Cores.blocos[3],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$feito/${fase.alvo}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: _restantes(fase) <= 3 ? Cores.destaque : Cores.painel,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t('Peças: {0}', [_restantes(fase)]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placarDePontos() => Column(
    children: [
      TextoContornado('${_partida.pontos}', tamanho: 50),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Cores.ouro, size: 18),
          const SizedBox(width: 4),
          Text(
            '${math.max(_s.progresso.recorde, _partida.pontos)}',
            style: const TextStyle(color: Cores.textoFraco, fontSize: 16),
          ),
          if (_partida.combo >= 2) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: Cores.destaque, borderRadius: BorderRadius.circular(20)),
              child: Text(t('Combo x{0}', [_partida.combo]), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      if (_partida.rampa) _barraDaMeta(),
    ],
  );

  /// Infinito: nível das peças, progresso até a próxima meta de pontos e o que ela dá.
  Widget _barraDaMeta() {
    final pagos = _partida.marcosPagos;
    final proxima = Marcos.proximo(pagos);
    final anterior = pagos == 0 ? 0 : Marcos.todos[pagos - 1].pontos;
    final progresso = proxima == null
        ? 1.0
        : ((_partida.pontos - anterior) / (proxima.pontos - anterior)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(color: Cores.painel, borderRadius: BorderRadius.circular(12)),
            child: Text(t('Nível {0}', [pagos + 1]), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progresso,
                minHeight: 9,
                backgroundColor: Cores.casa,
                color: Cores.blocos[1],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            proxima == null ? t('Máximo!') : t('Meta {0} · +{1}', [Marcos.formatar(proxima.pontos), proxima.gemas]),
            style: const TextStyle(fontSize: 13, color: Cores.textoFraco, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _tabuleiro(double lado) => Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Com Martelo ou Bomba escolhido a borda fica dourada: dá para ver que ele espera o toque.
            colors: _reforcoAtivo != null ? const [Cores.ouro, Color(0xFFFF8A00), Cores.ouro] : Cores.moldura,
          ),
          boxShadow: [
            BoxShadow(color: Cores.brilhoRosa.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(-6, -4)),
            BoxShadow(color: Cores.brilhoCiano.withValues(alpha: 0.3), blurRadius: 28, offset: const Offset(6, 8)),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Cores.painel, borderRadius: BorderRadius.circular(19)),
          child: SizedBox.square(
            dimension: lado,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _reforcoAtivo == null ? null : _tocouNoTabuleiro,
              child: TabuleiroWidget(
                key: _chaveTabuleiro,
                tabuleiro: _partida.tabuleiro,
                previa: _previa,
                removidos: _removidos,
                geracao: _geracao,
              ),
            ),
          ),
        ),
      ),
      if (_reforcoAtivo != null && _fim == null)
        Positioned(
          left: 0,
          right: 0,
          bottom: -44,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Cores.ouro, borderRadius: BorderRadius.circular(16)),
                child: Text(
                  _reforcoAtivo == _Reforco.martelo
                      ? t('Toque no bloco que quer tirar')
                      : t('Toque no centro da área 3x3 que quer limpar'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3A2400)),
                ),
              ),
            ),
          ),
        ),
      if (_aviso case final aviso?)
        IgnorePointer(
          child: _Aviso(key: ValueKey(aviso.id), aviso: aviso),
        ),
    ],
  );

  Widget _mao() {
    final casaMao = _casa * 0.5;
    return SizedBox(
      height: casaMao * 5 + 16,
      child: Row(
        children: [
          for (var i = 0; i < Partida.tamanhoMao; i++)
            Expanded(
              child: GestureDetector(
                key: ValueKey('mao-$i'),
                behavior: HitTestBehavior.opaque,
                onPanDown: (d) => _pegar(i, d.globalPosition),
                onPanUpdate: (d) => _mover(d.globalPosition),
                onPanEnd: (_) => _soltar(),
                onPanCancel: _soltar,
                child: Center(
                  child: switch (_partida.mao[i]) {
                    final peca? when _arrastando != i => PecaWidget(
                      peca: peca,
                      tamanhoCasa: casaMao,
                      apagada: !_partida.tabuleiro.cabeEmAlgumLugar(peca.formato),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reforcos() => ListenableBuilder(
    listenable: _s.progresso,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            _BotaoReforco(
              icone: Icons.undo_rounded,
              texto: t('Desfazer'),
              custo: Custos.desfazer,
              aoTocar: _partida.podeDesfazer && _fim == null
                  ? () => _usarReforco(Custos.desfazer, _partida.desfazer)
                  : null,
            ),
            const SizedBox(width: 8),
            _BotaoReforco(
              icone: Icons.shuffle_rounded,
              texto: t('Trocar'),
              custo: Custos.trocar,
              aoTocar: _fim == null
                  ? () => _usarReforco(Custos.trocar, () {
                      _partida.trocarMao();
                      return true;
                    })
                  : null,
            ),
            const SizedBox(width: 8),
            _BotaoReforco(
              icone: Icons.hardware_rounded,
              nome: t('Martelo'),
              custo: Custos.martelo,
              ativo: _reforcoAtivo == _Reforco.martelo,
              aoTocar: _fim == null ? () => _alternarReforco(_Reforco.martelo, Custos.martelo) : null,
            ),
            const SizedBox(width: 8),
            _BotaoReforco(
              icone: Icons.flare_rounded,
              nome: t('Bomba'),
              custo: Custos.bomba,
              ativo: _reforcoAtivo == _Reforco.bomba,
              aoTocar: _fim == null ? () => _alternarReforco(_Reforco.bomba, Custos.bomba) : null,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pecaNoDedo() {
    final peca = _partida.mao[_arrastando!]!;
    final palco = _chavePalco.currentContext?.findRenderObject() as RenderBox?;
    if (palco == null) return const SizedBox.shrink();
    final canto = palco.globalToLocal(_cantoDaPeca(peca, _dedo!));
    return Positioned(
      left: canto.dx,
      top: canto.dy,
      child: IgnorePointer(
        child: PecaWidget(peca: peca, tamanhoCasa: _casa),
      ),
    );
  }

  Widget _painelDoFim() => Positioned.fill(
    child: ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 380),
          child: CartaoVidro(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
            child: ListenableBuilder(
              listenable: _s.progresso,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (_fim) {
                  _Fim.segundaChance => _segundaChance(),
                  _Fim.faseVencida => _faseVencida(widget.fase!),
                  _Fim.faseFalhou => _faseFalhou(widget.fase!),
                  _ => _resultado(),
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  /// Botão principal dos painéis (estilo bala).
  Widget _botao(String texto, IconData icone, VoidCallback? acao) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: BotaoDoce(texto: texto, icone: icone, cor: Cores.blocos[3], altura: 52, tamanhoTexto: 20, aoTocar: acao),
  );

  List<Widget> _faseVencida(Fase fase) {
    final estrelas = _s.progresso.estrelasDaFase(fase.numero);
    return [
      Text(
        t('Fase {0} concluída!', [fase.numero]),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 1; i <= 3; i++)
            Icon(Icons.star_rounded, size: i == 2 ? 64 : 52, color: i <= estrelas ? Cores.ouro : Cores.casa),
        ],
      ),
      if (_gemasFase > 0)
        Text(
          t('+{0} gemas', [_gemasFase]),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.gema, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      const SizedBox(height: 20),
      if (fase.numero < Fase.total)
        _botao(t('Próxima fase'), Icons.arrow_forward_rounded, () => _irParaFase(fase.numero + 1)),
      TextButton(onPressed: _irParaMapa, child: Text(t('Mapa'))),
    ];
  }

  List<Widget> _faseFalhou(Fase fase) {
    final semEspaco = _partida.fimDeJogo;
    return [
      Text(
        semEspaco ? t('Sem espaço!') : t('Acabaram as peças!'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        t('Faltou pouco: {0}/{1}', [fase.progresso(_partida), fase.alvo]),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Cores.textoFraco),
      ),
      const SizedBox(height: 20),
      if (!_ajudou) ...[
        _botao(
          semEspaco ? t('Abrir espaço') : t('+5 peças'),
          _s.progresso.assinante ? Icons.workspace_premium_rounded : Icons.smart_display_rounded,
          _s.progresso.assinante ? _ajudarNaFase : _ajudaComAnuncio,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _s.progresso.gemas >= Custos.continuar ? _ajudaComGemas : null,
          icon: const IconeGema(),
          label: Text(t('Usar {0} gemas', [Custos.continuar])),
        ),
      ] else
        _botao(t('Tentar de novo'), Icons.replay_rounded, () => _irParaFase(fase.numero)),
      const SizedBox(height: 4),
      if (!_ajudou) TextButton(onPressed: () => _irParaFase(fase.numero), child: Text(t('Tentar de novo'))),
      TextButton(onPressed: _irParaMapa, child: Text(t('Mapa'))),
    ];
  }

  List<Widget> _segundaChance() {
    final p = _s.progresso;
    return [
      Text(
        t('Sem espaço!'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(t('{0} pontos', [_partida.pontos]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 8),
      Text(
        t('Limpar as 4 linhas do meio e continuar?'),
        textAlign: TextAlign.center,
        style: TextStyle(color: Cores.textoFraco),
      ),
      const SizedBox(height: 20),
      if (p.assinante)
        _botao(t('Continuar grátis'), Icons.workspace_premium_rounded, _continuar)
      else
        _botao(t('Assistir e continuar'), Icons.smart_display_rounded, _continuarComAnuncio),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
        onPressed: p.gemas >= Custos.continuar ? _continuarComGemas : null,
        icon: const IconeGema(),
        label: Text(t('Usar {0} gemas', [Custos.continuar])),
      ),
      const SizedBox(height: 4),
      TextButton(onPressed: _encerrar, child: Text(t('Não, obrigado'))),
    ];
  }

  List<Widget> _resultado() => [
    Center(
      child: Mascote(
        humor: humorDoFim(
          novoRecorde: _novoRecorde,
          pontos: _partida.pontos,
          recorde: widget.relampago ? _s.progresso.relampagoMelhor : _s.progresso.recorde,
        ),
        tamanho: 74,
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
      child: Text(
        fraseDoMascote(
          novoRecorde: _novoRecorde,
          pontos: _partida.pontos,
          recorde: widget.relampago ? _s.progresso.relampagoMelhor : _s.progresso.recorde,
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Cores.textoFraco),
      ),
    ),
    Text(
      _novoRecorde ? t('Novo recorde!') : t('Fim de jogo'),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    ),
    Text(
      '${_partida.pontos}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
    ),
    Text(
      t('Recorde: {0}', [widget.relampago ? _s.progresso.relampagoMelhor : _s.progresso.recorde]),
      textAlign: TextAlign.center,
      style: const TextStyle(color: Cores.textoFraco),
    ),
    if (widget.diario)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          [
            t('Desafio do dia concluído!'),
            if (_gemasDesafio > 0) t('+{0} gemas', [_gemasDesafio]),
            if (_faixaNova case final f?) t('Faixa {0}! +{1} gemas', [t(f.faixa.nome), f.gemas]),
            if (_bausNovos > 0) t('Baú novo na coleção!'),
            if (premioDaSequencia(_s.progresso.sequencia(_dia)) > 0 && _gemasDesafio > 0)
              t('Marco de {0} dias! 🎉', [_s.progresso.sequencia(_dia)]),
            if (_s.progresso.sequencia(_dia) == 30 && _gemasDesafio > 0) t('Tema Chama liberado na Loja!'),
            if (_figurinhaNova case final f?)
              f.completou
                  ? t('Figurinha {0}: álbum {1} completo! +{2} gemas', [
                      f.figurinha.nome,
                      f.album.nome,
                      f.album.premioGemas,
                    ])
                  : t('Figurinha nova: {0}', [t(f.figurinha.nome)]),
            '🔥 ${_s.progresso.sequencia(_dia)} ${t(_s.progresso.sequencia(_dia) == 1 ? 'dia' : 'dias seguidos')}',
          ].join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
        ),
      ),
    if (widget.relampago)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          [t('Tempo esgotado!'), if (_gemasRelampago > 0) _textoGemas(_gemasRelampago)].join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
        ),
      ),
    if (widget.amigo case final amigo?)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          [
            _partida.pontos > amigo.pontos
                ? t('Você venceu seu amigo! {0} x {1}', [_partida.pontos, amigo.pontos])
                : (_partida.pontos == amigo.pontos
                      ? t('Empate! {0} x {1}', [_partida.pontos, amigo.pontos])
                      : t('Quase! Faltaram {0} pontos para vencer', [amigo.pontos - _partida.pontos + 1])),
            if (_gemasAmigo > 0) t('+{0} gemas', [_gemasAmigo]),
          ].join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
        ),
      ),
    if (widget.arena)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          [
            t('Melhor da semana: {0}', [_s.progresso.arenaMelhor(_semana)]),
            if (Arena.trofeuPara(_s.progresso.arenaMelhor(_semana)) case final trofeu?)
              t('Troféu {0}! Pegue o prêmio na Arena.', [t(trofeu.nome)]),
          ].join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.ouro, fontWeight: FontWeight.w700),
        ),
      ),
    const SizedBox(height: 20),
    _botao(
      widget.diario || widget.arena || widget.amigo != null || widget.relampago
          ? t('Tentar de novo')
          : t('Jogar de novo'),
      Icons.replay_rounded,
      _jogarDeNovo,
    ),
    const SizedBox(height: 10),
    OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
      onPressed: _compartilhar,
      icon: const Icon(Icons.share_rounded),
      label: Text(t('Desafiar amigos')),
    ),
    TextButton(onPressed: _sair, child: Text(t('Início'))),
  ];
}

class _BotaoReforco extends StatelessWidget {
  const _BotaoReforco({
    required this.icone,
    required this.custo,
    this.texto,
    this.nome,
    this.ativo = false,
    this.aoTocar,
  });

  final IconData icone;
  final int custo;

  /// Com [texto] o botão mostra o nome; sem ele fica só o ícone (e o [nome] vira dica ao segurar).
  final String? texto;
  final String? nome;
  final bool ativo;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: aoTocar == null ? 0.4 : 1,
    child: Tooltip(
      message: nome ?? texto ?? '',
      child: Material(
        color: ativo ? Cores.ouro : Cores.painel.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: aoTocar,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: texto == null ? 10 : 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icone, size: 22, color: ativo ? const Color(0xFF3A2400) : null),
                if (texto != null) ...[
                  const SizedBox(width: 6),
                  Text(texto!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(width: 6),
                const IconeGema(tamanho: 14),
                Text(
                  ' $custo',
                  style: TextStyle(color: ativo ? const Color(0xFF3A2400) : Cores.gema, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Texto que pula no meio do tabuleiro ("Combo x3 +120") e some.
/// O que mostrar no meio do tabuleiro depois de uma jogada: elogio (ou meta) e os detalhes.
class _AvisoDeJogada {
  const _AvisoDeJogada({required this.id, required this.titulo, required this.nivel, required this.detalhes});

  final int id;
  final String titulo;

  /// 1 a 5: define o tamanho e a cor do título.
  final int nivel;
  final List<String> detalhes;
}

/// Texto que pula no meio do tabuleiro ("Incrível! +120") e some. Quanto maior o nível, maior e mais quente a cor.
class _Aviso extends StatelessWidget {
  const _Aviso({super.key, required this.aviso});

  final _AvisoDeJogada aviso;

  static const _tamanhos = [30.0, 36.0, 42.0, 48.0, 54.0];
  static const _cores = [Color(0xFFFFFFFF), Color(0xFFFFF27A), Color(0xFFFFB347), Color(0xFFFF6EC7), Color(0xFF7DF9FF)];
  static const _contornos = [
    Color(0xFF3B1E8A),
    Color(0xFFB0186A),
    Color(0xFF8A2E00),
    Color(0xFF6A0DAD),
    Color(0xFF00508A),
  ];

  @override
  Widget build(BuildContext context) {
    final n = (aviso.nivel - 1).clamp(0, 4);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1000 + n * 150),
      builder: (context, t, child) {
        // Quanto maior o nível, mais "elástica" a entrada.
        final escala = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) * (1 + n * 0.04) : 1.0 + n * 0.04;
        final opacidade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
        return Opacity(
          opacity: opacidade.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -30 * t),
            child: Transform.scale(scale: escala, child: child),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextoContornado(aviso.titulo, tamanho: _tamanhos[n], cor: _cores[n], contorno: _contornos[n]),
          for (final d in aviso.detalhes) TextoContornado(d, tamanho: 20, cor: Colors.white, contorno: _contornos[n]),
        ],
      ),
    );
  }
}

/// Balão do tutorial. Não bloqueia o arraste (só o botão ENTENDI recebe toque).
class BalaoTutorial extends StatefulWidget {
  const BalaoTutorial({super.key, required this.texto, this.mostrarMao = false, this.aoEntender});

  final String texto;
  final bool mostrarMao;
  final VoidCallback? aoEntender;

  @override
  State<BalaoTutorial> createState() => _BalaoTutorialState();
}

class _BalaoTutorialState extends State<BalaoTutorial> with SingleTickerProviderStateMixin {
  late final _mao = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _animarMao();
  }

  @override
  void didUpdateWidget(BalaoTutorial antigo) {
    super.didUpdateWidget(antigo);
    _animarMao();
  }

  /// A mão só se mexe enquanto aparece (animação parada não gasta bateria).
  void _animarMao() => widget.mostrarMao ? _mao.repeat(reverse: true) : _mao.stop();

  @override
  void dispose() {
    _mao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      IgnorePointer(
        ignoring: widget.aoEntender == null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              const BoxShadow(color: Color(0x66000000), offset: Offset(0, 5)),
              BoxShadow(color: Cores.brilhoRosa.withValues(alpha: 0.5), blurRadius: 20),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A0B5E),
                  height: 1.25,
                ),
              ),
              if (widget.aoEntender != null) ...[
                const SizedBox(height: 10),
                BotaoDoce(
                  texto: t('ENTENDI'),
                  cor: Cores.blocos[3],
                  altura: 44,
                  tamanhoTexto: 18,
                  aoTocar: widget.aoEntender,
                ),
              ],
            ],
          ),
        ),
      ),
      if (widget.mostrarMao)
        IgnorePointer(
          child: Align(
            // Aponta para a primeira peça da mão.
            alignment: const Alignment(-0.68, 0),
            child: AnimatedBuilder(
              animation: _mao,
              builder: (context, child) => Transform.translate(offset: Offset(0, 58 + _mao.value * 22), child: child),
              child: const Icon(
                Icons.touch_app_rounded,
                size: 54,
                color: Colors.white,
                shadows: [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 3), blurRadius: 4)],
              ),
            ),
          ),
        ),
    ],
  );
}
