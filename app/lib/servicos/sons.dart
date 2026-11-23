import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'progresso.dart';

/// Efeitos do jogo. Os arquivos saem de `ferramentas/gerar_sons.py`.
enum Som { encaixe, linha, combo, incrivel, fantastico, fim }

abstract class Sons {
  Future<void> iniciar();
  void tocar(Som som);

  /// Liga ou desliga a música de fundo conforme as configurações do jogador (som e música).
  void atualizarMusica();
}

/// Para testes: não toca nada.
class SemSons implements Sons {
  const SemSons();
  @override
  Future<void> iniciar() async {}
  @override
  void tocar(Som som) {}
  @override
  void atualizarMusica() {}
}

class SonsDoJogo with WidgetsBindingObserver implements Sons {
  SonsDoJogo(this._progresso) {
    _progresso.addListener(atualizarMusica);
    WidgetsBinding.instance.addObserver(this);
  }

  final Progresso _progresso;
  final _players = {for (final s in Som.values) s: AudioPlayer()};
  final _musica = AudioPlayer();
  bool _musicaPronta = false;
  bool _tocandoMusica = false;
  bool _emPrimeiroPlano = true;

  /// A música só toca com o jogo na tela (sai quando o jogador troca de app ou bloqueia o celular).
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    _emPrimeiroPlano = estado == AppLifecycleState.resumed;
    atualizarMusica();
  }

  @override
  void atualizarMusica() {
    if (!_musicaPronta) return;
    final deveTocar = _progresso.somLigado && _progresso.musicaLigada && _emPrimeiroPlano;
    if (deveTocar == _tocandoMusica) return;
    _tocandoMusica = deveTocar;
    (deveTocar ? _musica.resume() : _musica.pause()).catchError((Object e) => debugPrint('música: $e'));
  }

  @override
  Future<void> iniciar() async {
    // Toca junto com a música do jogador, sem pausá-la.
    await AudioPlayer.global.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build());
    for (final MapEntry(key: som, value: player) in _players.entries) {
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('sons/${som.name}.wav'));
    }
    try {
      await _musica.setReleaseMode(ReleaseMode.loop);
      await _musica.setVolume(0.35);
      await _musica.setSource(AssetSource('sons/musica.wav'));
      _musicaPronta = true;
      atualizarMusica();
    } on Object catch (e) {
      debugPrint('música indisponível: $e');
    }
  }

  @override
  void tocar(Som som) {
    if (!_progresso.somLigado) return;
    final player = _players[som]!;
    player.stop().then((_) => player.resume()).catchError((Object e) => debugPrint('som $som: $e'));
  }
}
