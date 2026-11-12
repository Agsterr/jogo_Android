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

## Ideias para depois (não fazer antes de medir)
Veja as issues com a etiqueta `ideia`. Prioridade é o que os números (retenção D1/D7, tempo de sessão) pedirem.
