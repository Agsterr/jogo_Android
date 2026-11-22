# Salvar o progresso (trocar de celular, reinstalar)

O progresso (fases, estrelas, gemas, recorde, temas, sequência) fica no aparelho, em `SharedPreferences`
(`app/lib/servicos/progresso.dart`). Há três jeitos de não perdê-lo, do mais simples ao mais completo.

## 1. Código de progresso (pronto)
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
  à prova de trapaça é o salvamento na nuvem (item 3).

## 2. Backup automático do Android
`android:allowBackup="true"` está ligado. Quando o celular tem o backup do Google ligado e o jogo é reinstalado pela
**Play Store**, o Android costuma devolver os dados sozinho. Não há garantia (depende do aparelho e da configuração) e
não vale para APK instalado à mão. Por isso o código existe.

## 3. Salvamento na nuvem (precisa do usuário)
Google Play Games (Saved Games): issues #16 e #17. Depende do app criado no Play Console (#2) e do Play Games
configurado. Quando existir, o código vira plano B.
