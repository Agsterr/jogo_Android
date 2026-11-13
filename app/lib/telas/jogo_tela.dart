import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../jogo/arena.dart';
import '../jogo/eventos.dart';
import '../jogo/fases.dart';
import '../jogo/missoes.dart';
import '../jogo/partida.dart';
import '../jogo/peca.dart';
import '../jogo/sorteio.dart';
import '../servicos/servicos.dart';
import '../servicos/sons.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';
import '../widgets/tabuleiro_widget.dart';
import 'loja_tela.dart';
import 'mapa_tela.dart';
import 'roleta_partida.dart';

/// Preço dos reforços e da segunda chance, em gemas.
abstract final class Custos {
  static const desfazer = 3;
  static const trocar = 5;
  static const continuar = 10;
}

enum _Fim { segundaChance, resultado, faseVencida, faseFalhou }

class JogoTela extends StatefulWidget {
  const JogoTela({super.key, required this.servicos, this.diario = false, this.arena = false, this.fase, this.partida});

  final Servicos servicos;

  /// Desafio do dia: semente fixa para todos.
  final bool diario;

  /// Arena da semana: semente fixa da semana, vale a melhor partida.
  final bool arena;

  /// Modo Fases: objetivo e limite de peças.
  final Fase? fase;

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
  (String, int)? _aviso;

  _Fim? _fim;
  bool _novoRecorde = false;
  int _gemasDesafio = 0;

  /// Fases: peças extras ganhas na ajuda (uma ajuda por tentativa).
  int _extras = 0;
  bool _ajudou = false;
  int _gemasFase = 0;

  Servicos get _s => widget.servicos;

  @visibleForTesting
  Partida get partidaParaTeste => _partida;

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
  void _dicaDeEntrada() {
    if (!mounted || _tutorial != null) return;
    final dica = switch (widget.fase?.objetivo) {
      Objetivo.pedras => Dicas.pedras,
      Objetivo.pontos => Dicas.pontos,
      Objetivo.umaCor => Dicas.umaCor,
      Objetivo.combo => Dicas.combo,
      Objetivo.linhas => null,
      null => widget.arena ? Dicas.arena : (widget.diario ? Dicas.desafio : Dicas.infinito),
    };
    if (dica != null) mostrarDicaUmaVez(context, _s, dica);
  }

  // ---------- tutorial da fase 1 ----------

  /// Passo do tutorial (0: arrastar, 1: encher linha, 2: objetivo) ou `null` se não há tutorial.
  int? _tutorial;

  static const _textosTutorial = [
    'Segure uma peça aqui embaixo e arraste até o tabuleiro.',
    'Isso! Agora encha uma linha ou coluna INTEIRA: ela some e dá pontos.',
    'Muito bem! O objetivo da fase fica lá em cima. Cumpra antes de acabar as peças: '
        'quanto mais peças sobrarem, mais estrelas!',
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
  String get _chave => widget.arena ? 'arena' : (widget.diario ? 'desafio' : 'classico');

  int get _semana => Arena.semana(_s.hoje());

  Partida? _partidaSalva() {
    if (widget.fase != null) return null;
    final json = _s.progresso.partidaSalva(_chave);
    if (json == null || (widget.diario && json['dia'] != _dia)) return null;
    if (widget.arena && json['semana'] != _semana) return null;
    try {
      return Partida.deJson(json);
    } on Object {
      return null; // formato antigo ou corrompido: começa de novo
    }
  }

  void _salvar() => widget.fase != null
      ? null
      : _s.progresso.salvarPartida(_chave, {..._partida.paraJson(), 'dia': _dia, 'semana': _semana});

  Partida _novaPartida() =>
      widget.fase?.novaPartida() ??
      Partida(
        semente: widget.arena
            ? Arena.semente(_s.hoje())
            : (widget.diario ? _dia : DateTime.now().microsecondsSinceEpoch),
      );

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
    if (jogada.linhasLimpas > 0) {
      HapticFeedback.mediumImpact();
      _s.sons.tocar(jogada.combo >= 2 || jogada.linhasLimpas >= 2 ? Som.combo : Som.linha);
      _removidos = jogada.removidos;
      _geracao++;
      _aviso = (_textoDoAviso(jogada), _geracao);
    } else {
      HapticFeedback.lightImpact();
      _s.sons.tocar(Som.encaixe);
    }
    _s.progresso.ganharGemas(jogada.gemas * multiplicadorDeGemas(_s.hoje()));
    _s.progresso.contarMissoes(_dia, contagemDaJogada(jogada));
    _avancarTutorial(jogada);
    _salvar();
    setState(() {});
    if (widget.fase case final fase?) {
      _conferirFase(fase);
      return;
    }
    if (_partida.fimDeJogo) {
      _s.sons.tocar(Som.fim);
      if (_partida.continuou) {
        _encerrar();
      } else {
        setState(() => _fim = _Fim.segundaChance);
      }
    }
  }

  String _textoGemas(int n) => '+$n ${n == 1 ? 'gema' : 'gemas'}';

