import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/conquistas.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';

const _icones = <Medida, IconData>{
  Medida.partidas: Icons.sports_esports_rounded,
  Medida.recorde: Icons.emoji_events_rounded,
  Medida.linhas: Icons.view_week_rounded,
  Medida.combo: Icons.bolt_rounded,
  Medida.fases: Icons.map_rounded,
  Medida.estrelas: Icons.star_rounded,
  Medida.sequencia: Icons.local_fire_department_rounded,
  Medida.desafios: Icons.calendar_month_rounded,
  Medida.figurinhas: Icons.collections_bookmark_rounded,
  Medida.amigos: Icons.group_rounded,
};

class ConquistasTela extends StatelessWidget {
  const ConquistasTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso;
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: p,
            builder: (context, _) {
              final e = p.estatisticas, pegas = p.conquistasPegas;
              final feitas = Conquista.todas.where((c) => c.feita(e)).length;
              // Prontas para resgatar primeiro, depois as que faltam, e as já resgatadas no fim.
              final ordem = [...Conquista.todas]
                ..sort((a, b) {
                  int peso(Conquista c) => pegas.contains(c.id) ? 2 : (c.feita(e) ? 0 : 1);
                  return peso(a).compareTo(peso(b));
                });
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
                      const Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: TextoContornado('Conquistas', tamanho: 26, alinhamento: TextAlign.start),
                        ),
                      ),
                      Text(
                        '$feitas/${Conquista.todas.length}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final c in ordem)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Linha(
                        conquista: c,
                        valor: c.valor(e),
                        pega: pegas.contains(c.id),
                        aoPegar: () => p.pegarConquista(c.id),
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

class _Linha extends StatelessWidget {
  const _Linha({required this.conquista, required this.valor, required this.pega, required this.aoPegar});

  final Conquista conquista;
  final int valor;
  final bool pega;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    final c = conquista;
    final feita = valor >= c.meta;
    final cor = pega ? Cores.blocos[3] : (feita ? Cores.ouro : Cores.textoFraco);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Cores.painel.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: feita && !pega ? Border.all(color: Cores.ouro, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(pega ? Icons.check_circle_rounded : (_icones[c.medida] ?? Icons.star_rounded), size: 34, color: cor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(c.descricao, style: const TextStyle(fontSize: 13, height: 1.2, color: Cores.textoFraco)),
                if (!feita) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: valor / c.meta,
                      minHeight: 6,
                      backgroundColor: Cores.casa,
                      color: Cores.gema,
                    ),
                  ),
                  Text(
                    '${_formatar(valor)} / ${_formatar(c.meta)}',
                    style: const TextStyle(fontSize: 12, color: Cores.textoFraco),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (feita && !pega)
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: aoPegar,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [const IconeGema(tamanho: 16), Text(' +${c.gemas}')],
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconeGema(tamanho: 14),
                Text(' ${c.gemas}', style: TextStyle(fontSize: 14, color: pega ? Cores.textoFraco : null)),
              ],
            ),
        ],
      ),
    );
  }

  static String _formatar(int n) => n >= 1000 ? '${n ~/ 1000}.${(n % 1000).toString().padLeft(3, '0')}' : '$n';
}
