import 'package:material_ui/material_ui.dart';

import '../servicos/servicos.dart';
import '../tema.dart';
import 'doce.dart';
import '../idioma.dart';

/// Um texto de ajuda: aparece uma vez como janela e fica na tela "Como jogar".
class Dica {
  const Dica(this.id, this.titulo, this.icone, this.cor, this.linhas, {this.botao = 'ENTENDI'});

  final String id;
  final String titulo;
  final IconData icone;
  final Color cor;
  final List<String> linhas;

  /// Texto do botão que fecha a janela.
  final String botao;
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

  static const umaCor = Dica('uma-cor', 'Linhas de uma cor', Icons.palette_rounded, Color(0xFFA64DFF), [
    'Nesta fase as peças vêm em só 3 cores.',
    'Encha uma linha ou coluna inteira com blocos da MESMA cor.',
    'Dica: guarde uma linha para cada cor e não misture.',
  ]);

  static const combo = Dica('combo', 'Combo', Icons.bolt_rounded, Color(0xFFFF2E7E), [
    'Cada jogada que limpa linha aumenta o combo: x2, x3, x4...',
    'O combo só zera depois de 3 jogadas seguidas sem limpar nada.',
    'Dica: deixe várias linhas quase cheias e vá fechando uma por jogada.',
  ]);

  static const infinito = Dica('infinito', 'Modo Infinito', Icons.all_inclusive_rounded, Color(0xFFFF8A00), [
    'Jogue até não caber mais nenhuma peça: não tem limite de pontos.',
    'Cada meta de pontos (1.000, 2.500, 5.000...) dá gemas e sobe o nível: as peças ficam maiores.',
    'Elogios maiores (Ótimo, Incrível, Fantástico) vêm de várias linhas de uma vez e de combos.',
    'Tente bater o seu recorde. A partida fica salva: pode sair e continuar depois.',
  ]);

  static const desafio = Dica('desafio', 'Desafio do dia', Icons.event_rounded, Color(0xFFFF2E7E), [
    'Todo dia um desafio novo, com as MESMAS peças para todo mundo.',
    'Jogue para ganhar +5 gemas e manter a sua sequência de dias 🔥.',
    'Prêmios extras com 3, 7, 14 e 30 dias seguidos.',
    'Faixas de pontuação no dia: Bronze (1.500) +3 gemas, Prata (4.000) +8 e Ouro (8.000) +15.',
    'Depois das 19h tem ainda um presente da noite na tela inicial.',
    'Compartilhe a pontuação e desafie os amigos.',
  ]);

  static const missoes = Dica('missoes', 'Missões e baú', Icons.redeem_rounded, Color(0xFF00E08A), [
    'Todo dia aparecem 5 missões novas.',
    'Elas avançam sozinhas enquanto você joga qualquer modo.',
    'Missão completa? Toque no botão verde para pegar as gemas.',
    'Pegou as 5? Abra o baú: +15 gemas.',
  ]);

  static const presente = Dica('presente', 'Presente do dia', Icons.card_giftcard_rounded, Color(0xFFFFCC33), [
    'Entre todo dia e pegue um presente de gemas.',
    'Dias seguidos aumentam o presente: o 7º dia vale 30 gemas.',
    'Pulou um dia? O calendário recomeça.',
  ]);

  static const roda = Dica('roda', 'Roda da sorte', Icons.casino_rounded, Color(0xFF00C2FF), [
    'Todo dia você ganha 1 giro grátis na Roda da sorte.',
    'Pode girar mais 2 vezes vendo um anúncio (grátis no Encaixa+).',
    'Cada giro dá de 5 a 50 gemas.',
  ]);

  static const progresso = Dica('progresso', 'Salvar o progresso', Icons.save_rounded, Color(0xFF3FE0D0), [
    'O jogo salva o seu progresso sozinho. Se você reinstalar, ele tenta recuperar na primeira abertura.',
    'Funciona melhor com o Backup do Google ligado (Configurações > Google > Backup).',
    'Para garantir, ou para trocar de celular, toque em "Salvar progresso" (no fim da tela inicial, ou na Loja) e copie o código.',
    'No celular novo, abra o mesmo botão, cole o código e toque em Recuperar.',
    'As compras (Sem anúncios e Encaixa+) voltam em Loja > Restaurar compras.',
  ]);

