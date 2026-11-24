# Monetização

Modelo **híbrido**, como os jogos casuais que mais faturam: anúncios para quem não paga, e três jeitos de pagar.
Regra de ouro: **o anúncio nunca interrompe uma partida** e o premiado é sempre escolha do jogador.

## Anúncios (AdMob) — `app/lib/servicos/anuncios.dart`
| Formato | Onde | Regra |
|---|---|---|
| Premiado | Segunda chance; "+5 gemas grátis" na loja; Roda da sorte (giros 2 e 3); roleta do fim de partida (giros extras) | Só quando o jogador toca. Continua disponível para quem pagou |
| Intersticial | Ao sair do resultado ("Jogar de novo"/"Início") | Nunca nas 3 primeiras partidas; no máximo 1 a cada 3 partidas **e** 3 minutos (`PoliticaIntersticial`, testada) |
| Banner | — | Não usamos: paga pouco e deixa a tela feia |

O consentimento (GDPR/UMP) é pedido pelo SDK do Google só onde a lei exige.
IDs reais entram por segredo no CI; sem eles o app usa os **IDs de teste do Google** (nunca clique nos seus anúncios reais).

## Compras no app (Google Play Billing) — `app/lib/servicos/compras.dart`
| ID no Play Console | Tipo | Preço sugerido | O que dá |
|---|---|---|---|
| `sem_anuncios` | Produto único | R$ 14,99 | Remove intersticiais para sempre |
| `gemas_100` | Produto único (consumível) | R$ 4,89 | 100 gemas |
| `gemas_300` | Produto único (consumível) | R$ 12,99 | 300 gemas ("Mais popular") |
| `gemas_1000` | Produto único (consumível) | R$ 34,99 | 1000 gemas ("Melhor valor") |
| `encaixa_mais` (plano `mensal`) | **Assinatura** mensal | R$ 9,99/mês (sem teste grátis por enquanto) | Sem intersticiais + segunda chance grátis + 10 gemas/dia |

Os preços são ponto de partida; o Play converte para outras moedas. Teste A/B depois de ter tráfego.

### Economia de gemas
- Começa com 15 gemas (dá para provar Desfazer e Trocar).
- Ganha: linha de uma cor (+1), tabuleiro limpo (+3), Desafio do dia (+5/dia), anúncio premiado (+5), assinatura (+10/dia).
- Ganha também: fases (+2 na primeira vez, +15 por mundo), missões do dia (3 a 5 cada + baú de 10),
  sequência de dias (+5/+15/+30/+60 nos dias 3/7/14/30).
- Fim de semana (sex. 18h a dom.) e eventos: gemas das linhas de uma cor e do tabuleiro limpo em dobro.
- Gasta: Desfazer 3, Trocar 5, Segunda chance / ajuda nas fases 10, **temas de blocos** 150 a 300.

### Temas e eventos (`app/lib/jogo/temas.dart`, `app/lib/jogo/eventos.dart`)
| Tema | Como conseguir |
|---|---|
| Clássico | grátis |
| Doce, Oceano, Neon | 150, 200, 300 gemas |
| Galáxia | exclusivo Encaixa+ |
| Natal | grátis durante o evento de Natal (18 a 26/12); quem pega fica com ele |

Eventos ficam numa lista no app (Natal 2026, Carnaval 2027). Para lançar evento sem atualizar o app, falta o
Firebase Remote Config (#6, #15).

### Limites conhecidos (viraram issues)
- Compras validadas só no aparelho. Falta verificação no servidor e aviso de cancelamento em tempo real (RTDN).
- O progresso fica só no aparelho (troca de celular perde gemas). As compras não consumíveis e a assinatura voltam por
  "Restaurar compras"; as gemas não.

## Métricas para acompanhar
Retenção D1/D7/D30, partidas por dia, % que vê premiado, ARPDAU, conversão para Encaixa+. Precisa de
Firebase Analytics (issue aberta).

### Estado no Play Console (24\/11\/2026)
Os 4 produtos únicos e a assinatura foram **criados e ativados** no Play Console, com preço em reais e conversão automática
para os outros países. O Play só aceita certos pontos de preço, então R$ 4,90 / 12,90 / 34,90 / 14,90 / 9,90 viraram os
valores da tabela acima (R$ 4,89 / 12,99 / 34,99 / 14,99 / 9,99). O app mostra o preço que o Play devolve.
Falta: oferta de teste grátis da assinatura e o produto `gemas_evento` (#21).
**Baús vendidos por dinheiro continuam fora**: risco legal (ECA Digital) e dependem da verificação no servidor (#5, #23).
