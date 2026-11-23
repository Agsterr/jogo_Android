import 'package:encaixa/jogo/missoes.dart';
import 'package:encaixa/jogo/temas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('próximo marco da sequência', () {
    expect(proximoMarco(0), 3);
    expect(proximoMarco(3), 7);
    expect(proximoMarco(13), 14);
    expect(proximoMarco(29), 30);
    expect(proximoMarco(30), isNull);
  });

  test('30 dias seguidos liberam o tema Chama para sempre; antes disso ele está bloqueado', () async {
    final s = await servicosDeTeste(valores: {'sequencia': 29, 'desafioFeito': 20261111});
    final p = s.progresso;
    final chama = TemaDeBlocos.porId('chama');
    expect(chama.marcoDias, 30);
    expect(p.temTema(chama), isFalse);
    final gemas = await p.concluirDesafio(20261112, 500);
    expect(gemas, 5 + 60, reason: '5 do desafio + 60 do marco de 30 dias');
    expect(p.sequencia(20261112), 30);
    expect(p.temTema(chama), isTrue);
    // dias depois, sem jogar, o tema continua
    expect(p.sequencia(20261120), 0);
    expect(p.temTema(chama), isTrue);
  });

  test('marco intermediário (7 dias) paga gemas mas não libera o tema', () async {
    final s = await servicosDeTeste(valores: {'sequencia': 6, 'desafioFeito': 20261111});
    final gemas = await s.progresso.concluirDesafio(20261112, 100);
    expect(gemas, 5 + 15);
    expect(s.progresso.temTema(TemaDeBlocos.porId('chama')), isFalse);
  });

  for (final (fonte, nome) in [(1.0, '24-sequencia'), (1.5, '25-sequencia-fonte-grande')]) {
    testWidgets('diálogo da sequência ($nome)', (tester) async {
      telaDeCelular(tester, tamanho: const Size(360, 800), fonte: fonte);
      final s = await servicosDeTeste(valores: {'sequencia': 5, 'desafioFeito': 20261111});
      await tester.pumpWidget(appDeTeste(s));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.local_fire_department_rounded).first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Sequência do Desafio'), findsOneWidget);
      expect(find.textContaining('próximo prêmio'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturar(tester, nome);
    });
  }
}
