import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/puzzle.dart';
import '../jogo/album.dart';
import '../jogo/amigo.dart';
import '../jogo/conquistas.dart';
import '../jogo/passe.dart';
import '../jogo/arena.dart';
import '../jogo/eventos.dart';
import '../jogo/fases.dart';
import '../jogo/missoes.dart';
import '../jogo/roda.dart';
import '../jogo/sorteio.dart';
import '../jogo/temas.dart';
import '../servicos/progresso.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';
import 'ajuda_tela.dart';
import 'album_tela.dart';
import 'baus_tela.dart';
import 'conquistas_tela.dart';
import 'passe_tela.dart';
import 'arena_tela.dart';
import 'jogo_tela.dart';
import 'loja_tela.dart';
import 'mapa_tela.dart';
import 'progresso_tela.dart';
import 'roda_tela.dart';
import '../idioma.dart';

class InicioTela extends StatefulWidget {
  const InicioTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<InicioTela> createState() => _InicioTelaState();
}

class _InicioTelaState extends State<InicioTela> {
  Servicos get servicos => widget.servicos;

  @override
  void initState() {
    super.initState();
    servicos.ranking.disponivel().then((ok) {
      if (mounted && ok) setState(() => _rankingOk = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dia = Sorteio.sementeDoDia(servicos.hoje());
      // Reinstalou e o progresso voltou sozinho: conta ao jogador.
      if (servicos.progresso.recuperadoAutomaticamente) {
        servicos.progresso.recuperadoAutomaticamente = false;
        final r = servicos.progresso.resumo;
        mostrarDica(
          context,
          Dica('recuperado', 'Progresso recuperado!', Icons.cloud_done_rounded, Cores.blocos[3], [
            t('Encontramos o seu progresso salvo automaticamente.'),
            t('Fase {0} · {1} estrelas', [r.fase.clamp(1, Fase.total), r.estrelas]),
            t('{0} gemas · Recorde {1}', [r.gemas, r.recorde]),
          ], botao: t('CONTINUAR')),
        );
        return;
      }
      // Primeira abertura do dia: mostra o presente (ensina que vale voltar todo dia).
      if (servicos.mostrarPresenteAoAbrir && servicos.progresso.presenteDeHoje(dia) > 0) {
        _abrirPresente(dia);
      } else if (servicos.progresso.faseLiberada >= 5) {
        // Quem já tem progresso a perder: lembra uma vez onde fica o "Salvar progresso".
        mostrarDicaUmaVez(context, servicos, Dicas.progresso);
      }
    });
  }

  Future<void> _codigoDeAmigo() async {
    final desafio = await showDialog<DesafioAmigo>(context: context, builder: (_) => const _DialogoCodigoAmigo());
    if (desafio != null && mounted) _abrir(JogoTela(servicos: servicos, amigo: desafio));
  }

  bool _rankingOk = false;

  void _abrir(Widget tela) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));

  void _abrirPresente(int dia) => showDialog<void>(
    context: context,
    builder: (_) => _DialogoPresente(progresso: servicos.progresso, dia: dia),
  );

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso;
    final hoje = servicos.hoje();
    final dia = Sorteio.sementeDoDia(hoje);
    return Scaffold(
      body: FundoJogo(
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _BlocosDeFundo())),
            SafeArea(
              child: ListenableBuilder(
                listenable: p,
                builder: (context, _) {
                  final fase = math.min(p.faseLiberada, Fase.total);
                  // Os cartões da tela inicial são de tamanho fixo: passar de 1,3x quebra o layout.
                  return MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        Row(
                          children: [
                            if (p.assinante) const _Selo('Encaixa+'),
                            ...[
                              const SizedBox(width: 8),
                              _Sequencia(
                                p.sequencia(dia),
                                aoTocar: () => showDialog<void>(
                                  context: context,
                                  builder: (_) =>
                                      _DialogoSequencia(dias: p.sequencia(dia), feitoHoje: p.desafioFeito == dia),
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              tooltip: t('Como jogar'),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _abrir(AjudaTela(servicos: servicos)),
                              icon: const Icon(Icons.help_rounded),
                            ),
                            _BotaoPresente(disponivel: p.presenteDeHoje(dia) > 0, aoTocar: () => _abrirPresente(dia)),
                            IconButton(
                              tooltip: p.somLigado ? t('Desligar som') : t('Ligar som'),
                              visualDensity: VisualDensity.compact,
                              onPressed: p.alternarSom,
                              icon: Icon(p.somLigado ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                            ),
                            GemasChip(
                              gemas: p.gemas,
                              aoTocar: () => _abrir(LojaTela(servicos: servicos)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Logo(tamanho: 50),
                        const SizedBox(height: 14),
                        if (p.presenteDaNoiteDisponivel(dia, hoje)) ...[
                          _PresenteDaNoite(
                            aoTocar: () async {
                              final gemas = await p.pegarPresenteDaNoite(dia, servicos.hoje());
                              if (gemas > 0 && context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(SnackBar(content: Text(t('Boa noite! +{0} gemas', [gemas]))));
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (_BannerEvento.temAlgo(hoje)) ...[
                          GestureDetector(
                            onTap: () => mostrarDica(context, Dicas.eventos),
                            child: _BannerEvento(progresso: p, agora: hoje),
                          ),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: BotaoDoce(
                                texto: t('JOGAR'),
                                detalhe: t('Fase {0}', [fase]),
                                icone: Icons.play_arrow_rounded,
                                cor: Cores.blocos[3],
                                altura: 66,
                                tamanhoTexto: 28,
                                aoTocar: () => _abrir(JogoTela(servicos: servicos, fase: Fase.numero(fase))),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 72,
                              child: BotaoDoce(
                                texto: '',
                                icone: Icons.map_rounded,
                                cor: Cores.blocos[4],
                                altura: 66,
                                tamanhoTexto: 24,
                                aoTocar: () => MapaTela.abrir(context, servicos),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _Ladrilho(
                                  icone: Icons.all_inclusive_rounded,
                                  titulo: t('Infinito'),
                                  texto: p.temPartidaSalva('classico')
                                      ? t('Continuar partida')
                                      : t('Recorde {0}', [p.recorde]),
                                  cores: [Cores.blocos[1], Cores.blocos[0]],
                                  aoTocar: () => _abrir(JogoTela(servicos: servicos)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Ladrilho(
                                  icone: p.desafioFeito == dia ? Icons.check_circle_rounded : Icons.event_rounded,
                                  titulo: t('Desafio #{0}', [numeroDoDesafio(hoje)]),
                                  texto: p.desafioFeito == dia
                                      ? t('Feito: {0}', [p.desafioPontos])
                                      : t('+5 gemas hoje'),
                                  cores: [Cores.blocos[5], Cores.destaque],
                                  aoTocar: () => _abrir(JogoTela(servicos: servicos, diario: true)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _CartaoArena(
                          melhor: p.arenaMelhor(Arena.semana(hoje)),
                          premioDisponivel: Arena.trofeus.any(
                            (t) =>
                                p.arenaMelhor(Arena.semana(hoje)) >= t.pontos &&
                                !p.premioArenaPego(Arena.semana(hoje), t.nome),
                          ),
                          termina: tempoRestante(hoje, Arena.fim(hoje)),
                          aoTocar: () => _abrir(ArenaTela(servicos: servicos)),
                        ),
                        const SizedBox(height: 14),
                        _CartaoRoda(
                          giros: p.girosNoDia(dia),
                          aoTocar: () => _abrir(RodaTela(servicos: servicos)),
                        ),
                        const SizedBox(height: 14),
                        if (p.sequenciaPerdida(dia) > 0) ...[
                          _RecuperarSequencia(servicos: servicos, dia: dia),
                          const SizedBox(height: 14),
                        ],
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.bolt_rounded,
                                  titulo: t('Relâmpago'),
                                  subtitulo: p.relampagoMelhor > 0
                                      ? t('60 segundos · melhor {0}', [p.relampagoMelhor])
                                      : t('60 segundos para pontuar!'),
                                  cores: const [Color(0xFFFFD000), Color(0xFFFF6A00)],
                                  contorno: const Color(0xFF7A3000),
                                  aoTocar: () => _abrir(JogoTela(servicos: servicos, relampago: true)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.psychology_rounded,
                                  titulo: t('Puzzle do dia'),
                                  subtitulo: p.puzzleEstrelas(dia) > 0
                                      ? t('{0} de 3 estrelas', [p.puzzleEstrelas(dia)])
                                      : t('3 peças: limpe o máximo!'),
                                  cores: const [Color(0xFF7C4DFF), Color(0xFF00B0FF)],
                                  contorno: const Color(0xFF2A1B7A),
                                  aoTocar: () => _abrir(JogoTela(servicos: servicos, puzzle: puzzleDoDia(dia))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.collections_bookmark_rounded,
                                  titulo: t('Álbum'),
                                  subtitulo: t('{0} de {1} figurinhas', [
                                    p.figurinhas.length,
                                    Album.todos.fold<int>(0, (soma, a) => soma + a.figurinhas.length),
                                  ]),
                                  cores: const [Color(0xFF00D084), Color(0xFF008F9B)],
                                  contorno: const Color(0xFF00424A),
                                  aoTocar: () => _abrir(AlbumTela(servicos: servicos)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.military_tech_rounded,
                                  titulo: t('Conquistas'),
                                  subtitulo: p.conquistasProntas > 0
                                      ? t('{0} prêmio{1} para pegar!', [
                                          p.conquistasProntas,
                                          p.conquistasProntas == 1 ? '' : 's',
                                        ])
                                      : t('{0} de {1}', [
                                          Conquista.todas.where((c) => c.feita(p.estatisticas)).length,
                                          Conquista.todas.length,
                                        ]),
                                  cores: const [Color(0xFFFFB800), Color(0xFFFF3D6E)],
                                  contorno: const Color(0xFF7A1033),
                                  selo: p.conquistasProntas,
                                  aoTocar: () => _abrir(ConquistasTela(servicos: servicos)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.inventory_2_rounded,
                                  titulo: t('Baús e coleção'),
                                  subtitulo: p.baus > 0
                                      ? t('{0} baú{1} para abrir!', [p.baus, p.baus == 1 ? '' : 's'])
                                      : t('Itens de aparência: temas, molduras e cores'),
                                  cores: const [Color(0xFFFFB800), Color(0xFF8B3DFF)],
                                  contorno: const Color(0xFF3A1B8A),
                                  selo: p.baus,
                                  aoTocar: () => _abrir(BausTela(servicos: servicos)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Atalho(
                                  icone: Icons.workspace_premium_rounded,
                                  titulo: t('Passe'),
                                  subtitulo: p.passeProntos(dia) > 0
                                      ? t('{0} prêmio{1} para pegar!', [
                                          p.passeProntos(dia),
                                          p.passeProntos(dia) == 1 ? '' : 's',
                                        ])
                                      : t('Nível {0} de {1}', [p.passeNivel(dia), niveisDoPasse]),
                                  cores: const [Color(0xFF7B61FF), Color(0xFFFF61D8)],
                                  contorno: const Color(0xFF3A1B8A),
                                  selo: p.passeProntos(dia),
                                  aoTocar: () => _abrir(PasseTela(servicos: servicos)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _CartaoMissoes(progresso: p, dia: dia),
                        const SizedBox(height: 14),
                        BotaoDoce(
                          texto: t('LOJA'),
                          icone: Icons.storefront_rounded,
                          cor: Cores.blocos[5],
                          altura: 50,
                          tamanhoTexto: 20,
                          aoTocar: () => _abrir(LojaTela(servicos: servicos)),
                        ),
                        if (_rankingOk)
                          TextButton.icon(
                            onPressed: servicos.ranking.abrir,
                            icon: const Icon(Icons.leaderboard_rounded, size: 20),
                            label: Text(t('Ranking mundial')),
                          ),
                        TextButton.icon(
                          onPressed: _codigoDeAmigo,
                          icon: const Icon(Icons.group_add_rounded, size: 20),
                          label: Text(t('Código de amigo')),
                        ),
                        TextButton.icon(
                          onPressed: () => _abrir(ProgressoTela(servicos: servicos)),
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: Text(t('Salvar progresso')),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ladrilho colorido com ícone (modos Infinito e Desafio do dia).
class _Ladrilho extends StatelessWidget {
  const _Ladrilho({
    required this.icone,
    required this.titulo,
    required this.texto,
    required this.cores,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo, texto;
  final List<Color> cores;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: titulo,
    child: GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cores),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: Color.lerp(cores.last, Colors.black, 0.45)!, offset: const Offset(0, 5)),
            BoxShadow(color: cores.last.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, size: 32, color: Colors.white),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TextoContornado(
                titulo,
                tamanho: 20,
                alinhamento: TextAlign.start,
                contorno: Color.lerp(cores.last, Colors.black, 0.5)!,
              ),
            ),
            const SizedBox(height: 2),
            Text(texto, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}

class _Selo extends StatelessWidget {
  const _Selo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Cores.ouro, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFF4A3300)),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(color: Color(0xFF4A3300), fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

/// Logotipo: quatro blocos e o nome com uma cor por letra.
class Logo extends StatelessWidget {
  const Logo({super.key, this.tamanho = 56});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    const nome = 'ENCAIXA';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: tamanho * 1.6,
          height: tamanho * 1.1,
          child: const CustomPaint(painter: _PintorLogo()),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < nome.length; i++)
                Transform.rotate(
                  angle: (i.isEven ? -1 : 1) * 0.06,
                  child: TextoContornado(
                    nome[i],
                    tamanho: tamanho,
                    cor: Color.lerp(Cores.blocos[i % 6], Colors.white, 0.1)!,
                    contorno: const Color(0xFF1E0750),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PintorLogo extends CustomPainter {
  const _PintorLogo();

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.height / 2;
    final x0 = (s.width - 3 * c) / 2;
    // Forma de "T" encaixando: três em cima, um embaixo.
    pintarBloco(canvas, Rect.fromLTWH(x0, 0, c, c), Cores.blocos[0]);
    pintarBloco(canvas, Rect.fromLTWH(x0 + c, 0, c, c), Cores.blocos[2]);
    pintarBloco(canvas, Rect.fromLTWH(x0 + 2 * c, 0, c, c), Cores.blocos[4]);
    pintarBloco(canvas, Rect.fromLTWH(x0 + c, c, c, c), Cores.blocos[5]);
  }

  @override
  bool shouldRepaint(_PintorLogo antigo) => false;
}

/// Blocos soltos e apagados no fundo da tela inicial.
class _BlocosDeFundo extends CustomPainter {
  const _BlocosDeFundo();

  @override
  void paint(Canvas canvas, Size s) {
    final sorteio = Sorteio(42);
    final lado = s.width / 9;
    for (var i = 0; i < 18; i++) {
      final x = sorteio.proximo(1000) / 1000 * s.width;
      final y = sorteio.proximo(1000) / 1000 * s.height;
      pintarBloco(canvas, Rect.fromLTWH(x - lado / 2, y - lado / 2, lado, lado), Cores.blocos[i % 6], opacidade: 0.07);
    }
  }

  @override
  bool shouldRepaint(_BlocosDeFundo antigo) => false;
}

class _Sequencia extends StatelessWidget {
  const _Sequencia(this.dias, {required this.aoTocar});

  final int dias;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: t('Dias seguidos no Desafio do dia'),
    child: GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_rounded, color: Cores.blocos[1], size: 20),
            const SizedBox(width: 2),
            Text('$dias', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}

/// Marcos da sequência: o que já foi, quanto falta e o prêmio de cada um.
class _DialogoSequencia extends StatelessWidget {
  const _DialogoSequencia({required this.dias, required this.feitoHoje});

  final int dias;
  final bool feitoHoje;

  @override
  Widget build(BuildContext context) {
    final proximo = proximoMarco(dias);
    final chama = TemaDeBlocos.porId('chama');
    return AlertDialog(
      backgroundColor: Cores.painel,
      scrollable: true,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(t('Sequência do Desafio'), textAlign: TextAlign.center),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_fire_department_rounded, color: Cores.blocos[1], size: 34),
              Text(
                ' $dias ${t(dias == 1 ? 'dia' : 'dias')}',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            proximo == null
                ? t('Todos os marcos conquistados!')
                : (feitoHoje
                      ? t('Hoje já valeu. Faltam {0} para o próximo prêmio.', [proximo - dias])
                      : t('Jogue o Desafio de hoje: faltam {0} para o próximo prêmio.', [proximo - dias])),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
          const SizedBox(height: 12),
          for (final m in marcosDaSequencia)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dias >= m ? Cores.blocos[3].withValues(alpha: 0.3) : Cores.casa,
                borderRadius: BorderRadius.circular(14),
                border: m == proximo ? Border.all(color: Cores.ouro, width: 2) : null,
              ),
              child: Row(
                children: [
                  Icon(dias >= m ? Icons.check_circle_rounded : Icons.lock_outline_rounded, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('$m dias', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const IconeGema(tamanho: 16),
                  Text(' +${premioDaSequencia(m)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (m == chama.marcoDias) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.palette_rounded, size: 20, color: Cores.ouro),
                    Text(t(' Tema'), style: TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            t('Pulou um dia? Dá para recuperar a sequência uma vez por semana.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Cores.textoFraco),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('Fechar')))],
    );
  }
}

/// As 3 missões do dia e o baú.
class _CartaoMissoes extends StatelessWidget {
  const _CartaoMissoes({required this.progresso, required this.dia});

  final Progresso progresso;
  final int dia;

  @override
  Widget build(BuildContext context) {
    final missoes = missoesDoDia(dia);
    final todasPegas = List.generate(missoesPorDia, (i) => progresso.missaoPega(dia, i)).every((p) => p);
    final aberto = progresso.bauAberto(dia);
    return CartaoVidro(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: TextoContornado(t('Missões de hoje'), tamanho: 19, alinhamento: TextAlign.start)),
              IconButton(
                tooltip: t('Como funcionam as missões'),
                visualDensity: VisualDensity.compact,
                onPressed: () => mostrarDica(context, Dicas.missoes),
                icon: const Icon(Icons.info_outline_rounded, size: 22),
              ),
              _Bau(
                aberto: aberto,
                pronto: todasPegas && !aberto,
                aoTocar: () async {
                  await progresso.abrirBau(dia);
                  final nova = progresso.pegarFigurinhaRecente();
                  if (nova != null && context.mounted) await mostrarFigurinhaNova(context, nova);
                },
              ),
            ],
          ),
          for (var i = 0; i < missoes.length; i++)
            _LinhaMissao(
              missao: missoes[i],
              feito: progresso.progressoMissao(dia, missoes[i].tipo),
              pega: progresso.missaoPega(dia, i),
              aoPegar: () => progresso.pegarMissao(dia, i),
            ),
        ],
      ),
    );
  }
}

class _LinhaMissao extends StatelessWidget {
  const _LinhaMissao({required this.missao, required this.feito, required this.pega, required this.aoPegar});

  final Missao missao;
  final int feito;
  final bool pega;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    final completa = feito >= missao.alvo;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(missao.texto, style: TextStyle(fontSize: 14, color: pega ? Cores.textoFraco : Cores.texto)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (feito / missao.alvo).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: Cores.casa,
                    color: completa ? Cores.blocos[3] : Cores.blocos[4],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 74,
            child: pega
                ? Icon(Icons.check_circle_rounded, color: Cores.blocos[3])
                : completa
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: Cores.blocos[3],
                      foregroundColor: const Color(0xFF07361C),
                    ),
                    onPressed: aoPegar,
                    child: Text('+${missao.gemas}', style: const TextStyle(fontSize: 16)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        missao.tipo.maximo ? '' : '${feito.clamp(0, missao.alvo)}/${missao.alvo}  ',
                        style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
                      ),
                      Text(
                        '${missao.gemas}',
                        style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
                      ),
                      const IconeGema(tamanho: 14),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Bau extends StatelessWidget {
  const _Bau({required this.aberto, required this.pronto, required this.aoTocar});

  final bool aberto, pronto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: pronto ? aoTocar : null,
    icon: Icon(aberto ? Icons.inventory_2_outlined : Icons.redeem_rounded, color: pronto ? Cores.ouro : null),
    label: Text(aberto ? t('Aberto') : '+$gemasDoBau'),
  );
}

/// Evento com prazo (com tema grátis) ou aviso de gemas em dobro no fim de semana.
class _BannerEvento extends StatelessWidget {
  const _BannerEvento({required this.progresso, required this.agora});

  final Progresso progresso;
  final DateTime agora;

  static bool temAlgo(DateTime agora) => eventoAtivo(agora) != null || fimDeSemana(agora);

  @override
  Widget build(BuildContext context) {
    final evento = eventoAtivo(agora);
    final tema = evento?.tema == null ? null : TemaDeBlocos.porId(evento!.tema);
    final podePegar = tema != null && !progresso.temTema(tema);
    final cores = evento?.cores ?? [Cores.blocos[4], Cores.blocos[3]];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: cores),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Color.lerp(cores.last, Colors.black, 0.45)!, offset: const Offset(0, 5)),
          BoxShadow(color: cores.first.withValues(alpha: 0.45), blurRadius: 18),
        ],
      ),
      child: Row(
        children: [
          Icon(evento == null ? Icons.weekend_rounded : Icons.celebration_rounded, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('EVENTO · termina em {0}', [evento == null ? t('domingo') : tempoRestante(agora, evento.fim)]),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: TextoContornado(
                    evento != null ? t(evento.nome) : t('Fim de semana'),
                    tamanho: 20,
                    alinhamento: TextAlign.start,
                    contorno: Color.lerp(cores.last, Colors.black, 0.5)!,
                  ),
                ),
                Text(
                  t('Gemas em dobro · toque e saiba mais'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (podePegar)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 44),
                backgroundColor: Colors.white,
                foregroundColor: Color.lerp(cores.first, Colors.black, 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () async {
                await progresso.guardarTema(tema);
                await progresso.usarTema(tema);
              },
              child: Text(t('Tema\ngrátis'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1)),
            )
          else
            const TextoContornado('x2', tamanho: 28),
        ],
      ),
    );
  }
}

class _BotaoPresente extends StatelessWidget {
  const _BotaoPresente({required this.disponivel, required this.aoTocar});

  final bool disponivel;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: t('Presente do dia'),
    visualDensity: VisualDensity.compact,
    onPressed: aoTocar,
    icon: Badge(
      isLabelVisible: disponivel,
      backgroundColor: Cores.destaque,
      child: Icon(Icons.card_giftcard_rounded, color: disponivel ? Cores.ouro : null),
    ),
  );
}

/// Calendário de 7 dias de presentes por entrar no jogo.
class _DialogoPresente extends StatelessWidget {
  const _DialogoPresente({required this.progresso, required this.dia});

  final Progresso progresso;
  final int dia;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: progresso,
    builder: (context, _) {
      final hoje = progresso.presenteDeHoje(dia);
      final pego = progresso.presentePego(dia);
      final atual = hoje > 0 ? hoje : pego;
      return AlertDialog(
        backgroundColor: Cores.painel,
        // Com tela pequena e fonte grande o conteúdo rola em vez de o botão cobrir o último cartão.
        scrollable: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t('Presente do dia'), textAlign: TextAlign.center),
        ),
        content: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var d = 1; d <= 7; d++)
              Container(
                width: d == 7 ? 152 : 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: d < atual || (d == atual && pego > 0)
                      ? Cores.blocos[3].withValues(alpha: 0.35)
                      : (d == atual ? Cores.blocos[5] : Cores.casa),
                  borderRadius: BorderRadius.circular(14),
                  border: d == atual ? Border.all(color: Cores.ouro, width: 2) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      t('Dia {0}', [d]),
                      style: TextStyle(fontSize: 13, color: d == atual ? Colors.white : Cores.textoFraco),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const IconeGema(tamanho: 16),
                        Text(
                          ' ${gemasDoPresente(d)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (hoje > 0)
            FilledButton(
              onPressed: () => progresso.pegarPresente(dia),
              child: Text(t('Pegar +{0}', [gemasDoPresente(hoje)])),
            )
          else
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('Volte amanhã!'))),
        ],
      );
    },
  );
}

/// Pulou um dia do Desafio: oferece recuperar a sequência (anúncio ou gemas).
class _RecuperarSequencia extends StatelessWidget {
  const _RecuperarSequencia({required this.servicos, required this.dia});

  static const custo = 15;

  final Servicos servicos;
  final int dia;

  Future<void> _comAnuncio(BuildContext context) async {
    if (await servicos.anuncios.mostrarPremiado()) {
      await servicos.progresso.recuperarSequencia(dia);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('Anúncio indisponível agora. Tente de novo.'))));
    }
  }

  Future<void> _comGemas() async {
    if (await servicos.progresso.gastarGemas(custo)) await servicos.progresso.recuperarSequencia(dia);
  }

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.blocos[1].withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t('Sua sequência de {0} dias acabou!', [p.sequenciaPerdida(dia)]),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(t('Recupere agora (1 vez por semana).'), style: TextStyle(color: Cores.textoFraco)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                  onPressed: () => _comAnuncio(context),
                  icon: const Icon(Icons.smart_display_rounded),
                  label: Text(t('Anúncio')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
                  onPressed: p.gemas >= custo ? _comGemas : null,
                  icon: const IconeGema(),
                  label: const Text('$custo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Atalho da Arena da semana na tela inicial.
class _CartaoArena extends StatelessWidget {
  const _CartaoArena({
    required this.melhor,
    required this.premioDisponivel,
    required this.termina,
    required this.aoTocar,
  });

  final int melhor;
  final bool premioDisponivel;
  final String termina;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final trofeu = Arena.trofeuPara(melhor);
    final indice = trofeu == null ? -1 : Arena.trofeus.indexOf(trofeu);
    const cores = [Color(0xFFFFB800), Color(0xFFFF6A00)];
    return Semantics(
      button: true,
      label: t('Arena da semana'),
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: cores),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Color.lerp(cores.last, Colors.black, 0.45)!, offset: const Offset(0, 5)),
              BoxShadow(color: cores.first.withValues(alpha: 0.4), blurRadius: 18),
            ],
          ),
          child: Row(
            children: [
              Badge(
                isLabelVisible: premioDisponivel,
                backgroundColor: Cores.destaque,
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 44,
                  color: indice < 0 ? Colors.white : coresDosTrofeus[indice],
                  shadows: const [Shadow(color: Color(0xFF6B2A00), offset: Offset(0, 3))],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: TextoContornado(
                        t('Arena da semana'),
                        tamanho: 21,
                        alinhamento: TextAlign.start,
                        contorno: Color(0xFF7A3000),
                      ),
                    ),
                    Text(
                      premioDisponivel
                          ? t('Prêmio esperando por você!')
                          : (melhor == 0
                                ? t('Ganhe troféus e gemas')
                                : t('Melhor: {0} · {1}', [melhor, trofeu != null ? t(trofeu.nome) : t('sem troféu')])),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.15),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Com a fonte do sistema grande, encolhe em vez de empurrar/sobrepor o texto ao lado.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t('termina em'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text(termina, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cola o código que o amigo mandou e começa o desafio.
class _DialogoCodigoAmigo extends StatefulWidget {
  const _DialogoCodigoAmigo();

  @override
  State<_DialogoCodigoAmigo> createState() => _DialogoCodigoAmigoState();
}

class _DialogoCodigoAmigoState extends State<_DialogoCodigoAmigo> {
  final _campo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  Future<void> _colar() async {
    final dados = await Clipboard.getData(Clipboard.kTextPlain);
    if (dados?.text == null) return;
    setState(() {
      _campo.text = dados!.text!;
      _erro = null;
    });
  }

  void _comecar() {
    final desafio = DesafioAmigo.ler(_campo.text);
    if (desafio == null) {
      setState(() => _erro = t('Não achei um código. Cole a mensagem inteira que seu amigo mandou.'));
      return;
    }
    Navigator.of(context).pop(desafio);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Cores.painel,
    scrollable: true,
    title: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(t('Código de amigo'), textAlign: TextAlign.center),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t('Seu amigo mandou um código? Cole aqui e jogue com as mesmas peças dele. Vença a pontuação e ganhe gemas!'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.3),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _campo,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => setState(() => _erro = null),
          decoration: InputDecoration(
            hintText: t('Cole aqui (ENCAIXA-AMIGO-...)'),
            filled: true,
            fillColor: Cores.casa,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        if (_erro != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Cores.destaque, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
      ],
    ),
    actionsAlignment: MainAxisAlignment.center,
    actionsOverflowAlignment: OverflowBarAlignment.center,
    actions: [
      TextButton(onPressed: _colar, child: Text(t('Colar'))),
      TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('Cancelar'))),
      FilledButton(onPressed: _campo.text.trim().isEmpty ? null : _comecar, child: Text(t('Jogar'))),
    ],
  );
}

/// Segundo presente do dia, depois das 19h.
class _PresenteDaNoite extends StatelessWidget {
  const _PresenteDaNoite({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const cores = [Color(0xFF2B2FA8), Color(0xFF8B3DFF)];
    return Semantics(
      button: true,
      label: t('Presente da noite'),
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: cores),
            border: Border.all(color: Cores.ouro, width: 2),
            boxShadow: [BoxShadow(color: cores.last.withValues(alpha: 0.5), blurRadius: 18)],
          ),
          child: Row(
            children: [
              const Icon(Icons.nightlight_round, size: 34, color: Cores.ouro),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('Presente da noite!'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(t('Toque e leve +{0} gemas', [gemasDaNoite]), style: TextStyle(fontSize: 14, height: 1.2)),
                  ],
                ),
              ),
              const IconeGema(tamanho: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atalho pequeno (metade da largura): Álbum e Conquistas. O selo avisa quando há prêmio para pegar.
class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.cores,
    required this.contorno,
    required this.aoTocar,
    this.selo = 0,
  });

  final IconData icone;
  final String titulo, subtitulo;
  final List<Color> cores;
  final Color contorno;
  final VoidCallback aoTocar;
  final int selo;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: titulo,
    child: GestureDetector(
      onTap: aoTocar,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: cores),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: Color.lerp(cores.last, Colors.black, 0.45)!, offset: const Offset(0, 5)),
            BoxShadow(color: cores.first.withValues(alpha: 0.4), blurRadius: 18),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Badge(
              isLabelVisible: selo > 0,
              label: Text('$selo'),
              backgroundColor: Cores.destaque,
              child: Icon(
                icone,
                size: 38,
                color: Colors.white,
                shadows: [Shadow(color: contorno, offset: const Offset(0, 3))],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TextoContornado(titulo, tamanho: 20, alinhamento: TextAlign.start, contorno: contorno),
            ),
            Text(
              subtitulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.15),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Atalho da Roda da sorte: destaca quando há giro grátis.
class _CartaoRoda extends StatelessWidget {
  const _CartaoRoda({required this.giros, required this.aoTocar});

  final int giros;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const cores = [Color(0xFF00C2FF), Color(0xFF8B5CFF)];
    final gratis = giros == 0;
    final restantes = Roda.girosPorDia - giros;
    return Semantics(
      button: true,
      label: t('Roda da sorte'),
      child: GestureDetector(
        onTap: aoTocar,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: cores),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Color.lerp(cores.last, Colors.black, 0.45)!, offset: const Offset(0, 5)),
              BoxShadow(color: cores.first.withValues(alpha: 0.4), blurRadius: 18),
            ],
          ),
          child: Row(
            children: [
              Badge(
                isLabelVisible: gratis,
                backgroundColor: Cores.destaque,
                child: const Icon(
                  Icons.casino_rounded,
                  size: 40,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 3))],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextoContornado(t('Roda da sorte'), tamanho: 21, alinhamento: TextAlign.start),
                    Text(
                      gratis
                          ? t('Giro grátis hoje!')
                          : (restantes > 0 ? t('Mais {0} giros com anúncio', [restantes]) : t('Volte amanhã')),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gratis ? Colors.white : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  gratis ? t('GIRAR') : t('até 50'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: gratis ? const Color(0xFF5B2BD6) : Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
