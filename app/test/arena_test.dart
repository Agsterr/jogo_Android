import 'package:encaixa/jogo/arena.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('semana vai de segunda a domingo', () {
    expect(Arena.semana(DateTime(2026, 11, 9)), 20261109); // segunda
    expect(Arena.semana(DateTime(2026, 11, 15, 23)), 20261109); // domingo
    expect(Arena.semana(DateTime(2026, 11, 16)), 20261116);
    expect(Arena.fim(DateTime(2026, 11, 12, 10)), DateTime(2026, 11, 16));
    expect(Arena.semente(DateTime(2026, 11, 10)), Arena.semente(DateTime(2026, 11, 14)));
  });

  test('troféu pela pontuação', () {
    expect(Arena.trofeuPara(499), isNull);
    expect(Arena.trofeuPara(1500)?.nome, 'Prata');
    expect(Arena.trofeuPara(99999)?.nome, 'Diamante');
  });

  test('melhor da semana, prêmios uma vez e virada de semana', () async {
    SharedPreferences.setMockInitialValues({'gemas': 0});
    final p = await Progresso.carregar();
    const semana = 20261109;
    await p.registrarArena(semana, 1600);
    await p.registrarArena(semana, 900);
    expect(p.arenaMelhor(semana), 1600);
    expect(await p.pegarPremioArena(semana, Arena.trofeus[1]), 25);
    expect(await p.pegarPremioArena(semana, Arena.trofeus[1]), 0);
    expect(await p.pegarPremioArena(semana, Arena.trofeus[2]), 0, reason: 'não chegou no Ouro');
    expect(p.arenaMelhor(20261116), 0);
    await p.registrarArena(20261116, 100);
    expect(p.premioArenaPego(20261116, 'Prata'), isFalse);
  });
}
