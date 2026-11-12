import 'package:material_ui/material_ui.dart';

import '../servicos/servicos.dart';
import '../tema.dart';
import 'doce.dart';

/// Um texto de ajuda: aparece uma vez como janela e fica na tela "Como jogar".
class Dica {
  const Dica(this.id, this.titulo, this.icone, this.cor, this.linhas);

  final String id;
  final String titulo;
  final IconData icone;
  final Color cor;
  final List<String> linhas;
}

abstract final class Dicas {
  static const comoJogar = Dica('como-jogar', 'Como jogar', Icons.touch_app_rounded, Color(0xFF00E08A), [
    'Arraste as peças de baixo para o tabuleiro.',
    'Complete uma linha ou coluna inteira e ela some, dando pontos.',
    'Limpar várias de uma vez ou em jogadas seguidas faz COMBO e vale muito mais.',
    'Linha toda de uma cor só vale bônus e 1 gema.',
    'Peça cinza na mão é peça que não cabe em lugar nenhum.',
  ]);

  static const fases = Dica('fases', 'Fases', Icons.map_rounded, Color(0xFF00B4FF), [
    'Cada fase tem um objetivo (lá em cima) e um limite de peças.',
    'Cumpra o objetivo antes de acabar as peças para passar.',
    'Sobrou bastante peça? Ganha até 3 estrelas.',
    'Ficou sem peça ou sem espaço? Dá para pedir ajuda com anúncio ou gemas.',
    'A cada 20 fases, um mundo novo e +15 gemas.',
  ]);

  static const pedras = Dica('pedras', 'Pedras', Icons.landscape_rounded, Color(0xFF8E8AA6), [
    'Blocos cinza rachados são pedras.',
    'Elas não saem sozinhas: complete a linha ou a coluna onde a pedra está para quebrá-la.',
    'Quebre todas para passar de fase.',
  ]);

  static const pontos = Dica('pontos', 'Fase de pontos', Icons.star_rounded, Color(0xFFFFCC33), [
    'Faça a pontuação pedida antes de acabar as peças.',
    'Cada bloco vale 1 ponto; cada linha limpa vale 10.',
    'Combos e várias linhas de uma vez multiplicam os pontos!',
  ]);

  static const infinito = Dica('infinito', 'Modo Infinito', Icons.all_inclusive_rounded, Color(0xFFFF8A00), [
    'Jogue até não caber mais nenhuma peça.',
    'Tente bater o seu recorde.',
    'A partida fica salva: pode sair e continuar depois.',
  ]);

  static const desafio = Dica('desafio', 'Desafio do dia', Icons.event_rounded, Color(0xFFFF2E7E), [
    'Todo dia um desafio novo, com as MESMAS peças para todo mundo.',
    'Jogue para ganhar +5 gemas e manter a sua sequência de dias 🔥.',
    'Prêmios extras com 3, 7, 14 e 30 dias seguidos.',
    'Compartilhe a pontuação e desafie os amigos.',
  ]);

  static const missoes = Dica('missoes', 'Missões e baú', Icons.redeem_rounded, Color(0xFF00E08A), [
    'Todo dia aparecem 3 missões novas.',
    'Elas avançam sozinhas enquanto você joga qualquer modo.',
    'Missão completa? Toque no botão verde para pegar as gemas.',
    'Pegou as 3? Abra o baú: +10 gemas.',
  ]);

  static const presente = Dica('presente', 'Presente do dia', Icons.card_giftcard_rounded, Color(0xFFFFCC33), [
    'Entre todo dia e pegue um presente de gemas.',
    'Dias seguidos aumentam o presente: o 7º dia vale 30 gemas.',
    'Pulou um dia? O calendário recomeça.',
  ]);

  static const eventos = Dica('eventos', 'Eventos', Icons.celebration_rounded, Color(0xFFFF2E7E), [
    'Eventos duram alguns dias e aparecem no banner da tela inicial.',
    'Durante o evento, linhas de uma cor e tabuleiro limpo dão gemas EM DOBRO.',
    'Alguns eventos dão um tema de blocos grátis: pegue antes de acabar, ele fica com você para sempre.',
    'Todo fim de semana (sexta 18h a domingo) também tem gemas em dobro.',
  ]);

  static const gemas = Dica('gemas', 'Gemas e reforços', Icons.diamond_rounded, Color(0xFF3FE0D0), [
    'Desfazer (3 gemas): volta a última jogada.',
    'Trocar (5 gemas): troca as 3 peças da mão.',
    'Continuar (10 gemas): segunda chance quando acaba o espaço.',
    'Gemas vêm de linhas de uma cor, missões, fases, presentes, eventos e da loja.',
  ]);

  static const todas = [comoJogar, fases, pedras, pontos, infinito, desafio, missoes, presente, eventos, gemas];
}

/// Mostra a dica só na primeira vez (o jogador pode rever tudo em "Como jogar").
Future<void> mostrarDicaUmaVez(BuildContext context, Servicos s, Dica d) async {
  if (!s.mostrarDicas || s.progresso.dicaVista(d.id)) return;
  await s.progresso.marcarDica(d.id);
  if (context.mounted) await mostrarDica(context, d);
}

Future<void> mostrarDica(BuildContext context, Dica d) => showDialog<void>(
  context: context,
  builder: (_) => DialogoDica(dica: d),
);

class DialogoDica extends StatelessWidget {
  const DialogoDica({super.key, required this.dica});

  final Dica dica;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(24),
    child: CartaoVidro(
      cores: [dica.cor, Cores.brilhoCiano],
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(dica.icone, size: 52, color: dica.cor),
          const SizedBox(height: 4),
          TextoContornado(dica.titulo, tamanho: 26),
          const SizedBox(height: 12),
          ...dica.linhas.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.star_rounded, size: 16, color: dica.cor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l, style: const TextStyle(fontSize: 16, height: 1.3))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          BotaoDoce(
            texto: 'ENTENDI',
            cor: Cores.blocos[3],
            altura: 50,
            tamanhoTexto: 20,
            aoTocar: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