  static const eventos = Dica('eventos', 'Eventos', Icons.celebration_rounded, Color(0xFFFF2E7E), [
    'Eventos duram alguns dias e aparecem no banner da tela inicial.',
    'Durante o evento, linhas de uma cor e tabuleiro limpo dão gemas EM DOBRO.',
    'Alguns eventos dão um tema de blocos grátis: pegue antes de acabar, ele fica com você para sempre.',
    'Todo fim de semana (sexta 18h a domingo) também tem gemas em dobro.',
  ]);

  static const relampago = Dica('relampago', 'Relâmpago', Icons.timer_rounded, Color(0xFFFFB800), [
    'Você tem 60 segundos. O tempo só começa a correr na sua primeira jogada.',
    'Faça o máximo de pontos: linhas e combos valem muito.',
    'Se o tabuleiro encher antes, a partida acaba (não tem segunda chance).',
    'No fim, ganha 1 gema a cada 150 pontos (até 15).',
  ]);

  static const puzzle = Dica('puzzle', 'Puzzle do dia', Icons.psychology_rounded, Color(0xFF7C4DFF), [
    'Todo dia tem um tabuleiro novo, com 3 peças já definidas: não vêm outras.',
    'Pense na ordem e nas posições para limpar o máximo de linhas.',
    'A meta aparece em cima. Bateu a meta: 3 estrelas. Estrelas dão gemas (só uma vez por dia).',
    'Pode tentar de novo quantas vezes quiser para melhorar as estrelas.',
  ]);

  static const zen = Dica('zen', 'Modo Zen', Icons.spa_rounded, Color(0xFF00C2A8), [
    'Sem pressa e sem fim: quando nada mais cabe, o jogo tira as linhas e colunas mais cheias e você continua.',
    'Não vale recorde, gemas nem missões. É só para relaxar.',
    'A partida fica guardada: pode sair e voltar quando quiser.',
  ]);

  static const duelo = Dica('duelo', 'Dois jogadores', Icons.people_alt_rounded, Color(0xFFFF6A00), [
    'Um celular, dois jogadores: cada um joga uma partida, um depois do outro.',
    'As peças são as MESMAS para os dois, então ganha quem joga melhor.',
    'Vence quem fizer mais pontos. Não vale recorde, gemas nem missões.',
  ]);

  static const passe = Dica('passe', 'Passe de temporada', Icons.emoji_events_rounded, Color(0xFFFF8A00), [
    'Todo mês tem um Passe novo com 20 níveis. Jogar enche a barra.',
    'Desafio do dia dá 40, baú das missões 30, fases até 19 e partidas 5 (as 10 primeiras do dia).',
    'Cada 100 de XP é um nível, e cada nível dá gemas. O nível 20 dá o tema Aurora.',
    'Com o Encaixa+ as gemas do Passe vêm em dobro.',
    'No mês seguinte a trilha recomeça do zero: resgate os prêmios antes!',
  ]);

  static const especiais = Dica('especiais', 'Blocos especiais', Icons.auto_awesome_rounded, Color(0xFFFFB800), [
    'No Infinito, depois da primeira meta, algumas peças trazem um bloco especial.',
    'Bomba (bola escura): quando a linha dela some, leva junto a área 3x3 em volta (menos pedras).',
    'Joia (losango brilhante): quando a linha dela some, dá +1 gema e +30 pontos.',
    'Gelo (bloco esbranquiçado): precisa de DUAS linhas. A primeira só racha; a segunda tira e dá +1 gema e +20 pontos.',
    'Curinga (anel colorido): vale por qualquer cor na linha de uma cor só.',
    'Raio (relâmpago amarelo): quando a linha dele some, limpa também a outra linha ou coluna inteira que passa por ele.',
    'Só aparecem no Infinito: Desafio, Arena e fases continuam com as mesmas peças para todos.',
  ]);

