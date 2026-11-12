import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/sorteio.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/peca_widget.dart';
import 'jogo_tela.dart';
import 'loja_tela.dart';

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
                                  const Spacer(),
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
                                  const SizedBox(height: 14),
                                  _CartaoDesafio(
                                    numero: numeroDoDesafio(hoje),
                                    feito: p.desafioFeito == dia,
                                    pontos: p.desafioPontos,
                                    aoTocar: () => _abrir(context, JogoTela(servicos: servicos, diario: true)),
                                  ),
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
                      feito ? 'Feito: $pontos pontos. Dá para melhorar!' : 'Mesmas peças para todo mundo',
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
