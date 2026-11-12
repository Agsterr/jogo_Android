import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tudo que o jogador guarda no aparelho: recorde, gemas e o que comprou.
class Progresso extends ChangeNotifier {
  Progresso(this._prefs);

  static Future<Progresso> carregar() async => Progresso(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  /// Gemas de presente na primeira vez, para o jogador provar os reforços.
  static const int gemasIniciais = 15;

  int get recorde => _prefs.getInt('recorde') ?? 0;
  int get gemas => _prefs.getInt('gemas') ?? gemasIniciais;
  int get partidas => _prefs.getInt('partidas') ?? 0;
  bool get semAnuncios => _prefs.getBool('semAnuncios') ?? false;
  bool get assinante => _prefs.getBool('assinante') ?? false;

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

  Future<void> concluirDesafio(int dia, int pontos) async {
    if (desafioFeito == dia && pontos <= desafioPontos) return;
    final primeiraVez = desafioFeito != dia;
    await _prefs.setInt('desafioFeito', dia);
    await _prefs.setInt('desafioPontos', pontos);
    if (primeiraVez) await ganharGemas(5);
    notifyListeners();
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

  /// Assinante ganha 10 gemas por dia ao abrir o jogo.
  Future<bool> darBonusDoAssinante(int dia) async {
    if (!assinante || bonusAssinante == dia) return false;
    await _prefs.setInt('bonusAssinante', dia);
    await ganharGemas(10);
    return true;
  }
}
