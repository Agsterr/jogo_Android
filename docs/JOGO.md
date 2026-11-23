# Design do jogo — Encaixa

## Ideia em uma frase
Quebra-cabeça de blocos (o gênero que domina o topo das lojas há dois anos) com dois toques próprios: **cores que valem
bônus** e **Desafio do dia compartilhável** (mesmas peças para todo mundo, como os jogos diários de palavras).

## Por que pega
- **Fácil:** arrastar e soltar, sem tutorial. Entende-se em 5 segundos.
- **Sessão curta:** uma partida dura de 2 a 6 minutos, cabe na fila do ônibus.
- **"Só mais uma":** recorde sempre visível, combo na tela, quase-vitória na segunda chance.
- **Satisfação:** a linha que vai sumir acende com a cor da peça *antes* de soltar; os blocos encolhem e o texto
  "Combo x3 +120" pula no meio do tabuleiro; vibração leve.
- **Volta todo dia:** Desafio do dia (+5 gemas na primeira vez) e, para assinantes, +10 gemas diárias.
- **Boca a boca:** botão "Desafiar amigos" compartilha a pontuação com o link da loja.

## Regras
- Grade 8×8. A mão tem 3 peças (23 formatos, 6 cores). Quando as 3 são usadas, vêm outras 3.
- O sorteio tenta até 30 vezes garantir que **pelo menos uma** peça da mão nova caiba (justo, sem ser fácil demais).
- Linha ou coluna cheia some. Acaba quando nenhuma peça da mão cabe.
- Peça que não cabe em lugar nenhum aparece cinza na mão.

## Ajuda e tutorial (`app/lib/widgets/dicas.dart`)
- **Fase 1:** tutorial em 3 passos que acompanha as jogadas (arrastar → encher uma linha → objetivo e estrelas).
- **Primeira vez** no Infinito, no Desafio do dia, numa fase de pedras e numa de pontos: uma janela explica o modo.
- Tocar no banner do evento explica os eventos; o "i" das missões explica missões e baú.
- Botão **?** na tela inicial abre "Como jogar" com todos os textos.

## Pontuação (`app/lib/jogo/partida.dart`)
| Evento | Pontos |
|---|---|
| Cada bloco colocado | 1 |
| Limpar *n* linhas/colunas de uma vez | 10 × n² × combo |
| Linha de uma cor só | +20 e **+1 gema** |
| Tabuleiro vazio | +300 e **+3 gemas** |

**Combo:** sobe 1 a cada jogada que limpa; só zera depois de 3 jogadas seguidas sem limpar.

## Elogios (`app/lib/jogo/elogios.dart`)
Depois de limpar linhas, o texto no meio do tabuleiro cresce com a força da jogada. **Força = linhas limpas + combo acima
do primeiro.** O tamanho, a cor, a vibração e o som acompanham o nível.

| Elogio | Quando | Som |
|---|---|---|
| Boa! | 1 linha (força 1) | `linha` |
| Ótimo! | força 2 ou 3 (2 linhas; 1 linha no combo x2 ou x3) | `combo` |
| Incrível! | força 4 ou 5 (4 linhas; 2 linhas no combo x3) | `incrivel` |
| Fantástico! | força 6 ou mais | `fantastico` |
| Perfeito! | tabuleiro vazio | `fantastico` |

## Infinito: metas de pontos e níveis (`app/lib/jogo/marcos.dart`)
Só no modo Infinito (Desafio, Arena e fases têm as mesmas peças para todos e não mudam).
- **Metas:** 1.000 (+3 gemas), 2.500 (+5), 5.000 (+10), 10.000 (+20), 20.000 (+40) e 40.000 (+80). A barra sob o placar
  mostra o nível, o progresso e a próxima meta.
- **Nível = metas pagas + 1.** A cada meta as peças grandes (5 blocos ou mais) saem mais e as pequenas (1 ou 2 blocos)
  menos, até o nível 5 (4 metas). A mão nova continua sempre com pelo menos uma peça que cabe.
