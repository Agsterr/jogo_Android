import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/widgets/dicas.dart';
import 'package:encaixa/widgets/exemplo_dica.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('derrotas seguidas na mesma fase: contam, zeram ao vencer e ao mudar de fase', () async {
    final s = await servicosDeTeste();
    final p = s.progresso;
    expect(p.falhasNaFase(62), 0);
    expect(await p.registrarFalhaNaFase(62), 1);
    expect(await p.registrarFalhaNaFase(62), 2);
    expect(p.falhasNaFase(62), 2);
    expect(p.falhasNaFase(63), 0, reason: 'outra fase começa do zero');
    await p.concluirFase(62, 2);
    expect(p.falhasNaFase(62), 0, reason: 'venceu: zera');
    expect(await p.registrarFalhaNaFase(62), 1);
  });

  test('toda dica das fases tem exemplo desenhado e cada exemplo é um dos 5 tipos', () {
    for (final d in [Dicas.fases, Dicas.pedras, Dicas.pontos, Dicas.umaCor, Dicas.combo]) {
      expect(d.exemplo, isNotNull, reason: d.id);
    }
    expect(ExemploDaDica.values.length, 5);
  });

  testWidgets('botão ? abre a dica do objetivo da fase com o exemplo', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    final fase = Fase.numero(62);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(ExemploDaDicaWidget), findsOneWidget);
    await capturar(tester, '70-dica-com-exemplo-${fase.objetivo.name}');
    expect(tester.takeException(), isNull);
  });

  for (final dica in [Dicas.combo, Dicas.pedras, Dicas.umaCor, Dicas.pontos, Dicas.fases]) {
    testWidgets('dica com exemplo: ${dica.id} em tela pequena e fonte grande', (tester) async {
      telaDeCelular(tester, tamanho: const Size(320, 640), fonte: 1.3);
      final s = await servicosDeTeste();
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(onPressed: () => mostrarDica(context, dica), child: const Text('abrir')),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(ExemploDaDicaWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturar(tester, '71-dica-exemplo-${dica.id}');
    });
  }

  testWidgets('perder 2 vezes seguidas abre a dica sozinha e mostra o cartão "Ver dica"', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'gemas': 20, 'falhasFase': 62, 'falhasQtd': 1});
    final fase = Fase.numero(62);
    final partida = fase.novaPartida()
      ..jogadas = fase.pecas - 1
      ..mao = [
        Peca(Formato.desenho(['#']), 2),
        null,
        null,
      ];
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, fase: fase, partida: partida),
      ),
    );
    await tester.pump();
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveBy(const Offset(0, -260));
    await gesto.up();
    await tester.pumpAndSettle();
    expect(s.progresso.falhasNaFase(62), 2);
    expect(find.byType(ExemploDaDicaWidget), findsOneWidget, reason: 'a dica abre sozinha na 2ª derrota');
    await tester.tap(find.text('ENTENDI').first);
    await tester.pumpAndSettle();
    expect(find.text('Está difícil? Veja uma dica com exemplo.'), findsOneWidget);
    await capturar(tester, '72-fase-falhou-dica');
    expect(tester.takeException(), isNull);
  });
}
