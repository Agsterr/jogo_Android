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

## Reforços (gastam gemas)
| Reforço | Custo | Efeito |
|---|---|---|
| Desfazer | 3 | volta a última jogada (um nível) |
| Trocar | 5 | sorteia uma mão nova |
| Segunda chance | 10 gemas **ou** anúncio premiado (grátis no Encaixa+) | limpa as 4 linhas do meio; uma vez por partida |

## Desafio do dia
Semente = data (`aaaammdd`) num sorteador próprio (mulberry32), para todo mundo receber a mesma sequência em qualquer
versão do app. Número do desafio = dias desde 1º/11/2026. Pode repetir; vale a melhor pontuação.

## Modo Fases (`app/lib/jogo/fases.dart`)
- **140 fases em 7 mundos** (Doce, Oceano, Vulcão, Floresta, Gelo, Deserto, Galáxia), iguais para todos.
- Objetivos: **limpar N linhas**, **fazer N pontos**, **quebrar as pedras**, **linhas de uma cor só** (fase com 3 cores)
  e **combo xN**. As 10 primeiras ensinam um objetivo por vez; a última de cada mundo é um "chefe" de pedras.
- A dificuldade sobe sozinha: alvos maiores, mais pedras, **blocos soltos** no tabuleiro a partir do 2º mundo e menos
  folga de peças.
- **Calibrada por um robô** (`app/lib/jogo/robo.dart`): o jogo deixa o robô jogar a fase e define o limite de peças pelo
  que ele precisou, mais uma folga que cai de 80% (fase 1) para 12% (fase 140), mínimo de 10 peças. Se o robô não
  vence, troca a variação ou alivia o alvo. Assim **toda fase tem solução**.
- Estrelas: 3 sobrando ≥ 30% das peças, 2 com ≥ 15%, senão 1. Quem usou ajuda leva 1 estrela.
- Ajuda (uma por tentativa): **+5 peças** ou **abrir espaço**, por anúncio premiado ou 10 gemas (grátis no Encaixa+).
- Gemas: +2 na primeira vez que passa a fase e +15 ao fechar um mundo.

## Arena da semana (`app/lib/jogo/arena.dart`)
- Torneio de segunda a domingo com as mesmas peças para todos (semente da semana). Vale a melhor partida.
- Troféus por pontos: Bronze 500 (+10 gemas), Prata 1.500 (+25), Ouro 3.000 (+50), Diamante 6.000 (+100).
- Prêmios pegos na tela da Arena, uma vez por semana. Ranking mundial por posição: issue do Play Games.

## Missões do dia e sequência (`app/lib/jogo/missoes.dart`)
- 3 missões por dia, de tipos diferentes, sorteadas pela data (iguais para todos): limpar linhas, linhas de uma cor,
  combo, pontos numa partida, partidas, tabuleiro vazio, jogar o Desafio do dia. Cada uma vale de 3 a 5 gemas.
- Pegando as 3, o **baú** dá +10 gemas. Tudo zera à meia-noite.
- **Sequência 🔥:** dias seguidos jogando o Desafio do dia. Prêmio extra no 3º (+5), 7º (+15), 14º (+30) e 30º (+60) dia.

## Ideias para depois (não fazer antes de medir)
Veja as issues com a etiqueta `ideia`. Prioridade é o que os números (retenção D1/D7, tempo de sessão) pedirem.
