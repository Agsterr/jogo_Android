# Idiomas do jogo

O Encaixa fala **português, inglês e espanhol**. Sem escolha do jogador, ele segue o idioma do celular; se o idioma do
celular não for suportado, usa **inglês**. Em *Como jogar* o jogador pode escolher Automático, Português, English ou
Español (a escolha vale na hora, as telas se refazem).

## Como funciona
- `app/lib/idioma.dart`: `t('texto em português', [argumentos])` devolve o texto no idioma em uso. **O texto em português
  fica no próprio código e é a chave da tabela**, então o português nunca depende da tabela.
- `app/lib/idioma_textos.dart`: a tabela (`_en`, `_es`), chave = texto em português **exatamente** como no código.
- `{0}`, `{1}`... são preenchidos pelos argumentos; um `{}` sozinho vem dos modelos de missão e fase (`Limpe {} linhas`).
- Textos que vêm de dados (dicas, conquistas, álbuns, temas, missões...) ficam em português nos arquivos de `lib/jogo`
  e são traduzidos **na hora de mostrar**, com `t(...)` na tela.

## Escrevi um texto novo na tela. E agora?
1. Escreva `t('Meu texto')` (com `{0}` se tiver número), nunca o texto solto.
2. Acrescente a tradução em `_en` e `_es` em `idioma_textos.dart`.
3. Rode `flutter test`: `test/idioma_test.dart` **falha se faltar tradução** de qualquer `t('...')` do código ou de qualquer
   texto de dados, ou se os marcadores `{0}` não baterem. `test/idioma_telas_test.dart` abre as telas em inglês e espanhol
   com fonte grande e falha se algum texto estourar o layout.
4. Cuidado com `const`: um widget com `t(...)` não pode ser `const`.

## Como acrescentar um idioma (ex.: francês `fr`)
1. Em `idioma.dart`: acrescente `'fr'` em `suportados` e `'fr': 'Français'` em `nomes`.
2. Em `idioma_textos.dart`: crie `_fr` com **todas** as chaves de `_en` (copie e traduza) e inclua em `porIdioma`.
3. Em `test/idioma_test.dart` e `idioma_telas_test.dart`: inclua `fr` (os testes comparam as chaves entre idiomas).
4. Singular de "linhas/pedras/peças" nas fases: `lib/jogo/fases.dart` (`Fase.texto`) tem um `switch` por idioma.
5. Ficha da loja: texto em `docs/play-store/ficha.md`, prints com
   `flutter test test/play_store_test.dart --dart-define=CAPTURAS=true --dart-define=IDIOMA=fr` (sai em `docs/play-store/fr`),
   política de privacidade traduzida, e o idioma novo na Play Console (*Presença na loja > Traduções*).

## O que **não** é traduzido (de propósito)
- O nome **Encaixa**, o logo e a marca Encaixa+; os preços (vêm da Play Store já na moeda do jogador).
- Os menus do sistema que o Android mostra sozinho (por exemplo "Copiar/Colar" ao segurar num campo de texto) seguem o
  idioma do celular.
- As traduções para inglês e espanhol foram feitas sem revisão de falante nativo: vale pedir uma revisão.
