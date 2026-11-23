import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ranking mundial (placar do Google Play Games). Só aparece depois que o placar é criado na Play Console e o ID
/// vai em `android/app/src/main/res/values/game_services.xml` (veja docs/PLAY_GAMES.md).
abstract class Ranking {
  /// O placar está configurado neste build?
  Future<bool> disponivel();

  /// Manda a pontuação (o Google guarda só a melhor de cada jogador).
  Future<void> enviar(int pontos);

  /// Abre o placar do Google, o da semana (zera sozinho) ou o de todos os tempos. `false` se não deu (sem conta, sem placar).
  Future<bool> abrir({bool semana = false});
}

class SemRanking implements Ranking {
  const SemRanking();

  @override
  Future<bool> disponivel() async => false;

  @override
  Future<void> enviar(int pontos) async {}

  @override
  Future<bool> abrir({bool semana = false}) async => false;
}

class RankingPlayGames implements Ranking {
  static const _canal = MethodChannel('encaixa/nuvem');

  bool? _ok;

  @override
  Future<bool> disponivel() async {
    if (_ok != null) return _ok!;
    try {
      return _ok = await _canal.invokeMethod<bool>('rankingDisponivel') ?? false;
    } on Object catch (e) {
      debugPrint('Ranking (disponivel): $e');
      return _ok = false;
    }
  }

  @override
  Future<void> enviar(int pontos) async {
    if (pontos <= 0 || !await disponivel()) return;
    try {
      await _canal.invokeMethod<bool>('enviarPontos', {'pontos': pontos});
    } on Object catch (e) {
      debugPrint('Ranking (enviar): $e'); // sem conta ou sem rede: o jogo segue normalmente
    }
  }

  @override
  Future<bool> abrir({bool semana = false}) async {
    if (!await disponivel()) return false;
    try {
      return await _canal.invokeMethod<bool>('abrirRanking', {'semana': semana}) ?? false;
    } on PlatformException catch (e) {
      if (e.code != 'desconectado') return false;
      // Ainda sem login: pede a conta e tenta de novo uma vez.
      try {
        if (await _canal.invokeMethod<bool>('conectar') != true) return false;
        return await _canal.invokeMethod<bool>('abrirRanking', {'semana': semana}) ?? false;
      } on Object {
        return false;
      }
    } on Object catch (e) {
      debugPrint('Ranking (abrir): $e');
      return false;
    }
  }
}
