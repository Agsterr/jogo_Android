import 'package:encaixa/servicos/anuncios.dart';
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
}
