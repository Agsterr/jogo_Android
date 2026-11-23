import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../idioma.dart';
import '../jogo/bau.dart';
import '../jogo/conquistas.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/doce.dart';

/// Números do jogador: tudo que o jogo já guarda, mais as últimas partidas em barras.
class EstatisticasTela extends StatelessWidget {
  const EstatisticasTela({super.key, required this.servicos});

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
              final e = p.estatisticas;
              final itens = p.itensDeBau.values.where((n) => n > 0).length;
              final numeros = <(IconData, String, String)>[
                (Icons.sports_esports_rounded, t('Partidas'), '${e.partidas}'),
                (Icons.emoji_events_rounded, t('Recorde'), '${e.recorde}'),
                (Icons.view_week_rounded, t('Linhas limpas'), '${p.linhasTotal}'),
                (Icons.touch_app_rounded, t('Jogadas'), '${p.jogadasTotal}'),
                (Icons.bolt_rounded, t('Melhor combo'), 'x${e.comboMax}'),
                (Icons.layers_rounded, t('Mais linhas de uma vez'), '${e.linhasMax}'),
                (
                  Icons.local_fire_department_rounded,
                  t('Maior sequência'),
                  '${e.sequenciaMax} ${t(e.sequenciaMax == 1 ? 'dia' : 'dias')}',
                ),
                (Icons.calendar_month_rounded, t('Desafios feitos'), '${e.desafios}'),
                (Icons.map_rounded, t('Fases vencidas'), '${e.fasesConcluidas}'),
                (Icons.star_rounded, t('Estrelas'), '${e.estrelas}'),
                (Icons.timer_rounded, t('Melhor Relâmpago'), '${e.relampago}'),
                (Icons.group_rounded, t('Amigos vencidos'), '${e.amigosVencidos}'),
                (Icons.collections_bookmark_rounded, t('Figurinhas'), '${e.figurinhas}'),
                (
                  Icons.military_tech_rounded,
                  t('Conquistas'),
                  '${Conquista.todas.where((c) => c.feita(e)).length}/${Conquista.todas.length}',
                ),
                (Icons.inventory_2_rounded, t('Baús abertos'), '${p.bausAbertos}'),
                (Icons.palette_rounded, t('Itens da coleção'), '$itens/${ItensDeBau.todos.length}'),
              ];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: t('Voltar'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(child: TextoContornado(t('Estatísticas'), tamanho: 26)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CartaoVidro(child: _UltimasPartidas(pontos: p.ultimasPartidas)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (icone, nome, valor) in numeros)
                        SizedBox(
                          width: (MediaQuery.sizeOf(context).width - 32 - 10) / 2,
                          child: _Numero(icone: icone, nome: nome, valor: valor),
                        ),
                    ],
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

class _Numero extends StatelessWidget {
  const _Numero({required this.icone, required this.nome, required this.valor});

  final IconData icone;
  final String nome, valor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Icon(icone, color: Cores.ouro, size: 26),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              Text(nome, style: const TextStyle(fontSize: 12, color: Cores.textoFraco)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Barras com os pontos das últimas partidas (a mais nova à direita).
class _UltimasPartidas extends StatelessWidget {
  const _UltimasPartidas({required this.pontos});

  final List<int> pontos;

  @override
  Widget build(BuildContext context) {
    final maior = pontos.fold(1, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t('Últimas partidas'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (pontos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(t('Jogue uma partida para ver o gráfico'), style: const TextStyle(color: Cores.textoFraco)),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < pontos.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('${pontos[i]}', style: const TextStyle(fontSize: 11, color: Cores.textoFraco)),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 6 + 84 * pontos[i] / maior,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  i == pontos.length - 1 ? Cores.ouro : Cores.brilhoCiano,
                                  i == pontos.length - 1 ? const Color(0xFFFF8A00) : const Color(0xFF8B5CFF),
                                ],
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
      ],
    );
  }
}
