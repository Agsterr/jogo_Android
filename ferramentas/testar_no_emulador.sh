#!/usr/bin/env bash
# Instala o APK no emulador, abre o jogo e falha se ele fechar. Mostra o log de erro do Android.
# Uso (no CI, com o emulador ligado): ferramentas/testar_no_emulador.sh caminho/app-release.apk
set -u
APK="$1"
PACOTE=com.agsterr.encaixa2

adb install -r "$APK" || exit 1
adb logcat -c
adb shell monkey -p "$PACOTE" -c android.intent.category.LAUNCHER 1
sleep 25

mkdir -p emulador
adb exec-out screencap -p > emulador/tela.png
adb logcat -d > emulador/logcat.txt

echo "===== Erros do Android ====="
grep -E "FATAL EXCEPTION|AndroidRuntime|Caused by|E/flutter|libc   :|DEBUG   :" emulador/logcat.txt | head -120

if adb shell pidof "$PACOTE" > /dev/null; then
  echo "OK: o jogo continua aberto depois de 25 s."
else
  echo "FALHOU: o jogo fechou." >&2
  exit 1
fi
