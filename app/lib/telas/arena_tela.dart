import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/arena.dart';
import '../jogo/eventos.dart' show tempoRestante;
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';
import 'jogo_tela.dart';

/// Cor de cada troféu (Bronze, Prata, Ouro, Diamante).
const coresDosTrofeus = [Color(0xFFE08A4B), Color(0xFFCFD8E8), Color(0xFFFFCC33), Color(0xFF6FF3FF)];

/// Arena da semana: melhor pontuação, troféus e prêmios.
class ArenaTela extends StatelessWidget {
  const ArenaTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso;
    final agora = servicos.hoje();
    final semana = Arena.semana(agora);
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: p,
            builder: (context, _) {
              final melhor = p.arenaMelhor(semana);
              final trofeu = Arena.trofeuPara(melhor);
              final indice = trofeu == null ? -1 : Arena.trofeus.indexOf(trofeu);
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
                      const TextoContornado('Arena', tamanho: 26),
                      IconButton(
                        tooltip: 'Como funciona a Arena',
                        onPressed: () => mostrarDica(context, Dicas.arena),
                        icon: const Icon(Icons.info_outline_rounded),
                      ),
                      const Spacer(),
                      GemasChip(gemas: p.gemas),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CartaoVidro(
                    cores: const [Color(0xFFFFCC33), Color(0xFFFF8A00)],
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 84,
                          color: indice < 0 ? const Color(0xFF5B5480) : coresDosTrofeus[indice],
                          shadows: const [Shadow(color: Color(0xFF2A0B5E), offset: Offset(0, 4))],
                        ),
                        TextoContornado(trofeu?.nome ?? 'Sem troféu ainda', tamanho: 24),
                        const SizedBox(height: 6),
                        const Text('Melhor partida da semana', style: TextStyle(color: Cores.textoFraco)),
                        TextoContornado('$melhor', tamanho: 44),
                        const SizedBox(height: 4),
                        Text(
                          'Termina em ${tempoRestante(agora, Arena.fim(agora))}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Cores.ouro),
                        ),
                        const SizedBox(height: 14),
                        BotaoDoce(
                          texto: p.temPartidaSalva('arena') ? 'CONTINUAR' : 'JOGAR NA ARENA',
                          icone: Icons.play_arrow_rounded,
                          cor: Cores.blocos[3],
                          altura: 58,
                          tamanhoTexto: 22,
                          aoTocar: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => JogoTela(servicos: servicos, arena: true))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextoContornado('Troféus da semana', tamanho: 21, alinhamento: TextAlign.start),
                  const SizedBox(height: 8),
                  for (var i = 0; i < Arena.trofeus.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LinhaTrofeu(
                        trofeu: Arena.trofeus[i],
                        cor: coresDosTrofeus[i],
                        melhor: melhor,
                        pego: p.premioArenaPego(semana, Arena.trofeus[i].nome),
                        aoPegar: () => p.pegarPremioArena(semana, Arena.trofeus[i]),
                      ),
                    ),
                  const SizedBox(height: 6),
                  const CartaoVidro(
                    child: Row(
                      children: [
                        Icon(Icons.public_rounded, size: 34, color: Cores.brilhoCiano),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Em breve: ranking com jogadores do mundo todo e prêmios por posição.',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
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

class _LinhaTrofeu extends StatelessWidget {
  const _LinhaTrofeu({
    required this.trofeu,
    required this.cor,
    required this.melhor,
    required this.pego,
    required this.aoPegar,
  });

  final Trofeu trofeu;
  final Color cor;
  final int melhor;
  final bool pego;
  final VoidCallback aoPegar;

  @override
  Widget build(BuildContext context) {
    final alcancado = melhor >= trofeu.pontos;
    return CartaoVidro(
      cores: [cor, cor.withValues(alpha: 0.3)],
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, size: 40, color: alcancado ? cor : const Color(0xFF5B5480)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trofeu.nome} · ${trofeu.pontos} pts',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: (melhor / trofeu.pontos).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Cores.casa,
                    color: cor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: pego
                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E08A), size: 30)
                : alcancado
                ? FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(64, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: const Color(0xFF00E08A),
                      foregroundColor: const Color(0xFF07361C),
                    ),
                    onPressed: aoPegar,
                    child: Text('+${trofeu.gemas}'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${trofeu.gemas}',
                        style: const TextStyle(color: Cores.gema, fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const IconeGema(tamanho: 16),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
