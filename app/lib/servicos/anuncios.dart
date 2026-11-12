import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Quando mostrar anúncio entre partidas sem irritar quem joga.
///
/// - nunca nas primeiras partidas (deixa a pessoa gostar do jogo antes);
/// - no máximo um a cada [cadaPartidas] partidas;
/// - e com pelo menos [intervaloMinimo] entre um e outro.
class PoliticaIntersticial {
  PoliticaIntersticial({
    this.partidasLivres = 3,
    this.cadaPartidas = 3,
    this.intervaloMinimo = const Duration(minutes: 3),
  });

  final int partidasLivres;
  final int cadaPartidas;
  final Duration intervaloMinimo;
  DateTime? _ultimo;
  int _desdeUltimo = 0;

  bool deveMostrar({required int partidasJogadas, required DateTime agora}) {
    _desdeUltimo++;
    if (partidasJogadas <= partidasLivres) return false;
    if (_desdeUltimo < cadaPartidas) return false;
    final ultimo = _ultimo;
    if (ultimo != null && agora.difference(ultimo) < intervaloMinimo) return false;
    return true;
  }

  void mostrou(DateTime agora) {
    _ultimo = agora;
    _desdeUltimo = 0;
  }
}

/// Anúncios do jogo. A versão "nenhum" serve para testes e plataformas sem AdMob.
abstract class Anuncios {
  Future<void> iniciar();

  /// Anúncio premiado (o jogador escolhe ver). Devolve `true` se ganhou a recompensa.
  Future<bool> mostrarPremiado();

  /// Anúncio entre partidas, respeitando a [PoliticaIntersticial].
  Future<void> talvezIntersticial({required int partidasJogadas});
}

class SemAnuncios implements Anuncios {
  @override
  Future<void> iniciar() async {}
  @override
  Future<bool> mostrarPremiado() async => true;
  @override
  Future<void> talvezIntersticial({required int partidasJogadas}) async {}
}

/// AdMob. Os IDs reais vêm de `--dart-define`; sem eles usa os IDs de teste do Google.
class AnunciosAdMob implements Anuncios {
  AnunciosAdMob({PoliticaIntersticial? politica}) : _politica = politica ?? PoliticaIntersticial();

  static const _idPremiado = String.fromEnvironment(
    'ADMOB_PREMIADO',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const _idIntersticial = String.fromEnvironment(
    'ADMOB_INTERSTICIAL',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  final PoliticaIntersticial _politica;
  RewardedAd? _premiado;
  InterstitialAd? _intersticial;

  @override
  Future<void> iniciar() async {
    await _pedirConsentimento();
    await MobileAds.instance.initialize();
    _carregarPremiado();
    _carregarIntersticial();
  }

  /// Formulário de consentimento do Google (UMP): aparece só onde a lei exige.
  Future<void> _pedirConsentimento() {
    final pronto = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => pronto.complete()),
      (_) => pronto.complete(),
    );
    return pronto.future;
  }

  void _carregarPremiado() => RewardedAd.load(
    adUnitId: _idPremiado,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) => _premiado = ad,
      onAdFailedToLoad: (erro) => debugPrint('premiado não carregou: $erro'),
    ),
  );

  void _carregarIntersticial() => InterstitialAd.load(
    adUnitId: _idIntersticial,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) => _intersticial = ad,
      onAdFailedToLoad: (erro) => debugPrint('intersticial não carregou: $erro'),
    ),
  );

  @override
  Future<bool> mostrarPremiado() async {
    final ad = _premiado;
    if (ad == null) {
      _carregarPremiado();
      return false;
    }
    _premiado = null;
    final fim = Completer<bool>();
    var ganhou = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _carregarPremiado();
        if (!fim.isCompleted) fim.complete(ganhou);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _carregarPremiado();
        if (!fim.isCompleted) fim.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => ganhou = true);
    return fim.future;
  }

  @override
  Future<void> talvezIntersticial({required int partidasJogadas}) async {
    final agora = DateTime.now();
    if (!_politica.deveMostrar(partidasJogadas: partidasJogadas, agora: agora)) return;
    final ad = _intersticial;
    if (ad == null) {
      _carregarIntersticial();
      return;
    }
    _intersticial = null;
    _politica.mostrou(agora);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _carregarIntersticial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _carregarIntersticial();
      },
    );
    await ad.show();
  }
}
