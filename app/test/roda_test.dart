import 'package:encaixa/jogo/roda.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sorteio da roda é determinístico e usa todas as fatias', () {
    expect(Roda.sortear(20261113, 0), Roda.sortear(20261113, 0));
    final fatias = {for (var d = 0; d < 400; d++) Roda.sortear(20260000 + d, 0)};
    expect(fatias, hasLength(Roda.premios.length));
  });

  test('3 giros por dia, gemas certas, zera no dia seguinte', () async {
    SharedPreferences.setMockInitialValues({'gemas': 0});
    final p = await Progresso.carregar();
    var esperado = 0;
    for (var i = 0; i < Roda.girosPorDia; i++) {
      final fatia = await p.girarRoda(20261113);
      esperado += Roda.premios[fatia!];
    }
    expect(await p.girarRoda(20261113), isNull);
    expect(p.gemas, esperado);
    expect(p.girosNoDia(20261114), 0);
  });
}
