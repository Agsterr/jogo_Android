import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../jogo/roleta.dart';
import '../jogo/sorteio.dart';
import '../servicos/servicos.dart';
import '../servicos/sons.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import '../widgets/roda_widget.dart';
import '../idioma.dart';

/// Abre a roleta do fim de partida (se estiver ligada).
Future<void> mostrarRoletaDaPartida(BuildContext context, Servicos s, {int? semente}) async {
  if (!s.roletaAposPartida) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RoletaDaPartida(servicos: s, semente: semente),
  );
}

/// Roleta com prêmios bons e ruins: 1 giro grátis e mais [Roleta.girosExtras] vendo anúncio.
class RoletaDaPartida extends StatefulWidget {
  const RoletaDaPartida({super.key, required this.servicos, this.semente});

  final Servicos servicos;

  /// Semente fixa só nos testes; no jogo cada partida sorteia diferente.
  final int? semente;

  @override
  State<RoletaDaPartida> createState() => _RoletaDaPartidaState();
}

class _RoletaDaPartidaState extends State<RoletaDaPartida> {
  final _roda = GlobalKey<RodaGiratoriaState>();
  late final _sorteio = Sorteio(widget.semente ?? DateTime.now().microsecondsSinceEpoch);
  int _giros = 0;
  int? _ultimo;
  int _total = 0;
  bool _girando = false;

  Servicos get _s => widget.servicos;

  Future<void> _girar() async {
    if (_girando) return;
    if (_giros > 0 && !_s.progresso.assinante && !await _s.anuncios.mostrarPremiado()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('Anúncio indisponível agora. Tente de novo.'))));
      }
      return;
    }
    final fatia = Roleta.sortear(_sorteio);
    setState(() {
      _girando = true;
      _ultimo = null;
    });
    HapticFeedback.mediumImpact();
    await _roda.currentState?.girarPara(fatia);
    final premio = Roleta.premios[fatia];
    await _s.progresso.ganharGemas(premio);
    if (!mounted) return;
    _s.sons.tocar(premio > 0 ? Som.combo : Som.fim);
    setState(() {
      _girando = false;
      _giros++;
      _ultimo = premio;
      _total += premio;
    });
  }

  @override
  Widget build(BuildContext context) {
    final extrasRestantes = Roleta.girosExtras + 1 - _giros;
    final ultimo = _ultimo;
    // Respeita as barras do sistema; em tela baixa a roda encolhe em vez de empurrar os botões para fora.
    final barras = MediaQuery.viewPaddingOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(20, 20 + barras.top, 20, 20 + barras.bottom),
      child: CartaoVidro(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: TextoContornado(t('Roleta da partida'), tamanho: 26)),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: Center(
                child: ultimo == null
                    ? Text(
                        _girando ? t('Girando...') : t('Gire e tente a sorte!'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      )
                    : ultimo == 0
                    ? TextoContornado(t('Ah, não foi dessa vez!'), tamanho: 24, cor: Color(0xFFCFC8F0))
                    : TextoContornado(
                        t(ultimo == 1 ? '+{0} gema!' : '+{0} gemas!', [ultimo]),
                        tamanho: 32,
                        cor: const Color(0xFFFFF27A),
                        contorno: const Color(0xFFB0186A),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: LayoutBuilder(
                builder: (context, caixa) => SizedBox(
                  height: caixa.maxHeight < 250 ? caixa.maxHeight : 250,
                  child: Center(
                    child: RodaGiratoria(
                      key: _roda,
                      rotulos: [for (var i = 0; i < Roleta.premios.length; i++) Roleta.rotulo(i)],
                      // "Nada" em cinza: dá para ver que tem prêmio ruim.
                      cores: [
                        for (var i = 0; i < Roleta.premios.length; i++)
                          Roleta.premios[i] == 0 ? const Color(0xFF6B6390) : Cores.blocos[i % Cores.blocos.length],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  t(_total == 1 ? 'Total ganho: {0} gema' : 'Total ganho: {0} gemas', [_total]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 12),
            if (_giros == 0)
              BotaoDoce(
                texto: t('GIRAR'),
                icone: Icons.refresh_rounded,
                cor: Cores.blocos[3],
                altura: 54,
                tamanhoTexto: 22,
                aoTocar: _girando ? null : _girar,
              )
            else if (extrasRestantes > 0)
              BotaoDoce(
                texto: t('GIRAR DE NOVO'),
                detalhe: _s.progresso.assinante
                    ? t('Grátis no Encaixa+ · {0} restantes', [extrasRestantes])
                    : t('Vendo um anúncio · {0} restantes', [extrasRestantes]),
                icone: _s.progresso.assinante ? Icons.workspace_premium_rounded : Icons.smart_display_rounded,
                cor: Cores.blocos[5],
                altura: 54,
                tamanhoTexto: 20,
                aoTocar: _girando ? null : _girar,
              ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _girando ? null : () => Navigator.of(context).pop(),
              child: Text(_giros == 0 ? t('Agora não') : t('Continuar')),
            ),
          ],
        ),
      ),
    );
  }
}
