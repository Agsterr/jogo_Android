# Configurar o Play Games (salvar o progresso na nuvem com a conta Google)

Issue **#19**. Isto precisa da conta de desenvolvedor do Google Play, então só o dono consegue fazer. Os nomes dos menus
abaixo são os da documentação do Google (em inglês); no Play Console em português podem aparecer traduzidos.
Fonte: <https://developer.android.com/games/pgs/console/setup>.

## Antes de começar
- [ ] Conta de desenvolvedor do Google Play (taxa única de US$ 25).
- [ ] App **Encaixa** criado no Play Console como **jogo**, pacote `com.agsterr.encaixa2` (issue #2).
  Não precisa enviar versão antes; mas o acesso dos testadores por faixa de teste só existe com o app ligado ao jogo.

## Passo a passo no Play Console
1. **Grow users > Play Games Services > Setup and management > Configuration.**
2. Escolha **"No, my game doesn't use Google APIs"**, digite o nome do jogo (**Encaixa**) e clique em **Create**.
3. **Edit Properties:** só o nome é obrigatório para testar. Descrição, ícone (`docs/artes/icone-512.png`) e imagem de
   destaque (`docs/artes/destaque-1024x500.png`) precisam estar preenchidos antes de publicar.
4. **Credentials:** configure a **tela de consentimento OAuth** (botão **Configure**). Escopos exigidos:
   `games`, `games_lite` e `drive.appdata`. O Google recomenda **publicar** a tela de consentimento já.
5. **Add credential > Android > Create OAuth client.** No Google Cloud: tipo Android, pacote `com.agsterr.encaixa2` e o
   **SHA-1** no campo "Signing certificate fingerprint". Clique em **Create**, **Done**, escolha o client e **Save Changes**.
   O Google recomenda **duas credenciais com o mesmo pacote**:
   - **Chave do app na Play Store:** copie o SHA-1 da página de assinatura do app no Play Console (Play App Signing).
   - **Chave dos APKs do GitHub** (a chave de produção dos segredos do GitHub, issue #3; com o Play App Signing ela é a
     "chave de envio"): SHA-1 `03:8F:5D:C9:C2:8F:5D:74:47:DB:47:90:65:4E:BA:26:E5:CA:FF:77` (lido na execução #36 do CI).
     É a impressão digital pública do certificado, não é segredo. Se os segredos mudarem, o valor novo aparece no resumo de
     cada execução, no passo "SHA-1 da chave de assinatura (para o Play Games)" (aba *Summary* em Actions).
   O pacote e o SHA-1 precisam ser **exatamente** os do app, senão o login falha.
6. **Ative os Jogos salvos (Saved Games).** O Google tem a página "enable features" para isso; o caminho exato do menu
   não foi confirmado: procure **Saved games** nas configurações do Play Games Services e ative.
7. **Testers:** *Grow users > Play Games Services > Setup and management > Testers > Add testers*, com o **e-mail da conta
   Google** usada na Play Store do celular de teste. Sem isso, o Play Games não funciona para a sua conta.
8. **Copie o "Project ID"** (só números, 12 ou mais) que aparece no topo da página **Configuration**, abaixo do nome do
   jogo, e mande para o agente. Não é segredo.
9. **Antes de lançar o app:** publique a configuração do Play Games (**Publish Game**) **antes** do app. Sem isso, quem não
   é testador recebe erro.

## O que o agente faz com o Project ID (código)
Passos do Android nativo, segundo a documentação do Google (a parte Flutter não está documentada lá, ver "A confirmar"):
- `res/values/strings.xml`: `<string translatable="false" name="game_services_project_id">PROJECT_ID</string>`.
- `AndroidManifest.xml`, dentro de `<application>`:
  `<meta-data android:name="com.google.android.gms.games.APP_ID" android:value="@string/game_services_project_id"/>`.
- Dependência `com.google.android.gms:play-services-games-v2` e `PlayGamesSdk.initialize(...)` na inicialização.
- **Entrada automática:** a v2 tenta autenticar sozinha ao abrir o jogo (sem botão "entrar").
- **Salvar:** o mesmo código de progresso (`CodigoProgresso`, menos de 4 KB) como jogo salvo; o limite do Google é 3 MB.
  Salvar depois de partidas e fases, com a mesma pausa de 5 s da cópia automática.
- **Ler:** ao abrir, comparar com o aparelho e **ficar com o mais avançado** (mais fases e estrelas); se houver dúvida,
  perguntar ao jogador. O Google diz que, em conflito, normalmente quem decide é o jogador.
- Tela *Salvar progresso* mostrando "Conta do Google: conectada como <nome>".
- Funciona offline: grava e lê sem internet e sincroniza depois.
- A cópia automática (Block Store) e o código de progresso continuam como planos B.

## A confirmar (não deu para ler na documentação)
- O caminho exato do menu para ativar **Saved Games** e as etapas exatas de **publicar** a configuração.
- A API de **conflito** de jogos salvos no Android.
- Qual plugin Flutter usar (por exemplo `games_services`) e se ele já usa o SDK v2. Se não usar, o código nativo é nosso.

## Como saber que deu certo
Dois celulares (ou desinstalar e instalar) com a mesma conta Google mostram o mesmo progresso, sem copiar nada.

## Estado (23/11/2026)
Feito no Play Console e no Google Cloud (projeto `encaixa-515600`, **Project ID `41851413204`**): tela OAuth, escopos,
duas credenciais Android para `com.agsterr.encaixa2` (SHA-1 da chave de envio e da chave de assinatura da Play),
Jogos salvos ativados e projeto publicado.

No código: `game_services.xml` + `meta-data` no manifesto, `play-services-games-v2`, canal `encaixa/nuvem` em
`MainActivity.kt` (Jogo salvo `progresso`) e `CopiaDupla` (Play Games + Block Store; ao ler, vale o progresso mais
avançado). **Ainda não testado em aparelho:** conferir com a mesma conta Google em dois celulares / reinstalando.
Não feito: mostrar "Conectado como <nome>" na tela Salvar progresso.

## Ranking mundial (placar)
O código já está no app (`lib/servicos/ranking.dart` e `MainActivity.kt`): ele manda a pontuação do **Infinito, do Desafio e da
Arena** ao placar e mostra o botão **Ranking mundial** na tela inicial. **Fica escondido até você configurar o placar:**
1. Play Console > Play Games Services > **Leaderboards** (Placares) > **Create leaderboard**: nome "Melhor pontuação",
   formato numérico, ordem decrescente (maior é melhor).
2. Copie o **ID do placar** (começa com `CgkI...`; não é segredo).
3. Cole em `app/android/app/src/main/res/values/game_services.xml`, em `leaderboard_id`, e envie. (Ou me passe o ID.)
4. Publique a configuração do Play Games. O Google guarda só a melhor pontuação de cada jogador.
**Não testado em aparelho.** Sem login no Play Games o botão pede a conta e tenta de novo.
