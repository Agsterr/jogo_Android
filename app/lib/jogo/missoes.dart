import 'partida.dart';
import 'sorteio.dart';

/// O que a missão conta. `maximo` guarda o melhor valor do dia; os outros somam.
enum TipoMissao {
  linhas('Limpe {} linhas'),
  umaCor('Limpe {} linhas de uma cor só'),
  combo('Faça um combo x{}', maximo: true),
  pontos('Faça {} pontos numa partida', maximo: true),
  partidas('Jogue {} partidas'),
  limpo('Deixe o tabuleiro vazio'),
  desafio('Jogue o Desafio do dia');

  const TipoMissao(this.modelo, {this.maximo = false});

  final String modelo;
  final bool maximo;
}

class Missao {
  const Missao(this.tipo, this.alvo, this.gemas);

  final TipoMissao tipo;
  final int alvo;
  final int gemas;

  String get texto => tipo.modelo.replaceAll('{}', '$alvo');
}

/// Gemas do baú ao concluir as 3 missões do dia.
const gemasDoBau = 10;

const _opcoes = [
  Missao(TipoMissao.linhas, 15, 3),
  Missao(TipoMissao.linhas, 30, 5),
  Missao(TipoMissao.umaCor, 2, 4),
  Missao(TipoMissao.combo, 4, 4),
  Missao(TipoMissao.pontos, 1500, 3),
  Missao(TipoMissao.pontos, 3000, 5),
  Missao(TipoMissao.partidas, 3, 3),
  Missao(TipoMissao.limpo, 1, 5),
  Missao(TipoMissao.desafio, 1, 3),
];

/// Três missões de tipos diferentes, iguais para todo mundo no mesmo dia.
List<Missao> missoesDoDia(int dia) {
  final sorteio = Sorteio(dia * 31 + 7);
  final escolhidas = <Missao>[];
  while (escolhidas.length < 3) {
    final m = _opcoes[sorteio.proximo(_opcoes.length)];
    if (escolhidas.every((e) => e.tipo != m.tipo)) escolhidas.add(m);
  }
  return escolhidas;
}

/// Quanto cada jogada conta para cada tipo de missão.
Map<TipoMissao, int> contagemDaJogada(Jogada j) => {
  TipoMissao.linhas: j.linhasLimpas,
  TipoMissao.umaCor: j.linhasDeUmaCor,
  TipoMissao.combo: j.combo,
  TipoMissao.limpo: j.tabuleiroLimpo ? 1 : 0,
};

/// Prêmio da sequência de dias jogando o Desafio do dia.
int premioDaSequencia(int dias) => switch (dias) {
  3 => 5,
  7 => 15,
  14 => 30,
  30 => 60,
  _ => 0,
};

/// Dia anterior no formato aaaammdd.
int diaAnterior(int dia) {
  final d = DateTime.utc(dia ~/ 10000, dia ~/ 100 % 100, dia % 100).subtract(const Duration(days: 1));
  return Sorteio.sementeDoDia(d);
}
