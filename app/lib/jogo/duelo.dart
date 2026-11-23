/// Dois jogadores no mesmo celular: cada um joga uma partida, uma depois da outra, com as MESMAS peças
/// (mesma semente). Vence quem fizer mais pontos. Só diversão: não vale recorde, gemas, missões nem ranking.
class Duelo {
  const Duelo({required this.semente, this.jogador = 1, this.pontosJ1 = 0});

  /// Semente das peças, igual para os dois jogadores.
  final int semente;

  /// De quem é a vez (1 ou 2).
  final int jogador;

  /// Pontos do jogador 1 (só vale quando [jogador] é 2).
  final int pontosJ1;

  /// Duelo novo com peças sorteadas agora.
  factory Duelo.novo([DateTime? agora]) =>
      Duelo(semente: (agora ?? DateTime.now()).microsecondsSinceEpoch % 2000000000 + 1);

  /// A vez do jogador 2, depois de o 1 fazer [pontos].
  Duelo vezDoJogador2(int pontos) => Duelo(semente: semente, jogador: 2, pontosJ1: pontos);

  /// 1 ou 2 vence; 0 é empate. Compara os pontos do jogador 1 com os do 2.
  static int vencedor(int pontosJ1, int pontosJ2) => pontosJ1 == pontosJ2 ? 0 : (pontosJ1 > pontosJ2 ? 1 : 2);
}