- A meta é paga **uma vez só**: desfazer e jogar de novo não paga de novo. Partidas salvas antes das metas existirem não
  recebem as metas que já tinham passado.
- No nível 0 o sorteio é idêntico ao de antes (conferido nas 300 fases e em partidas de teste).

## Reforços (gastam gemas)
| Reforço | Custo | Efeito |
|---|---|---|
| Desfazer | 3 | volta a última jogada (um nível) |
| Trocar | 5 | sorteia uma mão nova |
| Martelo | 4 | toque nele e depois num bloco colorido: o bloco some (sem pontos e sem completar linha) |
| Bomba | 8 | toque nela e depois no centro de uma área 3x3: some tudo que for colorido ali |
| Segunda chance | 10 gemas **ou** anúncio premiado (grátis no Encaixa+) | limpa as 4 linhas do meio; uma vez por partida |

Martelo e Bomba nunca tiram **pedras** (só quebram completando a linha ou a coluna). Usar um deles desliga o Desfazer.
Tocar de novo no botão do reforço cancela; as gemas só saem quando o alvo é válido.

## Desafio do dia
Semente = data (`aaaammdd`) num sorteador próprio (mulberry32), para todo mundo receber a mesma sequência em qualquer
versão do app. Número do desafio = dias desde 1º/11/2026. Pode repetir; vale a melhor pontuação.

## Modo Fases (`app/lib/jogo/fases.dart`)
- **300 fases em 15 mundos** (Doce, Oceano, Vulcão, Floresta, Gelo, Deserto, Galáxia, Neon, Cristal, Selva, Nuvens,
  Piratas, Robôs, Dragões, Arco-íris), iguais para todos. Da 141 em diante é o "modo mestre": alvos maiores, até 18
  blocos soltos e folga de peças caindo até 8%.
- Objetivos: **limpar N linhas**, **fazer N pontos**, **quebrar as pedras**, **linhas de uma cor só** (fase com 3 cores)
  e **combo xN**. As 10 primeiras ensinam um objetivo por vez; a última de cada mundo é um "chefe" de pedras.
- A dificuldade sobe sozinha: alvos maiores, mais pedras, **blocos soltos** no tabuleiro a partir do 2º mundo e menos
  folga de peças.
- **Calibrada por um robô** (`app/lib/jogo/robo.dart`): o jogo deixa o robô jogar a fase e define o limite de peças pelo
  que ele precisou, mais uma folga que cai de 80% (fase 1) para 12% (fase 140), mínimo de 10 peças. Se o robô não
  vence, troca a variação ou alivia o alvo. Assim **toda fase tem solução**.
- Estrelas: 3 sobrando ≥ 30% das peças, 2 com ≥ 15%, senão 1. Quem usou ajuda leva 1 estrela.
- Ajuda (uma por tentativa): **+5 peças** ou **abrir espaço**, por anúncio premiado ou 10 gemas (grátis no Encaixa+).
  "Abrir espaço" limpa só os blocos coloridos das 4 linhas do meio: **as pedras ficam** (senão a ajuda venceria a fase).
- Gemas: +2 na primeira vez que passa a fase e +15 ao fechar um mundo.

## Roleta da partida (`app/lib/jogo/roleta.dart`)
- Abre no fim de cada partida (Infinito, Desafio, Arena) e de cada fase vencida.
- Prêmios bons e ruins: Nada (2 fatias), +1, +2, +3, +5, +10 e +25 (raro).
- 1 giro grátis; mais 2 giros vendo anúncio premiado (grátis no Encaixa+).

## Arena da semana (`app/lib/jogo/arena.dart`)
- Torneio de segunda a domingo com as mesmas peças para todos (semente da semana). Vale a melhor partida.
- Troféus por pontos: Bronze 500 (+10 gemas), Prata 1.500 (+25), Ouro 3.000 (+50), Diamante 6.000 (+100).
- Prêmios pegos na tela da Arena, uma vez por semana. Ranking mundial por posição: issue do Play Games.

