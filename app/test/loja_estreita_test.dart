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
}
