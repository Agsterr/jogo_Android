import 'package:encaixa/servicos/anuncios.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 12, 10);

  test('não mostra anúncio nas primeiras partidas', () {
    final p = PoliticaIntersticial();
    for (var i = 1; i <= 3; i++) {
      expect(p.deveMostrar(partidasJogadas: i, agora: t0), isFalse);
    }
  });

  test('no máximo um a cada 3 partidas e 3 minutos', () {
    final p = PoliticaIntersticial();
    expect(p.deveMostrar(partidasJogadas: 10, agora: t0), isFalse);
    expect(p.deveMostrar(partidasJogadas: 11, agora: t0), isFalse);
    expect(p.deveMostrar(partidasJogadas: 12, agora: t0), isTrue);
    p.mostrou(t0);
    final cedo = t0.add(const Duration(minutes: 1));
    for (var i = 13; i <= 15; i++) {
      expect(p.deveMostrar(partidasJogadas: i, agora: cedo), isFalse);
    }
    expect(p.deveMostrar(partidasJogadas: 16, agora: t0.add(const Duration(minutes: 4))), isTrue);
  });

  test('rodadas de qualquer modo contam para os anúncios (quem só joga Fases também vê)', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await Progresso.carregar();
    expect(p.rodadasParaAnuncios, 0);
    for (var i = 0; i < 4; i++) {
      await p.contarRodada();
    }
    expect(p.rodadas, 4);
    expect(p.partidas, 0);
    expect(p.rodadasParaAnuncios, 4, reason: 'passou das 3 primeiras: o anúncio já pode aparecer');
    final antigo = await (() async {
      SharedPreferences.setMockInitialValues({'partidas': 40});
      return Progresso.carregar();
    })();
    expect(antigo.rodadasParaAnuncios, 40, reason: 'quem já jogava não volta ao período sem anúncios');
  });
}