  static const baus = Dica('baus', 'Baús e coleção', Icons.inventory_2_rounded, Color(0xFFFFC62E), [
    'Você ganha baús jogando: Desafio do dia, níveis 5, 10, 15 e 20 do Passe, álbum completo e 14 e 30 dias de sequência.',
    'Também dá para abrir até 3 baús COMUNS por dia vendo um anúncio (com Encaixa+ é sem anúncio).',
    'Cada baú traz um item de APARÊNCIA: tema de blocos, moldura, cor do Quadrinho ou fundo do jogo. Nada muda a pontuação.',
    'As chances de cada raridade ficam sempre na tela do baú, com garantia de Raro e de Lendário.',
    'Item repetido sobe de nível (até 5 estrelas) e, no máximo, vira gemas.',
    'Toque num item que você tem para equipar. "Padrão" volta ao visual original.',
  ]);

  static const album = Dica('album', 'Álbum de figurinhas', Icons.collections_bookmark_rounded, Color(0xFF00D084), [
    'Concluir o Desafio do dia dá uma figurinha nova.',
    'Abrir o baú das missões do dia também dá uma.',
    'Nunca vem repetida: cada uma que chega é uma que faltava.',
    'Completou o álbum? Ganha gemas e libera o próximo.',
  ]);

  static const reforcos = Dica('reforcos', 'Martelo e Bomba', Icons.hardware_rounded, Color(0xFFFFCC33), [
    'Martelo (4 gemas): toque nele e depois num bloco colorido para tirá-lo.',
    'Bomba (8 gemas): toque nela e depois no centro de uma área 3x3 para limpar os blocos dali.',
    'Pedras das fases não saem com eles: só quebram completando a linha ou a coluna.',
    'Tocou no reforço sem querer? Toque nele de novo para cancelar. As gemas só saem quando você usa.',
  ]);

  static const gemas = Dica('gemas', 'Gemas e reforços', Icons.diamond_rounded, Color(0xFF3FE0D0), [
    'Desfazer (3 gemas): volta a última jogada.',
    'Trocar (5 gemas): troca as 3 peças da mão.',
    'Martelo (4 gemas): tira um bloco. Bomba (8 gemas): limpa uma área 3x3. Pedras não saem.',
    'Continuar (10 gemas): segunda chance quando acaba o espaço.',
    'Gemas vêm de linhas de uma cor, missões, fases, presentes, eventos e da loja.',
  ]);

  static const arena = Dica('arena', 'Arena da semana', Icons.emoji_events_rounded, Color(0xFFFFCC33), [
    'Um torneio por semana, de segunda a domingo, com as MESMAS peças para todo mundo.',
    'Jogue quantas vezes quiser: vale a sua melhor partida da semana.',
    'Bata as metas para ganhar troféus: Bronze (500), Prata (1.500), Ouro (3.000) e Diamante (6.000).',
    'Cada troféu dá gemas. Pegue na tela da Arena antes de a semana acabar!',
  ]);

  static const todas = [
    comoJogar,
    fases,
    pedras,
    pontos,
    umaCor,
    combo,
    infinito,
    desafio,
    arena,
    missoes,
    presente,
    reforcos,
    album,
    baus,
    puzzle,
    zen,
    duelo,
    passe,
    especiais,
    relampago,
    roda,
    progresso,
    eventos,
    gemas,
  ];
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
  Widget build(BuildContext context) {
    // Respeita as barras do sistema (o botão não pode ficar embaixo da barra de navegação do Android).
    final barras = MediaQuery.viewPaddingOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(24, 24 + barras.top, 24, 24 + barras.bottom),
      child: CartaoVidro(
        cores: [dica.cor, Cores.brilhoCiano],
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(dica.icone, size: 52, color: dica.cor),
            const SizedBox(height: 4),
            TextoContornado(t(dica.titulo), tamanho: 26),
            const SizedBox(height: 12),
            // Texto longo ou fonte grande: só as linhas rolam, o botão fica sempre à vista.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in dica.linhas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(Icons.star_rounded, size: 16, color: dica.cor),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t(l), style: const TextStyle(fontSize: 16, height: 1.3))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            BotaoDoce(
              texto: t(dica.botao),
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
}