  String _textoDoAviso(Jogada j) {
    final partes = <String>[
      if (j.tabuleiroLimpo)
        'Tabuleiro limpo!'
      else if (j.combo >= 2)
        'Combo x${j.combo}'
      else if (j.linhasLimpas >= 2)
        '${j.linhasLimpas} linhas!'
      else
        'Boa!',
      '+${j.pontos}',
      if (j.gemas > 0) _textoGemas(j.gemas * multiplicadorDeGemas(_s.hoje())),
    ];
    return partes.join('\n');
  }

  // ---------- fases ----------

  int _restantes(Fase fase) => fase.pecasRestantes(_partida) + _extras;

  Future<void> _conferirFase(Fase fase) async {
    if (fase.concluida(_partida)) {
      if (_tutorial != null) _terminarTutorial();
      _s.sons.tocar(Som.combo);
      // Quem precisou de ajuda leva no máximo 1 estrela.
      final estrelas = _ajudou ? 1 : fase.estrelas(_partida);
      final gemas = await _s.progresso.concluirFase(fase.numero, estrelas);
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
          .showSnackBar(const SnackBar(content: Text('Anúncio indisponível agora. Tente de novo.')));
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
          .showSnackBar(const SnackBar(content: Text('Anúncio indisponível agora. Tente de novo.')));
    }
  }

  Future<void> _continuarComGemas() async {
    if (await _s.progresso.gastarGemas(Custos.continuar)) _continuar();
  }

