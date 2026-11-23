/// Passe de temporada: uma trilha de 20 níveis por mês. Jogar enche a barra (XP); cada nível dá gemas
/// (o dobro para quem tem o Encaixa+) e o nível 20 dá o tema Aurora. Recomeça todo mês.
const niveisDoPasse = 20;
const xpPorNivel = 100;

/// De onde vem o XP.
abstract final class XpDoPasse {
  static const desafio = 40;
  static const bau = 30;
  static const amigo = 15;
  static const partida = 5;

  /// Só as primeiras partidas do dia dão XP (para não ser possível "fazer fazenda").
  static const partidasPorDia = 10;

  /// Fase vencida (primeira vez ou melhor resultado): 10 mais 3 por estrela.
  static int fase(int estrelas) => 10 + 3 * estrelas;
}

int nivelDoPasse(int xp) => (xp ~/ xpPorNivel).clamp(0, niveisDoPasse);

/// Gemas do nível (1 a 20) para quem não é assinante; assinante recebe o dobro.
int gemasDoNivelDoPasse(int nivel) => nivel % 5 == 0 ? 30 : 10;

/// Total de gemas da trilha inteira, sem e com Encaixa+.
int totalDoPasse({required bool assinante}) =>
    List.generate(niveisDoPasse, (i) => gemasDoNivelDoPasse(i + 1)).fold(0, (a, b) => a + b) * (assinante ? 2 : 1);

const _meses = [
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

/// "novembro" para o mês 202611.
String nomeDoMes(int mes) => _meses[(mes % 100 - 1).clamp(0, 11)];
