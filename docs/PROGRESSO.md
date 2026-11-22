# Salvar o progresso (trocar de celular, reinstalar)

O progresso (fases, estrelas, gemas, recorde, temas, sequência) fica no aparelho, em `SharedPreferences`
(`app/lib/servicos/progresso.dart`). Há três jeitos de não perdê-lo, do mais simples ao mais completo.

## 1. Cópia automática (Block Store do Google)
O jogo salva sozinho e recupera sozinho depois de reinstalar, sem o jogador fazer nada e sem Play Console.

- **Salvar:** a cada mudança no progresso, depois de 5 s sem novidade, o jogo grava o mesmo código do item 2 no
  **Block Store** do Google Play services (`app/lib/servicos/copia_automatica.dart`, código nativo em
  `app/android/.../MainActivity.kt`, biblioteca `play-services-auth-blockstore`).
- **Recuperar:** na abertura do jogo, se o aparelho ainda **não tem progresso**, ele procura a cópia, restaura e mostra
  "Progresso recuperado!". Quem já tem progresso nunca é trocado por uma cópia.
- **Nunca grava progresso vazio:** um celular recém-instalado não apaga a cópia boa antes de recuperá-la.
- A tela *Salvar progresso* mostra o estado: **ligada (nuvem)**, **ligada (neste celular)** ou **indisponível**, com a hora
  da última cópia.

**Quando funciona (segundo a documentação do Google):**
| Situação | Precisa de |
|---|---|
| Desinstalar e reinstalar no **mesmo celular** | Backup do Google ligado (Configurações > Google > Backup) |
| **Celular novo** | Android 9+, tela de bloqueio (senha/PIN/padrão), backup feito e restauração na configuração do aparelho |

Quando o aparelho não tem criptografia ponta a ponta, a cópia fica só no celular (estado "neste celular").
Cada item do Block Store aceita até 4 KB; o código das 300 fases tem menos de 1,2 KB.

**Ainda não verificado num aparelho real (issue de teste):** reinstalar e ver o progresso voltar; a restauração em
celular novo; se a cópia do APK de teste (chave de debug) volta no APK da Play Store (assinado com outra chave).
O emulador do CI só prova que o app abre e mostra no log (`EncaixaCopia`) se o Block Store respondeu.

## 2. Código de progresso (plano B, também pronto)
Tela **Salvar progresso** (`app/lib/telas/progresso_tela.dart`): tela inicial (fim da lista), Loja ou aviso que
aparece uma vez a partir da fase 5.

- **Salvar:** "Copiar código" ou "Enviar por app" gera um texto `ENCAIXA1-...` (menos de 1.200 caracteres com as 300
  fases). O jogador guarda onde quiser (WhatsApp para si mesmo, e-mail, notas).
- **Recuperar:** no celular novo, cola o código; o jogo mostra fase, estrelas, gemas e recorde e pede confirmação.
- Funciona offline, sem conta e também com o APK de teste (fora da Play Store).

**O que vai no código:** recorde, gemas, partidas, fase liberada, estrelas, sequência, presente, Arena, temas
comprados, tema escolhido, som e dicas vistas.
**O que NÃO vai:** compras (Sem anúncios, Encaixa+), que voltam por *Loja > Restaurar compras*; a partida em andamento;
missões e giros do dia.

**Segurança (`app/lib/servicos/codigo_progresso.dart`):**
- Formato: JSON → gzip → Base64 + `.` + soma de verificação (FNV-1a). Código cortado ou com uma letra trocada é recusado.
- Só chaves conhecidas, com tipo e faixa de valores certos, são aceitas (um código feito à mão não injeta `assinante`).
- O código tem a hora em que foi gerado; é recusado se for mais antigo que o último gerado ou recuperado no aparelho
  (não dá para gastar as gemas e colar o código antigo de novo no mesmo celular).
- **Limite honesto:** quem sabe mexer em Base64/gzip pode montar um código com mais gemas, e o mesmo código pode ser
  recuperado em dois celulares novos. Serve para o jogador não perder o que jogou, não para provar nada. O jeito
  à prova de trapaça é o salvamento na nuvem com conta (item 4).

## 3. Backup automático do Android
`android:allowBackup="true"` está ligado. Quando o celular tem o backup do Google ligado e o jogo é reinstalado pela
**Play Store**, o Android costuma devolver os dados sozinho. Não há garantia (depende do aparelho e da configuração) e
não vale para APK instalado à mão. Por isso o código existe.

## 4. Salvamento na nuvem com conta (precisa do usuário)
Google Play Games (Saved Games): issues #16 e #17. Depende do app criado no Play Console (#2) e do Play Games
configurado. Só vale a pena se quisermos ranking e salvar entre celulares com login; a cópia automática e o código já
cobrem reinstalar e trocar de celular.
