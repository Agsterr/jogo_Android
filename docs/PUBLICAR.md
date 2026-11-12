# Publicar na Play Store

## 1. Conta e app
1. Play Console (taxa única de US$ 25) → **Criar app** → nome "Encaixa", jogo, gratuito.
2. Pacote: `com.agsterr.encaixa2` (definido em `app/android/app/build.gradle.kts`).
3. Ficha da loja: ícone `docs/artes/icone-512.png`, destaque `docs/artes/destaque-1024x500.png` e as
   **7 imagens de telefone** em `docs/play-store/` (1080×1920, na ordem 1 a 7). Para refazê-las:
   `cd app && flutter test test/play_store_test.dart --dart-define=CAPTURAS=true`.
4. Política de privacidade (obrigatória com anúncios): publicar uma página e colocar o link (issue aberta).
5. Classificação de conteúdo, público-alvo (**não** marque crianças: anúncios personalizados) e "Segurança dos dados"
   (AdMob coleta ID de publicidade).

## 2. Chave de assinatura
```bash
keytool -genkey -v -keystore encaixa.jks -keyalg RSA -keysize 2048 -validity 10000 -alias encaixa
base64 -w0 encaixa.jks   # vai para o segredo ANDROID_KEYSTORE_BASE64
```
Guarde o `.jks` e as senhas fora do repositório. Ative o **Play App Signing**.

## 3. AdMob
Crie o app no AdMob e dois blocos: **premiado** e **intersticial**. Ligue o AdMob ao app no Play Console.

## 4. Segredos do GitHub (Settings → Secrets → Actions)
| Segredo | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | saída do `base64` acima |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` | senhas da chave |
| `ANDROID_KEY_ALIAS` | `encaixa` |
| `ADMOB_APP_ID` | `ca-app-pub-…~…` |
| `ADMOB_PREMIADO`, `ADMOB_INTERSTICIAL` | `ca-app-pub-…/…` |

Sem eles o CI ainda gera o APK, assinado com chave de debug e anúncios de teste (serve para testar no celular).

## 5. Produtos
Monetize → Produtos: crie `sem_anuncios`, `gemas_100`, `gemas_300`, `gemas_1000` e a assinatura `encaixa_mais`
(veja [MONETIZACAO.md](MONETIZACAO.md)). Compras só funcionam em app instalado pela Play (teste interno) e com
"testadores de licença" cadastrados.

## 6. Enviar
Cada push roda o workflow **CI**: formata, analisa, testa e gera `app-release.aab` (artefato `encaixa-android`).
Envie o `.aab` para **Teste interno** → **Teste fechado** (12 testadores por 14 dias é exigência para contas pessoais
novas) → **Produção**. Antes de cada versão, suba `version:` no `app/pubspec.yaml`.
