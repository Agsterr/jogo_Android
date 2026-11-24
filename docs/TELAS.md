# Telas e artes

Toda a arte é desenhada em código (`app/lib/tema.dart` → `pintarBloco`), com a fonte **Fredoka** (licença OFL,
`app/assets/fontes/OFL.txt`). Assim ícone, loja e jogo têm o mesmo estilo e não há imagens para manter.

## Regerar as capturas (`docs/telas/`)
```bash
cd app
flutter test --dart-define=CAPTURAS=true   # também regera docs/artes
```
Os testes de tela (`test/telas_test.dart`) rodam sempre; só salvam PNG com `CAPTURAS=true`. Incluem tela pequena
(320×600) com fonte 1,3× — se algo estourar, o teste falha.

## Regerar ícone e imagem de destaque (`docs/artes/`)
```bash
cd app
flutter test test/artes_test.dart --dart-define=CAPTURAS=true
# ícones do app (precisa do ImageMagick)
for d in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  convert ../docs/artes/icone-512.png -resize ${d#*:}x${d#*:} android/app/src/main/res/mipmap-${d%:*}/ic_launcher.png
  convert ../docs/artes/icone-adaptativo-frente.png -resize $((${d#*:} * 9 / 4))x$((${d#*:} * 9 / 4)) \
    android/app/src/main/res/mipmap-${d%:*}/ic_launcher_foreground.png
done
```
O ícone adaptativo (Android 8+) usa essa frente sobre o degradê de `res/drawable/ic_launcher_background.xml`.

## Sons (`app/assets/sons/`)
Efeitos sintetizados por `ferramentas/gerar_sons.py` (sem licença de terceiros): `python3 ferramentas/gerar_sons.py`.
Arquivos: `encaixe`, `linha`, `combo`, `incrivel`, `fantastico` e `fim`. Todo valor de `Som` precisa de um `.wav` com o mesmo
nome (um teste confere).

## Capturas novas (issue #25)
- `docs/telas/60-play-games-conectado.png` e `61-play-games-conectar.png`: tela *Salvar progresso* com e sem a conta do Play Games
  (`62-*-pequena.png`: 320x600 com fonte 1,3x). Gerar: `flutter test test/play_games_tela_test.dart --dart-define=CAPTURAS=true`.
- `63-inicio-fim.png`: a tela inicial inteira (360x1900). `1-inicio.png`, `29-aviso-salvar.png` e `idioma-*-inicio-2.png` foram
  geradas com o branch `feat/esconder-salvar-progresso` (sem o botão *Salvar progresso*); se esse branch ainda não estiver na
  `main`, regere depois do merge.
- Imagem de destaque por idioma: `docs/artes/destaque-1024x500.png` (pt), `docs/play-store/en/destaque-en-1024x500.png` e
  `docs/play-store/es/destaque-es-1024x500.png` (`test/artes_test.dart`).
