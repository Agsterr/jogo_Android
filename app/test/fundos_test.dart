import 'package:encaixa/jogo/bau.dart';
import 'package:encaixa/tema.dart';
import 'package:encaixa/telas/baus_tela.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:encaixa/widgets/dicas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);
  tearDown(() => Cores.fundoDoBau = null);

  test('cada fundo tem 4 cores e fica em todas as raridades', () {
    final fundos = ItensDeBau.todos.where((i) => i.categoria == Categoria.fundo).toList();
    expect(fundos.length, 6);
    expect(fundos.every((f) => f.cores.length == 4), isTrue);
    expect(fundos.map((f) => f.raridade).toSet(), Raridade.values.toSet());
  });

  test('equipar um fundo só vale se o jogador tem o item; padrão volta ao violeta', () async {
    final s = await servicosDeTeste(
      valores: {
        'bauItens': ['fundo-aurora:1'],
      },
    );
    final p = s.progresso;
    final aurora = ItensDeBau.porId('fundo-aurora')!;
    final galaxia = ItensDeBau.porId('fundo-galaxia')!;
    expect(await p.equipar(galaxia), isFalse);
    expect(Cores.fundoDoBau, isNull);
    expect(await p.equipar(aurora), isTrue);
    expect(p.equipado(aurora), isTrue);
    expect(Cores.fundoDoBau!.length, 4);
    await p.usarPadrao(Categoria.fundo);
    expect(p.equipado(aurora), isFalse);
    expect(Cores.fundoDoBau, isNull);
  });

  testWidgets('tela de baús e tela inicial com o fundo Aurora equipado', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(
      valores: {
        'bauItens': ['fundo-aurora:1', 'fundo-noite-azul:2'],
        'fundoAtivo': 'fundo-aurora',
      },
    );
    await s.progresso.equipar(ItensDeBau.porId('fundo-aurora')!);
    await tester.pumpWidget(appDeTeste(s, tela: BausTela(servicos: s)));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(find.text('Fundo do jogo'), findsWidgets);
    await capturar(tester, '49-fundos-colecao');
    await tester.pumpWidget(appDeTeste(s, tela: InicioTela(servicos: s)));
    await tester.pumpAndSettle();
    await capturar(tester, '50-fundo-aurora');
    expect(tester.takeException(), isNull);
  });

  for (final fonte in [1.0, 1.6]) {
    testWidgets('dica longa com barra de navegação do Android (fonte $fonte): o botão fica à vista', (tester) async {
      telaDeCelular(tester, tamanho: const Size(360, 700), fonte: fonte);
      tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 144); // 24 dp e 48 dp
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final s = await servicosDeTeste();
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(onPressed: () => mostrarDica(context, Dicas.baus), child: const Text('abrir')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      final botao = tester.getBottomLeft(find.text('ENTENDI').first).dy;
      expect(botao, lessThanOrEqualTo(700 - 48), reason: 'o botão não pode ficar sob a barra do sistema');
      expect(find.text('ENTENDI'), findsWidgets);
      await capturar(tester, fonte == 1.0 ? '51-dica-barra' : '52-dica-barra-fonte-grande');
      expect(tester.takeException(), isNull);
    });
  }
}