## Missões do dia e sequência (`app/lib/jogo/missoes.dart`)
- 5 missões por dia, de tipos diferentes, sorteadas pela data (iguais para todos): limpar linhas, linhas de uma cor,
  combo, pontos numa partida, partidas, tabuleiro vazio, Desafio do dia, vencer fases, 3 estrelas, jogar a Arena,
  colocar peças e limpar 2 linhas de uma vez. Cada uma vale de 3 a 6 gemas.
- Pegando as 5, o **baú** dá +15 gemas. Tudo zera à meia-noite.
- **Roda da sorte** (`app/lib/jogo/roda.dart`): 1 giro grátis por dia e mais 2 vendo anúncio (grátis no Encaixa+);
  prêmios de 5 a 50 gemas (50 é raro).
- **Sequência 🔥:** dias seguidos jogando o Desafio do dia. Prêmio extra no 3º (+5), 7º (+15), 14º (+30) e 30º (+60) dia.

## Ideias para depois (não fazer antes de medir)
Veja as issues com a etiqueta `ideia`. Prioridade é o que os números (retenção D1/D7, tempo de sessão) pedirem.

## Lembrete do Desafio (19h)
Desligado por padrão. Em **Como jogar** há o interruptor "Lembrete do Desafio": ao ligar, o app pede a permissão de
notificação (Android 13+) e agenda **uma** notificação local para as 19h (horário do celular). Ela é reagendada a cada
abertura do jogo e ao concluir o Desafio: se hoje já foi jogado ou já passou das 19h, vai para amanhã. Alarme inexato
(pode variar alguns minutos), sem servidor. **Ainda não testado em celular real** (issue #14).

## Sequência do Desafio (marcos)
Tocar na chama (canto da tela inicial) abre os marcos: 3 dias (+5 gemas), 7 (+15), 14 (+30) e 30 (+60 e o tema **Chama**,
que fica para sempre na Loja). O marco aparece no resultado do Desafio. Pulou um dia: dá para recuperar a sequência uma
vez por semana (anúncio ou gemas).

## Álbum de figurinhas
Uma figurinha nova ao **concluir o Desafio do dia** (uma por dia) e outra ao **abrir o baú das missões**. Nunca repete:
sai sempre uma que faltava, do primeiro álbum incompleto. Álbuns de 12 figurinhas: **Tesouros** e **Natureza** (este só
aparece com o primeiro completo). Completar um álbum paga **+100 gemas**. As figurinhas vão no código de progresso e na
cópia automática. Regras em `app/lib/jogo/album.dart`; tela em `app/lib/telas/album_tela.dart`.

## Desafio de amigo
Ao terminar uma partida, **Desafiar amigos** compartilha a mensagem com um código (`ENCAIXA-AMIGO-<semente>-<pontos>-<f|i>`).
O amigo toca em **Código de amigo** na tela inicial, cola a mensagem inteira e joga **com as mesmas peças**, com a sua
pontuação no topo (`AMIGO: 3000`). Vencer paga **+10 gemas**, uma vez por desafio (empate não vale). No Infinito (`i`) as
peças crescem com o nível, como no jogo original. Sem servidor: o código carrega tudo. Regras em `app/lib/jogo/amigo.dart`.

## Conquistas
26 conquistas (partidas, linhas de uma vez, combo, pontos, fases, estrelas, Desafios, sequência, figurinhas, amigos).
Cada uma paga gemas (5 a 150) e o jogador **toca para pegar** na tela Conquistas; o cartão da tela inicial mostra um selo
com quantas estão prontas. Regras em `app/lib/jogo/conquistas.dart`.

## Símbolos para daltônicos
Em **Como jogar**, o interruptor "Símbolos nas peças" desenha um símbolo em cada cor (círculo, triângulo, losango, estrela,
cruz e quadrado) nas peças da mão, no tabuleiro e na prévia. Desligado por padrão e vai no código de progresso.

## Modo Relâmpago (60 segundos)
Na tela inicial, **Relâmpago**: 60 segundos para fazer o máximo de pontos. O tempo só começa na primeira jogada; se o
tabuleiro encher antes, a partida acaba (sem segunda chance). No fim: **1 gema a cada 150 pontos (até 15)**. O recorde do
Relâmpago é separado do recorde geral. Peças sorteadas a cada partida, sem metas do Infinito.

## Passe de temporada (mensal)
20 níveis por mês, 100 XP cada. XP: Desafio +40, baú das missões +30, fase vencida +10 (+3 por estrela), vitória sobre
amigo +15, partida +5 (só as 10 primeiras do dia). Cada nível dá gemas (10; nos níveis 5, 10, 15 e 20, 30), **o dobro com
o Encaixa+**, e o nível 20 libera o tema **Aurora** para sempre. A trilha recomeça no mês seguinte. Regras em
`app/lib/jogo/passe.dart`.

## Blocos especiais (só no Infinito)
Depois da primeira meta (nível 1), cerca de 19% das peças trazem **um** bloco especial:
**bomba** (bola escura, 5%): quando a linha dela some, limpa também a área 3x3 em volta (pedras ficam) e dá +15 pontos;
**joia** (losango brilhante, 4%): quando a linha dela some, dá **+1 gema** e +30 pontos;
**gelo** (bloco esbranquiçado, 3%): precisa de **duas** linhas: a primeira só racha (ele fica, com rachaduras), a segunda tira
e dá +1 gema e +20 pontos; **curinga** (anel colorido, 3%): vale por qualquer cor na linha de uma cor só; **raio** (relâmpago amarelo, 4%): quando a linha
dele some, limpa também a outra linha ou coluna inteira que passa por ele (pedras ficam) e dá +15 pontos. No nível 0, e em todos os
outros modos (fases, Desafio, Arena, Relâmpago), o sorteio não gasta nenhum número a mais: as peças continuam exatamente
as mesmas. Regras em `app/lib/jogo/partida.dart` e `peca.dart`; testes em `test/especiais_test.dart`.

## Quadrinho, o mascote
Um bloco simpático desenhado em código (`app/lib/widgets/mascote.dart`, sem imagens) aparece no fim da partida e reage:
festa no novo recorde, feliz na partida normal e tristinho se foi bem abaixo do recorde, com uma frase de incentivo.

## Faixas do Desafio e presente da noite
**Faixas** pela melhor pontuação do Desafio no dia: Bronze (1.500) +3 gemas, Prata (4.000) +8, Ouro (8.000) +15. Não
soma entre faixas: ao subir de faixa no mesmo dia paga só a diferença. **Presente da noite**: depois das 19h aparece na
tela inicial um segundo presente (+10 gemas e 20 XP do Passe) uma vez por dia; o lembrete das 19h cita ele.

## Mascote na partida e ranking mundial
**Quadrinho** fica ao lado do tabuleiro (só em telas altas, sem encolher o tabuleiro) e fala: comemora elogios (festa) e
os fortes (Incrível, Fantástico: cara de "uau"), avisa quando o tabuleiro está quase cheio e dá uma **dica a cada 5
jogadas sem limpar linha**. A arte (feliz, festa, uau, triste) está em `docs/artes/mascote-*.png`, gerada em código.
**Ranking mundial:** o código já manda a pontuação do Infinito, Desafio e Arena ao placar do Google Play Games, mas o
botão só aparece quando o ID do placar estiver em `game_services.xml` (passo a passo em `docs/PLAY_GAMES.md`, issue #17).

## Baús e coleção (só aparência)
Os baús **se ganham jogando**; não há compra com dinheiro. Dão baú: concluir o **Desafio do dia** (1), os níveis **5, 10,
15 e 20 do Passe**, **completar um álbum** e os marcos de **14 e 30 dias** de sequência (mais 1 cada). Cada baú traz um
item de **aparência**: tema de blocos, moldura do tabuleiro ou cor do Quadrinho. **Nada muda a pontuação** e vale em
todos os modos, então Desafio, Arena e ranking continuam justos.

**Chances (sempre na tela do baú):** Comum 60%, Raro 28%, Épico 10%, Lendário 2%. **Garantia:** a cada 10 baús sai pelo
menos um Raro (ou melhor) e a cada 60 um Lendário. **Repetido:** sobe de nível (até 5 estrelas) e, no máximo, vira gemas
(5, 15, 40 ou 100 conforme a raridade). 18 itens: 6 temas, 6 molduras e 6 cores do mascote; "Padrão" volta ao visual
original. Regras em `app/lib/jogo/bau.dart`; tela em `app/lib/telas/baus_tela.dart`.

**Baú de anúncio:** até **3 por dia**, o jogador escolhe ver um anúncio com recompensa e abre na hora um baú **só de itens
Comuns** (quem tem o Encaixa+ abre sem ver o anúncio). Ele não gasta baú guardado e **não conta na garantia**. Comum repetido
no nível máximo vira 5 gemas.

**Fora de propósito:** venda de baús por dinheiro, habilidades que mudam o jogo e itens "únicos no mundo". Motivos e
decisões em aberto: issue "Baús com itens raros" (loot box tem regra legal e a Play exige mostrar as chances).

## Sensação de jogo (confete, tremor e música)
Ao limpar linhas, pedacinhos de cada bloco voam e caem (confete); nas jogadas muito fortes (Incrível, Fantástico, combo x4)
o tabuleiro treme de leve. Quem pediu **menos animação** no Android não vê nenhum dos dois. A **música de fundo**
(`app/assets/sons/musica.wav`, gerada por `ferramentas/gerar_sons.py`, 24 s em loop) **começa desligada** (muita gente joga
ouvindo a própria música): liga em *Como jogar > Música de fundo*, só toca com o som ligado e para quando o jogo sai da tela.

## Puzzle do dia

- Todo dia um tabuleiro novo, igual para todos, com **3 peças fixas** (não vêm outras). Vale limpar o máximo de linhas.
- A meta (3 a 5 linhas) vem de uma solução plantada ao gerar o puzzle; a jogada gulosa óbvia quase nunca basta.
- Estrelas: 3 = bateu a meta; 2 = meta menos 1 (mínimo 2 linhas); 1 = ao menos 1 linha. Gemas acumuladas 2/5/10.
- Só a **melhor marca do dia** paga gemas (paga a diferença); +15 XP do Passe na primeira pontuação do dia.
- Pode tentar de novo à vontade. Não conta como partida do Infinito, não mexe em recorde nem missões.
- Código: `app/lib/jogo/puzzle.dart`, testes em `app/test/puzzle_test.dart`, capturas `docs/telas/46-puzzle*.png`.

## Modo Zen

- Partida sem fim e sem pressa: quando nada mais cabe, o jogo tira as 2 linhas e 2 colunas mais cheias (mais, se a peça for grande) e segue.
- Não vale recorde, gemas, missões nem conquistas. A partida fica guardada ("zen"); se voltar travada, abre espaço sozinha.
- Código: `Partida.abrirEspaco`, `JogoTela(zen: true)`; testes em `app/test/zen_test.dart`.

## Fundos do jogo (baús)

- Nova categoria da coleção, 6 fundos em todas as raridades (cores: topo, base e 2 brilhos). Só aparência.
- `Cores.fundoDoBau` é lido por `FundoJogo` (todas as telas). Testes em `app/test/fundos_test.dart`.
