# Monetização

Modelo **híbrido**, como os jogos casuais que mais faturam: anúncios para quem não paga, e três jeitos de pagar.
Regra de ouro: **o anúncio nunca interrompe uma partida** e o premiado é sempre escolha do jogador.

## Anúncios (AdMob) — `app/lib/servicos/anuncios.dart`
| Formato | Onde | Regra |
|---|---|---|
| Premiado | Segunda chance; "+5 gemas grátis" na loja | Só quando o jogador toca. Continua disponível para quem pagou |
| Intersticial | Ao sair do resultado ("Jogar de novo"/"Início") | Nunca nas 3 primeiras partidas; no máximo 1 a cada 3 partidas **e** 3 minutos (`PoliticaIntersticial`, testada) |
| Banner | — | Não usamos: paga pouco e deixa a tela feia |

O consentimento (GDPR/UMP) é pedido pelo SDK do Google só onde a lei exige.
IDs reais entram por segredo no CI; sem eles o app usa os **IDs de teste do Google** (nunca clique nos seus anúncios reais).

## Compras no app (Google Play Billing) — `app/lib/servicos/compras.dart`
| ID no Play Console | Tipo | Preço sugerido | O que dá |
|---|---|---|---|
| `sem_anuncios` | Produto não consumível | R$ 14,90 | Remove intersticiais para sempre |
| `gemas_100` | Consumível | R$ 4,90 | 100 gemas |
| `gemas_300` | Consumível | R$ 12,90 | 300 gemas ("Mais popular") |
| `gemas_1000` | Consumível | R$ 34,90 | 1000 gemas ("Melhor valor") |
| `encaixa_mais` | **Assinatura** mensal | R$ 9,90/mês (teste grátis de 3 dias sugerido) | Sem intersticiais + segunda chance grátis + 10 gemas/dia |

Os preços são ponto de partida; o Play converte para outras moedas. Teste A/B depois de ter tráfego.

### Economia de gemas
- Começa com 15 gemas (dá para provar Desfazer e Trocar).
- Ganha: linha de uma cor (+1), tabuleiro limpo (+3), Desafio do dia (+5/dia), anúncio premiado (+5), assinatura (+10/dia).
- Gasta: Desfazer 3, Trocar 5, Segunda chance 10.

### Limites conhecidos (viraram issues)
- Compras validadas só no aparelho. Falta verificação no servidor e aviso de cancelamento em tempo real (RTDN).
- O progresso fica só no aparelho (troca de celular perde gemas). As compras não consumíveis e a assinatura voltam por
  "Restaurar compras"; as gemas não.

## Métricas para acompanhar
Retenção D1/D7/D30, partidas por dia, % que vê premiado, ARPDAU, conversão para Encaixa+. Precisa de
Firebase Analytics (issue aberta).
