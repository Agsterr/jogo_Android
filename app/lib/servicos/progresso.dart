import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../jogo/album.dart';
import '../jogo/arena.dart';
import '../jogo/fases.dart';
import '../jogo/missoes.dart';
import '../jogo/roda.dart';
import 'codigo_progresso.dart';
import '../jogo/temas.dart';
import '../tema.dart';

/// Tudo que o jogador guarda no aparelho: recorde, gemas e o que comprou.
class Progresso extends ChangeNotifier {
  Progresso(this._prefs) {
    Cores.pecas = temaAtivo.cores;
  }

  static Future<Progresso> carregar() async => Progresso(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  /// Gemas de presente na primeira vez, para o jogador provar os reforços.
  static const int gemasIniciais = 15;

  int get recorde => _prefs.getInt('recorde') ?? 0;
  int get gemas => _prefs.getInt('gemas') ?? gemasIniciais;
  int get partidas => _prefs.getInt('partidas') ?? 0;
  bool get semAnuncios => _prefs.getBool('semAnuncios') ?? false;
  bool get assinante => _prefs.getBool('assinante') ?? false;

  /// Dicas e tutorial já vistos.
  bool dicaVista(String id) => (_prefs.getStringList('dicas') ?? const []).contains(id);

  Future<void> marcarDica(String id) async {
    if (dicaVista(id)) return;
    await _prefs.setStringList('dicas', [...?_prefs.getStringList('dicas'), id]);
  }

  /// Lembrete diário do Desafio às 19h (desligado até o jogador ligar e aceitar a permissão).
  bool get lembreteLigado => _prefs.getBool('lembrete') ?? false;

  Future<void> definirLembrete(bool ligado) async {
    await _prefs.setBool('lembrete', ligado);
    notifyListeners();
  }

  bool get somLigado => _prefs.getBool('som') ?? true;

  Future<void> alternarSom() async {
    await _prefs.setBool('som', !somLigado);
    notifyListeners();
  }

  /// Assinante também não vê anúncio entre partidas.
  bool get livreDeAnuncios => semAnuncios || assinante;

  /// Dia (aaaammdd) do último Desafio do dia concluído e a pontuação.
  int get desafioFeito => _prefs.getInt('desafioFeito') ?? 0;
  int get desafioPontos => _prefs.getInt('desafioPontos') ?? 0;

  /// Dia em que o assinante recebeu as gemas diárias.
  int get bonusAssinante => _prefs.getInt('bonusAssinante') ?? 0;

  /// Registra o fim de uma partida. Devolve `true` se bateu o recorde.
  Future<bool> fimDePartida(int pontos) async {
    await _prefs.setInt('partidas', partidas + 1);
    final novo = pontos > recorde;
    if (novo) await _prefs.setInt('recorde', pontos);
    notifyListeners();
    return novo;
  }

  /// Dias seguidos jogando o Desafio do dia (zera se pular um dia).
  int sequencia(int hoje) {
    final ultimo = desafioFeito;
    if (ultimo != hoje && ultimo != diaAnterior(hoje)) return 0;
    return _prefs.getInt('sequencia') ?? 0;
  }

  /// Sequência que acabou ontem (pulou só um dia) e ainda pode ser recuperada: 1 vez por semana.
  int sequenciaPerdida(int hoje) {
    final ontem = diaAnterior(hoje);
    if (desafioFeito != diaAnterior(ontem)) return 0;
    final ultimaVez = _prefs.getInt('sequenciaSalva') ?? 0;
    if (ultimaVez != 0 && diasEntre(ultimaVez, hoje) < 7) return 0;
    return _prefs.getInt('sequencia') ?? 0;
  }

  /// Recupera a sequência como se o desafio de ontem tivesse sido feito.
  Future<bool> recuperarSequencia(int hoje) async {
    if (sequenciaPerdida(hoje) == 0) return false;
    await _prefs.setInt('desafioFeito', diaAnterior(hoje));
    await _prefs.setInt('sequenciaSalva', hoje);
    notifyListeners();
    return true;
  }

  // ---------- presente de entrada (7 dias) ----------

  /// Dia do ciclo (1 a 7) que o jogador pega hoje, ou 0 se já pegou.
  int presenteDeHoje(int hoje) {
    final ultimo = _prefs.getInt('presenteDia') ?? 0;
    if (ultimo == hoje) return 0;
    final seguido = ultimo == diaAnterior(hoje);
    final anterior = _prefs.getInt('presenteSeq') ?? 0;
    return seguido ? anterior % 7 + 1 : 1;
  }

  /// Dia do ciclo já pego hoje (para mostrar o calendário depois de pegar).
  int presentePego(int hoje) => (_prefs.getInt('presenteDia') ?? 0) == hoje ? (_prefs.getInt('presenteSeq') ?? 0) : 0;

  Future<int> pegarPresente(int hoje) async {
    final diaDoCiclo = presenteDeHoje(hoje);
    if (diaDoCiclo == 0) return 0;
    final gemas = gemasDoPresente(diaDoCiclo) * (diaDoCiclo == 7 && assinante ? 2 : 1);
    await _prefs.setInt('presenteDia', hoje);
    await _prefs.setInt('presenteSeq', diaDoCiclo);
    await ganharGemas(gemas);
    return gemas;
  }

  /// Conclui o desafio. Devolve as gemas ganhas (desafio + prêmio da sequência).
  Future<int> concluirDesafio(int dia, int pontos) async {
    if (desafioFeito == dia && pontos <= desafioPontos) return 0;
    final primeiraVez = desafioFeito != dia;
    var gemasGanhas = 0;
    if (primeiraVez) {
      final dias = sequencia(dia) + 1;
      await _prefs.setInt('sequencia', dias);
      gemasGanhas = 5 + premioDaSequencia(dias);
      await contarMissao(dia, TipoMissao.desafio, 1);
      await ganharFigurinha(dia * 31 + 2);
      // Prêmio de 30 dias: tema exclusivo, guardado para sempre.
      for (final t in TemaDeBlocos.todos) {
        if (t.marcoDias != null && dias >= t.marcoDias!) await guardarTema(t);
      }
    }
    await _prefs.setInt('desafioFeito', dia);
    await _prefs.setInt('desafioPontos', pontos);
    await ganharGemas(gemasGanhas);
    notifyListeners();
    return gemasGanhas;
  }

  /// O progresso acabou de voltar sozinho da cópia automática (a tela inicial avisa o jogador uma vez).
  bool recuperadoAutomaticamente = false;

  /// Resumo do progresso de agora, para avisar o jogador.
  ({int fase, int estrelas, int gemas, int recorde}) get resumo =>
      (fase: faseLiberada, estrelas: estrelasTotais, gemas: gemas, recorde: recorde);

  // ---------- código de progresso ----------

  /// Gera o código com o progresso de agora ([agora] em ms) e lembra a hora: códigos mais velhos
  /// que ela são recusados depois (senão dava para gastar as gemas e colar o código antigo de novo).
  Future<String> gerarCodigo(int agora) async {
    final codigo = CodigoProgresso.gerar({for (final k in _prefs.getKeys()) k: _prefs.get(k)}, agora: agora);
    await _prefs.setInt('codigoEm', agora);
    return codigo;
  }

  /// O código só vale se for mais novo que o último gerado ou recuperado neste aparelho.
  bool codigoRecente(Map<String, Object> dados) => (dados['salvoEm']! as int) > (_prefs.getInt('codigoEm') ?? 0);

  /// Troca o progresso deste aparelho pelo do código (compras e partida em andamento ficam como estão).
  Future<void> restaurarCodigo(Map<String, Object> dados) async {
    for (final chave in _prefs.getKeys().toList()) {
      if (CodigoProgresso.vai(chave)) await _prefs.remove(chave);
    }
    for (final MapEntry(key: chave, value: valor) in dados.entries) {
      if (chave == 'salvoEm') continue;
      switch (valor) {
        case final int v:
          await _prefs.setInt(chave, v);
        case final bool v:
          await _prefs.setBool(chave, v);
        case final String v:
          await _prefs.setString(chave, v);
        case final List<String> v:
          await _prefs.setStringList(chave, v);
      }
    }
    await _prefs.setInt('codigoEm', dados['salvoEm']! as int);
    Cores.pecas = temaAtivo.cores;
    notifyListeners();
  }

  // ---------- roda da sorte ----------

  int girosNoDia(int dia) => _prefs.getInt('rodaDia') == dia ? (_prefs.getInt('rodaGiros') ?? 0) : 0;

  /// Gira a roda: devolve a fatia sorteada e já dá as gemas. `null` se acabaram os giros do dia.
  Future<int?> girarRoda(int dia) async {
    final giro = girosNoDia(dia);
    if (giro >= Roda.girosPorDia) return null;
    final fatia = Roda.sortear(dia, giro);
    await _prefs.setInt('rodaDia', dia);
    await _prefs.setInt('rodaGiros', giro + 1);
    await ganharGemas(Roda.premios[fatia]);
    return fatia;
  }

  // ---------- arena da semana ----------

  /// Melhor pontuação na Arena desta [semana] (zera quando a semana muda).
  int arenaMelhor(int semana) => _prefs.getInt('arenaSemana') == semana ? (_prefs.getInt('arenaMelhor') ?? 0) : 0;

  Future<void> registrarArena(int semana, int pontos) async {
    if (_prefs.getInt('arenaSemana') != semana) {
      await _prefs.setInt('arenaSemana', semana);
      await _prefs.setInt('arenaMelhor', 0);
      await _prefs.remove('arenaPremios');
    }
    if (pontos > arenaMelhor(semana)) await _prefs.setInt('arenaMelhor', pontos);
    notifyListeners();
  }

  bool premioArenaPego(int semana, String trofeu) =>
      _prefs.getInt('arenaSemana') == semana && (_prefs.getStringList('arenaPremios') ?? const []).contains(trofeu);

  /// Recolhe as gemas de um troféu alcançado nesta semana (uma vez).
  Future<int> pegarPremioArena(int semana, Trofeu t) async {
    if (arenaMelhor(semana) < t.pontos || premioArenaPego(semana, t.nome)) return 0;
    await _prefs.setStringList('arenaPremios', [...?_prefs.getStringList('arenaPremios'), t.nome]);
    await ganharGemas(t.gemas);
    return t.gemas;
  }

  // ---------- temas ----------

  /// Tema em uso; volta ao Clássico se o jogador perdeu o direito (ex.: assinatura acabou).
  TemaDeBlocos get temaAtivo {
    final t = TemaDeBlocos.porId(_prefs.getString('tema'));
    return temTema(t) ? t : TemaDeBlocos.classico;
  }

  /// Tem o tema? (grátis, comprado, assinante ou evento em andamento)
  bool temTema(TemaDeBlocos t, {String? eventoAtivo}) =>
      (t.preco == 0 && !t.assinante && t.evento == null && t.marcoDias == null) ||
      (_prefs.getStringList('temas') ?? []).contains(t.id) ||
      (t.assinante && assinante) ||
      (t.evento != null && t.evento == eventoAtivo);

  Future<bool> comprarTema(TemaDeBlocos t) async {
    if (t.preco == 0 || temTema(t) || !await gastarGemas(t.preco)) return false;
    await _prefs.setStringList('temas', [...?_prefs.getStringList('temas'), t.id]);
    notifyListeners();
    return true;
  }

  /// Tema de evento pego durante o evento fica para sempre.
  Future<void> guardarTema(TemaDeBlocos t) async {
    if ((_prefs.getStringList('temas') ?? []).contains(t.id)) return;
    await _prefs.setStringList('temas', [...?_prefs.getStringList('temas'), t.id]);
  }

  Future<void> usarTema(TemaDeBlocos t) async {
    await _prefs.setString('tema', t.id);
    Cores.pecas = t.cores;
    notifyListeners();
  }

  // ---------- fases ----------

  /// Maior fase liberada (começa na 1).
  int get faseLiberada => _prefs.getInt('faseLiberada') ?? 1;
  int estrelasDaFase(int numero) => _prefs.getInt('estrelas_$numero') ?? 0;
  int get estrelasTotais => List.generate(Fase.total, (i) => estrelasDaFase(i + 1)).fold(0, (a, b) => a + b);

  /// Guarda a melhor nota e libera a próxima. Devolve as gemas ganhas
  /// (+2 na primeira vez; +15 ao terminar um mundo).
  Future<int> concluirFase(int numero, int estrelas) async {
    final primeiraVez = estrelasDaFase(numero) == 0;
    if (estrelas > estrelasDaFase(numero)) await _prefs.setInt('estrelas_$numero', estrelas);
    if (numero >= faseLiberada) await _prefs.setInt('faseLiberada', numero + 1);
    var gemas = 0;
    if (primeiraVez) gemas = 2 + (numero % Fase.porMundo == 0 ? 15 : 0);
    await ganharGemas(gemas);
    notifyListeners();
    return gemas;
  }

  // ---------- missões do dia ----------

  /// Progresso da missão no [dia]; zera sozinho quando o dia vira.
  int progressoMissao(int dia, TipoMissao tipo) =>
      _prefs.getInt('missoesDia') == dia ? (_prefs.getInt('missao_${tipo.name}') ?? 0) : 0;

  Future<void> _virarDia(int dia) async {
    if (_prefs.getInt('missoesDia') == dia) return;
    for (final t in TipoMissao.values) {
      await _prefs.remove('missao_${t.name}');
    }
    await _prefs.remove('missoesPegas');
    await _prefs.remove('bauAberto');
    await _prefs.setInt('missoesDia', dia);
  }

  Future<void> contarMissao(int dia, TipoMissao tipo, int valor) async {
    if (valor <= 0) return;
    await _virarDia(dia);
    final atual = progressoMissao(dia, tipo);
    await _prefs.setInt('missao_${tipo.name}', tipo.maximo ? (valor > atual ? valor : atual) : atual + valor);
    notifyListeners();
  }

  Future<void> contarMissoes(int dia, Map<TipoMissao, int> valores) async {
    for (final MapEntry(key: tipo, value: valor) in valores.entries) {
      await contarMissao(dia, tipo, valor);
    }
  }

  bool missaoPega(int dia, int indice) =>
      _prefs.getInt('missoesDia') == dia && (_prefs.getStringList('missoesPegas') ?? []).contains('$indice');

  bool bauAberto(int dia) => _prefs.getInt('missoesDia') == dia && (_prefs.getBool('bauAberto') ?? false);

  /// Recolhe o prêmio de uma missão concluída.
  Future<bool> pegarMissao(int dia, int indice) async {
    final m = missoesDoDia(dia)[indice];
    if (missaoPega(dia, indice) || progressoMissao(dia, m.tipo) < m.alvo) return false;
    await _virarDia(dia);
    await _prefs.setStringList('missoesPegas', [...?_prefs.getStringList('missoesPegas'), '$indice']);
    await ganharGemas(m.gemas);
    return true;
  }

  // ---------- álbum de figurinhas ----------

  Set<String> get figurinhas => {...?_prefs.getStringList('figurinhas')};

  /// Ganhou agora (só em memória): a tela mostra "Figurinha nova!" e depois limpa com [pegarFigurinhaRecente].
  ({Album album, Figurinha figurinha, bool completou})? _figurinhaRecente;

  ({Album album, Figurinha figurinha, bool completou})? pegarFigurinhaRecente() {
    final f = _figurinhaRecente;
    _figurinhaRecente = null;
    return f;
  }

  /// Sorteia e guarda uma figurinha nova. Completar um álbum paga as gemas dele. `null` se já tem todas.
  Future<({Album album, Figurinha figurinha, bool completou})?> ganharFigurinha(int semente) async {
    final tenho = figurinhas;
    final sorteada = Album.sortear(tenho, semente + tenho.length * 7919);
    if (sorteada == null) return null;
    await _prefs.setStringList('figurinhas', [...?_prefs.getStringList('figurinhas'), sorteada.figurinha.id]);
    final completou = sorteada.album.completo(figurinhas);
    if (completou) await ganharGemas(sorteada.album.premioGemas);
    notifyListeners();
    return _figurinhaRecente = (album: sorteada.album, figurinha: sorteada.figurinha, completou: completou);
  }

  Future<bool> abrirBau(int dia) async {
    if (bauAberto(dia) || !List.generate(missoesPorDia, (i) => missaoPega(dia, i)).every((p) => p)) return false;
    await _prefs.setBool('bauAberto', true);
    await ganharGemas(gemasDoBau);
    await ganharFigurinha(dia * 31 + 1);
    return true;
  }

  Future<void> ganharGemas(int quantidade) async {
    if (quantidade == 0) return;
    await _prefs.setInt('gemas', gemas + quantidade);
    notifyListeners();
  }

  /// Gasta gemas se houver saldo.
  Future<bool> gastarGemas(int quantidade) async {
    if (gemas < quantidade) return false;
    await _prefs.setInt('gemas', gemas - quantidade);
    notifyListeners();
    return true;
  }

  Future<void> definirSemAnuncios(bool valor) async {
    await _prefs.setBool('semAnuncios', valor);
    notifyListeners();
  }

  Future<void> definirAssinante(bool valor) async {
    await _prefs.setBool('assinante', valor);
    Cores.pecas = temaAtivo.cores;
    notifyListeners();
  }

  /// Anúncios premiados de gemas vistos no [dia] (aaaammdd).
  int premiadosNoDia(int dia) => _prefs.getInt('premiadosDia') == dia ? (_prefs.getInt('premiadosQtd') ?? 0) : 0;

  Future<void> registrarPremiado(int dia) async {
    final qtd = premiadosNoDia(dia) + 1;
    await _prefs.setInt('premiadosDia', dia);
    await _prefs.setInt('premiadosQtd', qtd);
    notifyListeners();
  }

  /// Partida em andamento. A chave separa o Clássico do Desafio de cada dia.
  Map<String, Object?>? partidaSalva(String chave) {
    final texto = _prefs.getString('partida_$chave');
    if (texto == null) return null;
    try {
      return (jsonDecode(texto) as Map).cast<String, Object?>();
    } on FormatException {
      return null;
    }
  }

  bool temPartidaSalva(String chave) => _prefs.containsKey('partida_$chave');

  Future<void> salvarPartida(String chave, Map<String, Object?> json) =>
      _prefs.setString('partida_$chave', jsonEncode(json));

  Future<void> apagarPartida(String chave) async {
    await _prefs.remove('partida_$chave');
    notifyListeners();
  }

  /// Assinante ganha 10 gemas por dia ao abrir o jogo.
  Future<bool> darBonusDoAssinante(int dia) async {
    if (!assinante || bonusAssinante == dia) return false;
    await _prefs.setInt('bonusAssinante', dia);
    await ganharGemas(10);
    return true;
  }
}
