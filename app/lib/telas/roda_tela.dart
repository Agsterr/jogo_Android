import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/roda.dart';
import '../jogo/sorteio.dart';
import '../servicos/servicos.dart';
import '../servicos/sons.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';

/// Roda da sorte diária.
class RodaTela extends StatefulWidget {
  const RodaTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<RodaTela> createState() => _RodaTelaState();
}

class _RodaTelaState extends State<RodaTela> with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
  double _de = 0, _ate = 0;
  int? _premio;
  bool _girando = false;

  Servicos get _s => widget.servicos;
  int get _dia => Sorteio.sementeDoDia(_s.hoje());

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  Future<void> _girar({required bool comAnuncio}) async {
    if (_girando) return;
    if (comAnuncio && !_s.progresso.assinante && !await _s.anuncios.mostrarPremiado()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Anúncio indisponível agora. Tente de novo.')));
      }
      return;
    }
    final fatia = await _s.progresso.girarRoda(_dia);
    if (fatia == null || !mounted) return;
    const fatiaAngulo = 2 * math.pi / 8;
    // Para no meio da fatia sorteada, debaixo do ponteiro (topo), depois de 5 voltas.
    final alvo = -(fatia * fatiaAngulo + fatiaAngulo / 2);
    setState(() {
      _girando = true;
      _premio = null;
      _de = _ate % (2 * math.pi);
      _ate = alvo - 2 * math.pi * 5;
    });
    HapticFeedback.mediumImpact();
    await _giro.forward(from: 0);
    if (!mounted) return;
    _s.sons.tocar(Som.combo);
    HapticFeedback.heavyImpact();
    setState(() {
      _girando = false;
      _premio = Roda.premios[fatia];
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _s.progresso;
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: p,
            builder: (context, _) {
              final giros = p.girosNoDia(_dia);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const TextoContornado('Roda da sorte', tamanho: 26),
                        const Spacer(),
                        GemasChip(gemas: p.gemas),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 64,
                    child: _premio == null
                        ? const Text('Gire e ganhe gemas!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600))
                        : TextoContornado(
                            '+$_premio gemas!',
                            tamanho: 44,
                            cor: const Color(0xFFFFF27A),
                            contorno: const Color(0xFFB0186A),
                          ),
                  ),
                  Expanded(
                    flex: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            Positioned.fill(
                              top: 18,
                              child: AnimatedBuilder(
                                animation: _giro,
                                builder: (context, _) {
                                  final t = Curves.easeOutCubic.transform(_giro.value);
                                  return Transform.rotate(
                                    angle: _de + (_ate - _de) * t,
                                    child: const CustomPaint(painter: _PintorRoda()),
                                  );
                                },
                              ),
                            ),
                            const CustomPaint(size: Size(44, 46), painter: _Ponteiro()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: giros == 0
                        ? BotaoDoce(
                            texto: 'GIRAR GRÁTIS',
                            icone: Icons.refresh_rounded,
                            cor: Cores.blocos[3],
                            altura: 62,
                            tamanhoTexto: 24,
                            aoTocar: _girando ? null : () => _girar(comAnuncio: false),
                          )
                        : giros < Roda.girosPorDia
                        ? BotaoDoce(
                            texto: 'GIRAR DE NOVO',
                            detalhe: p.assinante
                                ? 'Grátis no Encaixa+ · ${Roda.girosPorDia - giros} restantes'
                                : 'Vendo um anúncio · ${Roda.girosPorDia - giros} restantes',
                            icone: p.assinante ? Icons.workspace_premium_rounded : Icons.smart_display_rounded,
                            cor: Cores.blocos[5],
                            altura: 62,
                            tamanhoTexto: 22,
                            aoTocar: _girando ? null : () => _girar(comAnuncio: true),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'Volte amanhã para girar de novo!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                  ),
                  const SizedBox(height: 28),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A roda: 8 fatias coloridas com o prêmio, aro com luzes e miolo.
class _PintorRoda extends CustomPainter {
  const _PintorRoda();

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide / 2;
    final fatia = 2 * math.pi / Roda.premios.length;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2A0B5E));
    final rFatia = r * 0.9;
    for (var i = 0; i < Roda.premios.length; i++) {
      final inicio = -math.pi / 2 + i * fatia;
      final cor = Cores.blocos[i % Cores.blocos.length];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rFatia),
        inicio,
        fatia,
        true,
        Paint()
          ..shader = RadialGradient(colors: [Color.lerp(cor, Colors.white, 0.35)!, cor])
              .createShader(Rect.fromCircle(center: c, radius: rFatia)),
      );
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rFatia),
        inicio,
        fatia,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white.withValues(alpha: 0.7),
      );
      // Prêmio escrito ao longo do raio.
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(inicio + fatia / 2 + math.pi / 2);
      final texto = TextPainter(
        text: TextSpan(
          text: '${Roda.premios[i]}',
          style: TextStyle(
            fontFamily: fonteJogo,
            fontSize: r * 0.17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: const [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 2), blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      texto.paint(canvas, Offset(-texto.width / 2, -rFatia * 0.82));
      canvas.restore();
    }
    // Luzes do aro.
    for (var i = 0; i < 16; i++) {
      final a = i * 2 * math.pi / 16;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 0.95,
        r * 0.025,
        Paint()..color = i.isEven ? Cores.ouro : Colors.white,
      );
    }
    // Miolo.
    canvas.drawCircle(c, r * 0.16, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.12, Paint()..color = Cores.destaque);
  }

  @override
  bool shouldRepaint(_PintorRoda antigo) => false;
}

/// Ponteiro dourado no topo.
class _Ponteiro extends CustomPainter {
  const _Ponteiro();

  @override
  void paint(Canvas canvas, Size s) {
    final caminho = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close();
    canvas.drawShadow(caminho, Colors.black, 4, false);
    canvas.drawPath(caminho, Paint()..color = Cores.ouro);
    canvas.drawPath(
      caminho,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_Ponteiro antigo) => false;
}
