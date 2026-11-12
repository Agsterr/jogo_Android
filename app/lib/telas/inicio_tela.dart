import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/eventos.dart';
import '../jogo/fases.dart';
import '../jogo/missoes.dart';
import '../jogo/sorteio.dart';
import '../jogo/temas.dart';
import '../servicos/progresso.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/peca_widget.dart';
import 'jogo_tela.dart';
import 'loja_tela.dart';
import 'mapa_tela.dart';

class InicioTela extends StatelessWidget {
  const InicioTela({super.key, required this.servicos});

  final Servicos servicos;

  void _abrir(BuildContext context, Widget tela) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => tela));

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
                // Rola só quando não cabe (tela pequena ou fonte grande).
                builder: (context, _) => LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: Row(
                                children: [
                                  if (p.assinante) const _Selo('Encaixa+'),
                                  if (p.sequencia(dia) > 0) ...[const SizedBox(width: 8), _Sequencia(p.sequencia(dia))],
                                  const Spacer(),
                                  _BotaoPresente(
                                    disponivel: p.presenteDeHoje(dia) > 0,
                                    aoTocar: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => _DialogoPresente(progresso: p, dia: dia),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: p.somLigado ? 'Desligar som' : 'Ligar som',
                                    onPressed: p.alternarSom,
                                    icon: Icon(p.somLigado ? Icons.volume_up_rounded : Icons.volume_off_rounded),
                                  ),
                                  GemasChip(
                                    gemas: p.gemas,
                                    aoTocar: () => _abrir(context, LojaTela(servicos: servicos)),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 2),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Logo()),
                            const SizedBox(height: 8),
                            const Text(
                              'Encaixe. Limpe. Combine as cores.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Cores.textoFraco, fontSize: 16),
                            ),
                            const Spacer(flex: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_events_rounded, color: Cores.ouro),
                                const SizedBox(width: 6),
                                Text(
                                  'Recorde  ${p.recorde}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(64, 64),
                                      backgroundColor: Cores.blocos[3],
                                      foregroundColor: const Color(0xFF07361C),
                                      textStyle: const TextStyle(
                                        fontFamily: fonteJogo,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => _abrir(context, JogoTela(servicos: servicos)),
                                    icon: const Icon(Icons.play_arrow_rounded, size: 34),
                                    label: Text(p.temPartidaSalva('classico') ? 'CONTINUAR' : 'JOGAR'),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(64, 54),
                                      backgroundColor: Cores.blocos[4],
                                      foregroundColor: const Color(0xFF052E3D),
                                      textStyle: const TextStyle(
                                        fontFamily: fonteJogo,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onPressed: () => _abrir(context, MapaTela(servicos: servicos)),
                                    icon: const Icon(Icons.map_rounded, size: 26),
                                    label: Text('FASES · ${math.min(p.faseLiberada, Fase.total)}/${Fase.total}'),
                                  ),
                                  const SizedBox(height: 14),
                                  _CartaoDesafio(
                                    numero: numeroDoDesafio(hoje),
                                    feito: p.desafioFeito == dia,
                                    pontos: p.desafioPontos,
                                    aoTocar: () => _abrir(context, JogoTela(servicos: servicos, diario: true)),
                                  ),
                                  const SizedBox(height: 14),
                                  if (p.sequenciaPerdida(dia) > 0) ...[
                                    _RecuperarSequencia(servicos: servicos, dia: dia),
                                    const SizedBox(height: 14),
                                  ],
                                  if (_BannerEvento.temAlgo(hoje)) ...[
                                    _BannerEvento(progresso: p, agora: hoje),
                                    const SizedBox(height: 14),
                                  ],
                                  _CartaoMissoes(progresso: p, dia: dia),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(64, 50)),
                                    onPressed: () => _abrir(context, LojaTela(servicos: servicos)),
                                    icon: const Icon(Icons.storefront_rounded),
                                    label: const Text('Loja'),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDesafio extends StatelessWidget {
  const _CartaoDesafio({required this.numero, required this.feito, required this.pontos, required this.aoTocar});

  final int numero;
  final bool feito;
  final int pontos;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Cores.blocos[5], Cores.destaque])),
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(feito ? Icons.check_circle_rounded : Icons.calendar_today_rounded, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Desafio do dia #$numero', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                    Text(
                      feito ? 'Feito: $pontos pontos. Dá para melhorar!' : 'Mesmas peças para todos',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (!feito) ...[
                const Text('+5 ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const IconeGema(tamanho: 20),
              ],
            ],
          ),
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
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < nome.length; i++)
                  TextSpan(
                    text: nome[i],
                    style: TextStyle(color: Color.lerp(Cores.blocos[i % 6], Colors.white, 0.15)),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: tamanho,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              height: 1,
              shadows: const [Shadow(color: Color(0xFF0A0524), offset: Offset(0, 4))],
            ),
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
  const _Sequencia(this.dias);

  final int dias;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Dias seguidos no Desafio do dia',
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
  );
}

/// As 3 missões do dia e o baú.
class _CartaoMissoes extends StatelessWidget {
  const _CartaoMissoes({required this.progresso, required this.dia});

  final Progresso progresso;
  final int dia;

  @override
  Widget build(BuildContext context) {
    final missoes = missoesDoDia(dia);
    final todasPegas = List.generate(3, (i) => progresso.missaoPega(dia, i)).every((p) => p);
    final aberto = progresso.bauAberto(dia);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Missões de hoje', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              _Bau(aberto: aberto, pronto: todasPegas && !aberto, aoTocar: () => progresso.abrirBau(dia)),
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
    label: Text(aberto ? 'Aberto' : '+$gemasDoBau'),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: evento == null
              ? [Cores.blocos[4], Cores.blocos[3]]
              : [const Color(0xFFC62828), const Color(0xFF2E7D32)],
        ),
      ),
      child: Row(
        children: [
          Icon(evento == null ? Icons.weekend_rounded : Icons.celebration_rounded, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento == null ? 'Fim de semana' : 'Evento de ${evento.nome}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  evento == null
                      ? 'Gemas em dobro nas linhas de uma cor'
                      : 'Gemas em dobro · termina em ${tempoRestante(agora, evento.fim)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          if (podePegar)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8E1B1B),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () async {
                await progresso.guardarTema(tema);
                await progresso.usarTema(tema);
              },
              child: const Text('Tema grátis', style: TextStyle(fontSize: 15)),
            )
          else
            const Text('x2', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
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
    tooltip: 'Presente do dia',
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
        title: const Text('Presente do dia', textAlign: TextAlign.center),
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
                    Text('Dia $d', style: TextStyle(fontSize: 13, color: d == atual ? Colors.white : Cores.textoFraco)),
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
            FilledButton(onPressed: () => progresso.pegarPresente(dia), child: Text('Pegar +${gemasDoPresente(hoje)}'))
          else
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Volte amanhã!')),
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
          .showSnackBar(const SnackBar(content: Text('Anúncio indisponível agora. Tente de novo.')));
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
            'Sua sequência de ${p.sequenciaPerdida(dia)} dias acabou!',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Text('Recupere agora (1 vez por semana).', style: TextStyle(color: Cores.textoFraco)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
                  onPressed: () => _comAnuncio(context),
                  icon: const Icon(Icons.smart_display_rounded),
                  label: const Text('Anúncio'),
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
