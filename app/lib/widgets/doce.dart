import 'package:material_ui/material_ui.dart';

import '../tema.dart';

/// Botão "bala": degradê, borda inferior 3D e afunda ao tocar.
class BotaoDoce extends StatefulWidget {
  const BotaoDoce({
    super.key,
    required this.texto,
    required this.cor,
    this.icone,
    this.aoTocar,
    this.altura = 60,
    this.tamanhoTexto = 24,
    this.detalhe,
  });

  final String texto;
  final Color cor;
  final IconData? icone;
  final VoidCallback? aoTocar;
  final double altura;
  final double tamanhoTexto;

  /// Texto menor embaixo (ex.: "Fase 12").
  final String? detalhe;

  @override
  State<BotaoDoce> createState() => _BotaoDoceState();
}

class _BotaoDoceState extends State<BotaoDoce> {
  bool _apertado = false;

  @override
  Widget build(BuildContext context) {
    final ativo = widget.aoTocar != null;
    final cor = ativo ? widget.cor : const Color(0xFF5B5480);
    final borda = Color.lerp(cor, Colors.black, 0.38)!;
    const fundo = 6.0;
    final afundar = _apertado ? fundo - 2 : 0.0;
    return Semantics(
      button: true,
      label: widget.texto,
      child: GestureDetector(
        onTapDown: ativo ? (_) => setState(() => _apertado = true) : null,
        onTapCancel: () => setState(() => _apertado = false),
        onTapUp: ativo
            ? (_) {
                setState(() => _apertado = false);
                widget.aoTocar!();
              }
            : null,
        child: SizedBox(
          height: widget.altura + fundo,
          child: Stack(
            children: [
              Positioned.fill(
                top: fundo,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: borda,
                    borderRadius: BorderRadius.circular(widget.altura * 0.36),
                    boxShadow: [
                      BoxShadow(color: cor.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6)),
                    ],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: afundar,
                height: widget.altura,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.altura * 0.36),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(cor, Colors.white, 0.35)!, cor],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Faixa de brilho.
                      Positioned(
                        left: widget.altura * 0.3,
                        right: widget.altura * 0.3,
                        top: widget.altura * 0.1,
                        height: widget.altura * 0.18,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icone != null) ...[
                                  Icon(
                                    widget.icone,
                                    size: widget.tamanhoTexto * 1.25,
                                    color: Colors.white,
                                    shadows: [Shadow(color: borda, offset: const Offset(0, 2))],
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextoContornado(widget.texto, tamanho: widget.tamanhoTexto, contorno: borda),
                                    if (widget.detalhe != null)
                                      Text(
                                        widget.detalhe!,
                                        style: TextStyle(
                                          fontSize: widget.tamanhoTexto * 0.55,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          height: 1,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

/// Texto branco com contorno grosso e sombra (estilo de jogo).
class TextoContornado extends StatelessWidget {
  const TextoContornado(
    this.texto, {
    super.key,
    this.tamanho = 24,
    this.cor = Colors.white,
    this.contorno = const Color(0xFF2A0B5E),
    this.alinhamento = TextAlign.center,
  });

  final String texto;
  final double tamanho;
  final Color cor;
  final Color contorno;
  final TextAlign alinhamento;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(fontFamily: fonteJogo, fontSize: tamanho, fontWeight: FontWeight.w700, height: 1.1);
    return Stack(
      children: [
        Text(
          texto,
          textAlign: alinhamento,
          style: estilo.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = tamanho * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = contorno,
            shadows: [Shadow(color: contorno, offset: Offset(0, tamanho * 0.08))],
          ),
        ),
        Text(
          texto,
          textAlign: alinhamento,
          style: estilo.copyWith(color: cor),
        ),
      ],
    );
  }
}

/// Cartão de vidro com borda em degradê (usado nas seções da tela inicial).
class CartaoVidro extends StatelessWidget {
  const CartaoVidro({super.key, required this.child, this.cores, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final List<Color>? cores;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = cores ?? [Cores.brilhoRosa, Cores.brilhoCiano];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: c),
        boxShadow: [BoxShadow(color: c.first.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
        child: child,
      ),
    );
  }
}
