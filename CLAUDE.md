# Encaixa — instruções para agentes

## Projeto
- Jogo Android em Flutter: `app/`. Regras em `app/lib/jogo/` (Dart puro, sem Flutter), serviços (progresso, AdMob,
  Play Billing) em `app/lib/servicos/`, telas em `app/lib/telas/`. Leia `docs/JOGO.md` e `docs/MONETIZACAO.md`.
- Textos, commits, issues e PRs em português. Simples antes de genérico: sem gerenciador de estado, sem injeção de
  dependência, sem camadas extras. Serviços vão pelo construtor (`Servicos`).
- Nunca grave chaves, senhas ou IDs reais do AdMob no repositório: ficam nos segredos do GitHub (`docs/PUBLICAR.md`).

## Antes de enviar
- `cd app && dart format -l 120 lib test && flutter analyze && flutter test` (o CI faz o mesmo).
- Mudou regra de pontuação? Atualize o teste em `test/partida_test.dart` e a tabela em `docs/JOGO.md`.
- **Mudou tela? Regere e olhe as imagens** antes de dizer que está pronto: `flutter test --dart-define=CAPTURAS=true`
  (veja `docs/TELAS.md`). Teste passando não prova que ficou bonito.

## Pendências viram issue
Tudo que ficar para depois, faltar o usuário fazer (Play Console, AdMob, segredos) ou não der para testar aqui (aparelho
real) vira issue no GitHub. Procure uma aberta antes de criar outra.
