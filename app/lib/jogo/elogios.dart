import 'partida.dart';

/// Elogio que aparece depois de limpar linhas. Quanto mais forte a jogada, maior o texto e mais animado o som.
class Elogio {
  const Elogio(this.texto, this.nivel);

  final String texto;

  /// 1 (Boa!) a 5 (Perfeito!).
  final int nivel;
}

/// `null` se a jogada não limpou nada.
///
/// Força = linhas limpas + combo acima do primeiro. Ex.: 1 linha = Boa; 2 linhas, ou 1 linha no combo x2 = Ótimo;
/// 4 pontos de força = Incrível; 6 ou mais = Fantástico; tabuleiro vazio = Perfeito.
Elogio? elogioDaJogada(Jogada j) {
  if (j.linhasLimpas == 0) return null;
  if (j.tabuleiroLimpo) return const Elogio('Perfeito!', 5);
  final forca = j.linhasLimpas + (j.combo > 1 ? j.combo - 1 : 0);
  if (forca >= 6) return const Elogio('Fantástico!', 4);
  if (forca >= 4) return const Elogio('Incrível!', 3);
  if (forca >= 2) return const Elogio('Ótimo!', 2);
  return const Elogio('Boa!', 1);
}
