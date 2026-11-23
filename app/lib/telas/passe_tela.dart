import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/passe.dart';
import '../jogo/sorteio.dart';
import '../jogo/temas.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';

/// Passe de temporada do mês: 20 níveis, cada um com gemas; o último dá o tema Aurora.
class PasseTela extends StatefulWidget {
  const PasseTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<PasseTela> createState() => _PasseTelaState();
}

class _PasseTelaState extends State<PasseTela> {
  Servicos get _s => widget.servicos;
  int get _dia => Sorteio.sementeDoDia(_s.hoje());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostrarDicaUmaVez(context, _s, Dicas.passe);
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
              final dia = _dia;
              final xp = p.passeXp(dia), nivel = p.passeNivel(dia), pegos = p.passePegos(dia);
              final cheio = nivel >= niveisDoPasse;
              final noNivel = cheio ? xpPorNivel : xp % xpPorNivel;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: TextoContornado(
                            'Passe de ${nomeDoMes(dia ~/ 100)}',
                            tamanho: 24,
                            alinhamento: TextAlign.start,
                          ),
                        ),
                      ),
                      GemasChip(gemas: p.gemas),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CartaoVidro(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cheio ? 'Passe completo!' : 'Nível $nivel de $niveisDoPasse',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text('$xp XP', style: const TextStyle(fontSize: 16, color: Cores.textoFraco)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: noNivel / xpPorNivel,
                            minHeight: 10,
                            backgroundColor: Cores.casa,
                            color: Cores.ouro,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cheio
                              ? 'Resgate os prêmios que faltam antes do fim do mês.'
                              : 'Faltam ${xpPorNivel - noNivel} XP para o nível ${nivel + 1}. '
                                    'Desafio +${XpDoPasse.desafio}, baú +${XpDoPasse.bau}, fase até +${XpDoPasse.fase(3)}, partida +${XpDoPasse.partida}.',
                          style: const TextStyle(fontSize: 13, height: 1.3, color: Cores.textoFraco),
                        ),
                        if (!p.assinante) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Com o Encaixa+ as gemas do Passe vêm em dobro '
                            '(${totalDoPasse(assinante: false)} viram ${totalDoPasse(assinante: true)}).',
                            style: const TextStyle(fontSize: 13, height: 1.3, color: Cores.ouro),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (var n = 1; n <= niveisDoPasse; n++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Nivel(
                        nivel: n,
                        gemas: gemasDoNivelDoPasse(n) * (p.assinante ? 2 : 1),
                        alcancado: n <= nivel,
                        pego: pegos.contains(n),
                        aoPegar: () => p.pegarNivelDoPasse(dia, n),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Nivel extends StatelessWidget {
  const _Nivel({
    required this.nivel,
    required this.gemas,
    required this.alcancado,
    required this.pego,
    required this.aoPegar,
  });

  final int nivel, gemas;
  final bool alcancado, pego;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    final ultimo = nivel == niveisDoPasse;
    final pronto = alcancado && !pego;
    final aurora = TemaDeBlocos.todos.firstWhere((t) => t.passe);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: Cores.painel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: pronto ? Border.all(color: Cores.ouro, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pego ? Cores.blocos[3] : (alcancado ? Cores.ouro : Cores.casa),
            ),
            child: Text(
              '$nivel',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: alcancado ? const Color(0xFF3A2400) : Cores.textoFraco,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const IconeGema(tamanho: 18),
          Text(' +$gemas', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          if (ultimo) ...[
            const SizedBox(width: 10),
            const Icon(Icons.palette_rounded, size: 20, color: Cores.ouro),
            Flexible(child: Text(' Tema ${aurora.nome}', style: const TextStyle(fontSize: 14))),
          ],
          const Spacer(),
          if (pronto)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: aoPegar,
              child: const Text('Pegar'),
            )
          else
            Icon(
              pego ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
              color: pego ? Cores.blocos[3] : Cores.textoFraco,
            ),
        ],
      ),
    );
  }
}
