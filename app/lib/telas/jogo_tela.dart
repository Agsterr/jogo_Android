import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../jogo/partida.dart';
import '../jogo/peca.dart';
import '../jogo/sorteio.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/peca_widget.dart';
import '../widgets/tabuleiro_widget.dart';
import 'loja_tela.dart';

/// Preço dos reforços e da segunda chance, em gemas.
abstract final class Custos {
  static const desfazer = 3;
  static const trocar = 5;
  static const continuar = 10;
}

enum _Fim { segundaChance, resultado }

class JogoTela extends StatefulWidget {
  const JogoTela({super.key, required this.servicos, this.diario = false, this.partida});

  final Servicos servicos;

  /// Desafio do dia: semente fixa para todos.
  final bool diario;

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

  Servicos get _s => widget.servicos;

  @override
  void initState() {
    super.initState();
    _dia = Sorteio.sementeDoDia(_s.hoje());
    _partida = widget.partida ?? _partidaSalva() ?? _novaPartida();
    if (_partida.fimDeJogo) _fim = _partida.continuou ? _Fim.resultado : _Fim.segundaChance;
  }

  /// Clássico e Desafio têm partidas salvas separadas.
  String get _chave => widget.diario ? 'desafio' : 'classico';

  Partida? _partidaSalva() {
    final json = _s.progresso.partidaSalva(_chave);
    if (json == null || (widget.diario && json['dia'] != _dia)) return null;
    try {
      return Partida.deJson(json);
    } on Object {
      return null; // formato antigo ou corrompido: começa de novo
    }
  }

  void _salvar() => _s.progresso.salvarPartida(_chave, {..._partida.paraJson(), 'dia': _dia});

  Partida _novaPartida() => Partida(semente: widget.diario ? _dia : DateTime.now().microsecondsSinceEpoch);

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
      _removidos = jogada.removidos;
      _geracao++;
      _aviso = (_textoDoAviso(jogada), _geracao);
    } else {
      HapticFeedback.lightImpact();
    }
    _s.progresso.ganharGemas(jogada.gemas);
    _salvar();
    setState(() {});
    if (_partida.fimDeJogo) {
      if (_partida.continuou) {
        _encerrar();
      } else {
        setState(() => _fim = _Fim.segundaChance);
      }
    }
  }

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
      if (j.gemas > 0) '+${j.gemas} ${j.gemas == 1 ? 'gema' : 'gemas'}',
    ];
    return partes.join('\n');
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
    if (widget.diario) await _s.progresso.concluirDesafio(_dia, pontos);
    if (!mounted) return;
    setState(() {
      _novoRecorde = recorde;
      _fim = _Fim.resultado;
    });
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

  Future<void> _sair() async {
    await _intersticial();
    if (mounted) Navigator.of(context).pop();
  }

  void _compartilhar() {
    final texto = widget.diario
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

  Widget _placar() => Column(
    children: [
      Text('${_partida.pontos}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, height: 1.1)),
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Cores.painel,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 18, offset: Offset(0, 8))],
        ),
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Cores.painel,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Cores.blocos[5].withValues(alpha: 0.6), width: 2),
          ),
          child: ListenableBuilder(
            listenable: _s.progresso,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _fim == _Fim.segundaChance ? _segundaChance() : _resultado(),
            ),
          ),
        ),
      ),
    ),
  );

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
        FilledButton.icon(
          onPressed: _continuar,
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Continuar grátis'),
        )
      else
        FilledButton.icon(
          onPressed: _continuarComAnuncio,
          icon: const Icon(Icons.smart_display_rounded),
          label: const Text('Assistir e continuar'),
        ),
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
      const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'Desafio do dia concluído!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
        ),
      ),
    const SizedBox(height: 20),
    FilledButton.icon(
      onPressed: _jogarDeNovo,
      icon: const Icon(Icons.replay_rounded),
      label: Text(widget.diario ? 'Tentar de novo' : 'Jogar de novo'),
    ),
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
    child: Text(
      texto,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: Colors.white,
        shadows: [Shadow(color: Color(0xFFB0306A), offset: Offset(0, 3), blurRadius: 0)],
      ),
    ),
  );
}
