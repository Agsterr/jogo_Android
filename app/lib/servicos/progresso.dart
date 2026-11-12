import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../jogo/fases.dart';
import '../jogo/missoes.dart';
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
    }
    await _prefs.setInt('desafioFeito', dia);
    await _prefs.setInt('desafioPontos', pontos);
    await ganharGemas(gemasGanhas);
    notifyListeners();
    return gemasGanhas;
  }

  // ---------- temas ----------

  /// Tema em uso; volta ao Clássico se o jogador perdeu o direito (ex.: assinatura acabou).
  TemaDeBlocos get temaAtivo {
    final t = TemaDeBlocos.porId(_prefs.getString('tema'));
    return temTema(t) ? t : TemaDeBlocos.classico;
  }

  /// Tem o tema? (grátis, comprado, assinante ou evento em andamento)
  bool temTema(TemaDeBlocos t, {String? eventoAtivo}) =>
      (t.preco == 0 && !t.assinante && t.evento == null) ||
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

  Future<bool> abrirBau(int dia) async {
    if (bauAberto(dia) || !List.generate(3, (i) => missaoPega(dia, i)).every((p) => p)) return false;
    await _prefs.setBool('bauAberto', true);
    await ganharGemas(gemasDoBau);
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
