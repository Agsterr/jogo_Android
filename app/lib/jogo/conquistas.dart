/// Números que as conquistas medem (a tela de conquistas e o `Progresso` usam o mesmo retrato).
class Estatisticas {
  const Estatisticas({
    this.partidas = 0,
    this.recorde = 0,
    this.linhasMax = 0,
    this.comboMax = 0,
    this.fasesConcluidas = 0,
    this.estrelas = 0,
    this.sequenciaMax = 0,
    this.desafios = 0,
    this.figurinhas = 0,
    this.amigosVencidos = 0,
    this.relampago = 0,
  });

  final int partidas, recorde, linhasMax, comboMax, fasesConcluidas, estrelas, sequenciaMax, desafios, figurinhas;
  final int amigosVencidos, relampago;
}

enum Medida { partidas, recorde, linhas, combo, fases, estrelas, sequencia, desafios, figurinhas, amigos, relampago }

class Conquista {
  const Conquista(this.id, this.nome, this.descricao, this.medida, this.meta, this.gemas);

  final String id;
  final String nome;
  final String descricao;
  final Medida medida;
  final int meta;
  final int gemas;

  int valor(Estatisticas e) => switch (medida) {
    Medida.partidas => e.partidas,
    Medida.recorde => e.recorde,
    Medida.linhas => e.linhasMax,
    Medida.combo => e.comboMax,
    Medida.fases => e.fasesConcluidas,
    Medida.estrelas => e.estrelas,
    Medida.sequencia => e.sequenciaMax,
    Medida.desafios => e.desafios,
    Medida.figurinhas => e.figurinhas,
    Medida.amigos => e.amigosVencidos,
    Medida.relampago => e.relampago,
  };

  bool feita(Estatisticas e) => valor(e) >= meta;

  static const todas = [
    Conquista('partida-1', 'Primeiro passo', 'Jogue uma partida', Medida.partidas, 1, 5),
    Conquista('partida-50', 'Viciado', 'Jogue 50 partidas', Medida.partidas, 50, 20),
    Conquista('partida-200', 'Maratonista', 'Jogue 200 partidas', Medida.partidas, 200, 50),
    Conquista('linhas-2', 'Dupla', 'Limpe 2 linhas de uma vez', Medida.linhas, 2, 5),
    Conquista('linhas-3', 'Tripla', 'Limpe 3 linhas de uma vez', Medida.linhas, 3, 10),
    Conquista('linhas-4', 'Quádrupla', 'Limpe 4 linhas de uma vez', Medida.linhas, 4, 20),
    Conquista('combo-3', 'Embalado', 'Faça um combo x3', Medida.combo, 3, 10),
    Conquista('combo-5', 'Imparável', 'Faça um combo x5', Medida.combo, 5, 25),
    Conquista('pontos-1000', 'Mil pontos', 'Chegue a 1.000 pontos numa partida', Medida.recorde, 1000, 10),
    Conquista('pontos-5000', 'Cinco mil', 'Chegue a 5.000 pontos numa partida', Medida.recorde, 5000, 25),
    Conquista('pontos-10000', 'Dez mil', 'Chegue a 10.000 pontos numa partida', Medida.recorde, 10000, 50),
    Conquista('fase-10', 'Caminhante', 'Conclua 10 fases', Medida.fases, 10, 15),
    Conquista('fase-50', 'Explorador', 'Conclua 50 fases', Medida.fases, 50, 40),
    Conquista('fase-100', 'Veterano', 'Conclua 100 fases', Medida.fases, 100, 80),
    Conquista('fase-200', 'Lenda das fases', 'Conclua 200 fases', Medida.fases, 200, 150),
    Conquista('estrelas-50', 'Estrelado', 'Ganhe 50 estrelas nas fases', Medida.estrelas, 50, 20),
    Conquista('estrelas-150', 'Constelação', 'Ganhe 150 estrelas nas fases', Medida.estrelas, 150, 60),
    Conquista('desafio-1', 'Desafiante', 'Conclua um Desafio do dia', Medida.desafios, 1, 5),
    Conquista('desafio-10', 'Dedicado', 'Conclua 10 Desafios do dia', Medida.desafios, 10, 30),
    Conquista('seq-3', 'Pegando fogo', '3 dias seguidos no Desafio', Medida.sequencia, 3, 10),
    Conquista('seq-7', 'Uma semana', '7 dias seguidos no Desafio', Medida.sequencia, 7, 25),
    Conquista('seq-30', 'Um mês', '30 dias seguidos no Desafio', Medida.sequencia, 30, 100),
    Conquista('fig-12', 'Colecionador', 'Complete um álbum de figurinhas', Medida.figurinhas, 12, 30),
    Conquista('fig-24', 'Álbuns cheios', 'Complete os dois álbuns', Medida.figurinhas, 24, 80),
    Conquista('relampago-1000', 'Relâmpago', 'Faça 1.000 pontos em 60 segundos', Medida.relampago, 1000, 20),
    Conquista('relampago-2500', 'Raio', 'Faça 2.500 pontos em 60 segundos', Medida.relampago, 2500, 60),
    Conquista('amigo-1', 'Rival', 'Vença o desafio de um amigo', Medida.amigos, 1, 15),
    Conquista('amigo-5', 'Imbatível', 'Vença 5 desafios de amigos', Medida.amigos, 5, 50),
  ];
}
