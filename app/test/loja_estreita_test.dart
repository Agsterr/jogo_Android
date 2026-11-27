import 'package:encaixa/jogo/temas.dart';
import 'package:encaixa/telas/loja_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// A Loja em celular estreito e com fonte grande: o texto dos produtos não pode ser espremido (palavras quebradas).
void main() {
  setUpAll(carregarFontes);

  for (final (nome, fonte, tamanho) in [
    ('64-loja-fonte-1-3', 1.3, const Size(360, 800)),
    ('65-loja-fonte-1-6', 1.6, const Size(360, 800)),
    ('66-loja-pequena', 1.3, const Size(320, 640)),
    ('68-loja-tela-ampliada', 1.3, const Size(280, 600)), // 'Tamanho da tela' ampliado no Samsung
  ]) {
    testWidgets('loja legível ($nome)', (tester) async {
      telaDeCelular(tester, tamanho: tamanho, fonte: fonte);
      final s = await servicosDeTeste();
      await tester.pumpWidget(appDeTeste(s, tela: LojaTela(servicos: s)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // "anúncios" inteiro numa linha só: a palavra não pode ser partida ao meio.
      final largura = tester.getSize(find.text('Sem anúncios').first).width;
      expect(largura, greaterThan(80), reason: 'título espremido');
      await capturar(tester, nome);
      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturar(tester, '$nome-temas');
    });
  }

  test('todo tema da Loja tem um jeito de conseguir: preço, assinatura, evento, marco, passe, baú ou é o clássico', () {
    for (final t in TemaDeBlocos.todos) {
      final jeito = t.preco > 0 || t.assinante || t.evento != null || t.marcoDias != null || t.passe || t.bau;
      expect(jeito || t.id == TemaDeBlocos.classico.id, isTrue, reason: '${t.nome} ficaria com preço 0');
    }
  });

  testWidgets('temas dos baús não mostram preço 0: ficam travados com "Só nos baús" e liberam o Usar quando saem', (
    tester,
  ) async {
    telaDeCelular(tester, tamanho: const Size(360, 2600));
    final s = await servicosDeTeste(
      valores: {
        'gemas': 243,
        'temas': ['tema-menta'],
      },
    );
    await tester.pumpWidget(appDeTeste(s, tela: LojaTela(servicos: s)));
    await tester.pumpAndSettle();
    expect(find.text('Só nos baús'), findsNWidgets(5), reason: '6 temas de baú, 1 já saiu');
    expect(find.text(' 0'), findsNothing, reason: 'nenhum botão com preço 0');
    await capturar(tester, '67-loja-temas-bau');
    expect(tester.takeException(), isNull);
  });
}
