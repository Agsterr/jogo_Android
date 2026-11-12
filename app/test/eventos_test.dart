import 'package:encaixa/jogo/eventos.dart';
import 'package:encaixa/jogo/temas.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fim de semana vai de sexta 18h a domingo', () {
    expect(fimDeSemana(DateTime(2026, 11, 13, 17, 59)), isFalse); // sexta
    expect(fimDeSemana(DateTime(2026, 11, 13, 18)), isTrue);
    expect(fimDeSemana(DateTime(2026, 11, 15, 23, 59)), isTrue); // domingo
    expect(fimDeSemana(DateTime(2026, 11, 16)), isFalse); // segunda
  });

  test('evento de Natal e gemas em dobro', () {
    expect(eventoAtivo(DateTime(2026, 12, 17, 23)), isNull);
    expect(eventoAtivo(DateTime(2026, 12, 18))?.id, 'natal-2026');
    expect(eventoAtivo(DateTime(2026, 12, 27)), isNull);
    expect(multiplicadorDeGemas(DateTime(2026, 12, 22, 10)), 2); // terça, mas no evento
    expect(eventoAtivo(DateTime(2026, 11, 17))?.id, 'festival-2026');
    expect(multiplicadorDeGemas(DateTime(2027, 1, 12, 10)), 1); // terça sem evento
    expect(tempoRestante(DateTime(2026, 12, 23, 20), DateTime(2026, 12, 27)), '3d 4h');
  });

  test('temas: comprar com gemas, assinante e evento', () async {
    SharedPreferences.setMockInitialValues({'gemas': 160});
    final p = await Progresso.carregar();
    final doce = TemaDeBlocos.porId('doce'), neon = TemaDeBlocos.porId('neon');
    final galaxia = TemaDeBlocos.porId('galaxia'), natal = TemaDeBlocos.porId('natal');
    expect(p.temTema(TemaDeBlocos.classico), isTrue);
    expect(await p.comprarTema(neon), isFalse, reason: 'gemas insuficientes');
    expect(await p.comprarTema(doce), isTrue);
    expect(p.gemas, 10);
    expect(p.temTema(galaxia), isFalse);
    await p.definirAssinante(true);
    expect(p.temTema(galaxia), isTrue);
    expect(p.temTema(natal), isFalse);
    expect(p.temTema(natal, eventoAtivo: 'natal-2026'), isTrue);
    await p.guardarTema(natal);
    expect(p.temTema(natal), isTrue, reason: 'pegou durante o evento, fica para sempre');
    await p.usarTema(doce);
    expect(p.temaAtivo.id, 'doce');
  });
}
