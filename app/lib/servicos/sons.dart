import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'progresso.dart';

/// Efeitos do jogo. Os arquivos saem de `ferramentas/gerar_sons.py`.
enum Som { encaixe, linha, combo, fim }

abstract class Sons {
  Future<void> iniciar();
  void tocar(Som som);
}

/// Para testes: não toca nada.
class SemSons implements Sons {
  const SemSons();
  @override
  Future<void> iniciar() async {}
  @override
  void tocar(Som som) {}
}

class SonsDoJogo implements Sons {
  SonsDoJogo(this._progresso);

  final Progresso _progresso;
  final _players = {for (final s in Som.values) s: AudioPlayer()};

  @override
  Future<void> iniciar() async {
    // Toca junto com a música do jogador, sem pausá-la.
    await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    for (final MapEntry(key: som, value: player) in _players.entries) {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('sons/${som.name}.wav'));
    }
  }

  @override
  void tocar(Som som) {
    if (!_progresso.somLigado) return;
    final player = _players[som]!;
    player.stop().then((_) => player.resume()).catchError((Object e) => debugPrint('som $som: $e'));
  }
}
