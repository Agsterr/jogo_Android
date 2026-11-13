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
import '../widgets/roda_widget.dart';

/// Roda da sorte diária.
class RodaTela extends StatefulWidget {
  const RodaTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<RodaTela> createState() => _RodaTelaState();
}

class _RodaTelaState extends State<RodaTela> {
  final _roda = GlobalKey<RodaGiratoriaState>();
  int? _premio;
  bool _girando = false;

  Servicos get _s => widget.servicos;
  int get _dia => Sorteio.sementeDoDia(_s.hoje());

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
    setState(() {
      _girando = true;
      _premio = null;
    });
    HapticFeedback.mediumImpact();
    await _roda.currentState?.girarPara(fatia);
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
                      child: RodaGiratoria(
                        key: _roda,
                        rotulos: [for (final p in Roda.premios) '$p'],
                        cores: Cores.blocos,
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