  Future<void> _encerrar() async {
    await _s.progresso.apagarPartida(_chave);
    final pontos = _partida.pontos;
    final recorde = await _s.progresso.fimDePartida(pontos);
    await _s.progresso.contarMissoes(_dia, {TipoMissao.partidas: 1, TipoMissao.pontos: pontos});
    final gemasDesafio = widget.diario ? await _s.progresso.concluirDesafio(_dia, pontos) : 0;
    if (widget.arena) {
      await _s.progresso.registrarArena(_semana, pontos);
      await _s.progresso.contarMissao(_dia, TipoMissao.arena, 1);
    }
    if (!mounted) return;
    setState(() {
      _novoRecorde = recorde;
      _gemasDesafio = gemasDesafio;
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
        ? 'Encaixa 🏆 Arena da semana\n⭐ ${_partida.pontos} pontos'
              '${Arena.trofeuPara(_partida.pontos) == null ? '' : ' · ${Arena.trofeuPara(_partida.pontos)!.nome}'}\n'
              'Mesmas peças para todo mundo até domingo. Consegue me passar?\n$linkDaLoja'
        : widget.diario
        ? 'Encaixa 🧩 Desafio #${numeroDoDesafio(_s.hoje())}\n⭐ ${_partida.pontos} pontos\n'
              'Mesmas peças para todo mundo. Consegue me passar?\n$linkDaLoja'
        : 'Fiz ${_partida.pontos} pontos no Encaixa 🧩 Consegue me passar?\n$linkDaLoja';
    SharePlus.instance.share(ShareParams(text: texto));
  }

  // ---------- tela ----------

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoJogo(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // Reserva espaço para topo, placar, mão (2,5 casas) e reforços.
            final lado = math.min(c.maxWidth - 24, (c.maxHeight - 250) / 1.33);
            _casa = lado / 8;
            return Stack(
              key: _chavePalco,
              children: [
                Column(
                  children: [
                    _barraDoTopo(),
                    _placar(),
                    const Spacer(),
                    _tabuleiro(lado),
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

  Widget _barraDoTopo() => ListenableBuilder(
    listenable: _s.progresso,
    builder: (context, _) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          if (widget.fase case final fase?)
            Text(
              'FASE ${fase.numero}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          if (widget.arena)
            const Text(
              'ARENA DA SEMANA',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.ouro),
            ),
          if (widget.diario)
            Text(
              'DESAFIO #${numeroDoDesafio(_s.hoje())}',
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
              'Peças: ${_restantes(fase)}',
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
              child: Text('Combo x${_partida.combo}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    ],
  );

  Widget _tabuleiro(double lado) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Cores.brilhoRosa, Color(0xFF8B5CFF), Cores.brilhoCiano],
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
      if (_aviso case (final texto, final id))
        IgnorePointer(
          child: _Aviso(key: ValueKey(id), texto: texto),
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
    builder: (context, _) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        children: [
          _BotaoReforco(
            icone: Icons.undo_rounded,
            texto: 'Desfazer',
            custo: Custos.desfazer,
            aoTocar: _partida.podeDesfazer && _fim == null
                ? () => _usarReforco(Custos.desfazer, _partida.desfazer)
                : null,
          ),
          const SizedBox(width: 12),
          _BotaoReforco(
            icone: Icons.shuffle_rounded,
            texto: 'Trocar',
            custo: Custos.trocar,
            aoTocar: _fim == null
                ? () => _usarReforco(Custos.trocar, () {
                    _partida.trocarMao();
                    return true;
                  })
                : null,
          ),
        ],
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
        'Fase ${fase.numero} concluída!',
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
          '+$_gemasFase gemas',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.gema, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      const SizedBox(height: 20),
      if (fase.numero < Fase.total)
        _botao('Próxima fase', Icons.arrow_forward_rounded, () => _irParaFase(fase.numero + 1)),
      TextButton(onPressed: _irParaMapa, child: const Text('Mapa')),
    ];
  }

  List<Widget> _faseFalhou(Fase fase) {
    final semEspaco = _partida.fimDeJogo;
    return [
      Text(
        semEspaco ? 'Sem espaço!' : 'Acabaram as peças!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(
        'Faltou pouco: ${fase.progresso(_partida)}/${fase.alvo}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Cores.textoFraco),
      ),
      const SizedBox(height: 20),
      if (!_ajudou) ...[
        _botao(
          semEspaco ? 'Abrir espaço' : '+5 peças',
          _s.progresso.assinante ? Icons.workspace_premium_rounded : Icons.smart_display_rounded,
          _s.progresso.assinante ? _ajudarNaFase : _ajudaComAnuncio,
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _s.progresso.gemas >= Custos.continuar ? _ajudaComGemas : null,
          icon: const IconeGema(),
          label: const Text('Usar ${Custos.continuar} gemas'),
        ),
      ] else
        _botao('Tentar de novo', Icons.replay_rounded, () => _irParaFase(fase.numero)),
      const SizedBox(height: 4),
      if (!_ajudou) TextButton(onPressed: () => _irParaFase(fase.numero), child: const Text('Tentar de novo')),
      TextButton(onPressed: _irParaMapa, child: const Text('Mapa')),
    ];
  }

  List<Widget> _segundaChance() {
    final p = _s.progresso;
    return [
      const Text(
        'Sem espaço!',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text('${_partida.pontos} pontos', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 8),
      const Text(
        'Limpar as 4 linhas do meio e continuar?',
        textAlign: TextAlign.center,
        style: TextStyle(color: Cores.textoFraco),
      ),
      const SizedBox(height: 20),
      if (p.assinante)
        _botao('Continuar grátis', Icons.workspace_premium_rounded, _continuar)
      else
        _botao('Assistir e continuar', Icons.smart_display_rounded, _continuarComAnuncio),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
        onPressed: p.gemas >= Custos.continuar ? _continuarComGemas : null,
        icon: const IconeGema(),
        label: const Text('Usar ${Custos.continuar} gemas'),
      ),
      const SizedBox(height: 4),
      TextButton(onPressed: _encerrar, child: const Text('Não, obrigado')),
    ];
  }

  List<Widget> _resultado() => [
    Icon(
      _novoRecorde ? Icons.emoji_events_rounded : Icons.flag_rounded,
      size: 48,
      color: _novoRecorde ? Cores.ouro : Cores.textoFraco,
    ),
    Text(
      _novoRecorde ? 'Novo recorde!' : 'Fim de jogo',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    ),
    Text(
      '${_partida.pontos}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
    ),
    Text(
      'Recorde: ${_s.progresso.recorde}',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Cores.textoFraco),
    ),
    if (widget.diario)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          [
            'Desafio do dia concluído!',
            if (_gemasDesafio > 0) '+$_gemasDesafio gemas',
            '🔥 ${_s.progresso.sequencia(_dia)} ${_s.progresso.sequencia(_dia) == 1 ? 'dia' : 'dias seguidos'}',
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
            'Melhor da semana: ${_s.progresso.arenaMelhor(_semana)}',
            if (Arena.trofeuPara(_s.progresso.arenaMelhor(_semana)) case final t?)
              'Troféu ${t.nome}! Pegue o prêmio na Arena.',
          ].join('\n'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Cores.ouro, fontWeight: FontWeight.w700),
        ),
      ),
    const SizedBox(height: 20),
    _botao(widget.diario || widget.arena ? 'Tentar de novo' : 'Jogar de novo', Icons.replay_rounded, _jogarDeNovo),
    const SizedBox(height: 10),
    OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
      onPressed: _compartilhar,
      icon: const Icon(Icons.share_rounded),
      label: const Text('Desafiar amigos'),
    ),
    TextButton(onPressed: _sair, child: const Text('Início')),
  ];
}

class _BotaoReforco extends StatelessWidget {
  const _BotaoReforco({required this.icone, required this.texto, required this.custo, this.aoTocar});

  final IconData icone;
  final String texto;
  final int custo;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: aoTocar == null ? 0.4 : 1,
    child: Material(
      color: Cores.painel.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 22),
              const SizedBox(width: 6),
              Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              const IconeGema(tamanho: 14),
              Text(
                ' $custo',
                style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Texto que pula no meio do tabuleiro ("Combo x3 +120") e some.
class _Aviso extends StatelessWidget {
  const _Aviso({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 1100),
    builder: (context, t, child) {
      final escala = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0;
      final opacidade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
      return Opacity(
        opacity: opacidade.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, -30 * t),
          child: Transform.scale(scale: escala, child: child),
        ),
      );
    },
    child: TextoContornado(texto, tamanho: 36, cor: const Color(0xFFFFF27A), contorno: const Color(0xFFB0186A)),
  );
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
                  texto: 'ENTENDI',
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
