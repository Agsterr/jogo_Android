import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/telas/progresso_tela.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// Área de transferência de mentira que guarda o texto (vale para "os dois celulares" do teste).
String? _clipboard;

void _simularClipboard(WidgetTester tester) {
  _clipboard = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      _clipboard = (call.arguments as Map)['text'] as String?;
    } else if (call.method == 'Clipboard.getData') {
      return <String, dynamic>{'text': _clipboard};
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

void main() {
  setUpAll(carregarFontes);

  testWidgets('trocar de celular: copia no aparelho A e recupera no aparelho B', (tester) async {
    telaDeCelular(tester);
    _simularClipboard(tester);

    // Aparelho A: jogador com progresso (e uma compra, que NÃO vai no código).
    final a = await servicosDeTeste(
      valores: {
        'gemas': 77,
        'faseLiberada': 12,
        'recorde': 4321,
        for (var n = 1; n < 12; n++) 'estrelas_$n': 3,
        'assinante': true,
      },
    );
    await tester.pumpWidget(appDeTeste(a, tela: ProgressoTela(servicos: a)));
    await tester.pump();
    expect(find.textContaining('Fase 12 de 300'), findsOneWidget);
    await capturar(tester, '26-salvar-progresso');
    await tester.tap(find.text('COPIAR CÓDIGO').first);
    await tester.pump();
    expect(_clipboard, startsWith('ENCAIXA1-'));
    expect(find.textContaining('Código copiado'), findsOneWidget);

    // Aparelho B: celular novo, sem nada.
    final b = await servicosDeTeste();
    expect(b.progresso.faseLiberada, 1);
    await tester.pumpWidget(
      appDeTeste(
        b,
        tela: ProgressoTela(key: UniqueKey(), servicos: b),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Colar'));
    await tester.pump();
    await tester.tap(find.text('RECUPERAR').first);
    await tester.pumpAndSettle();
    expect(find.text('Recuperar este progresso?'), findsOneWidget);
    expect(find.textContaining('Fase 12'), findsWidgets);
    await capturar(tester, '27-recuperar-progresso');
    await tester.tap(find.text('Recuperar'));
    // Sem pumpAndSettle: a mensagem "Progresso recuperado!" some sozinha depois de 4 s.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('Progresso recuperado'), findsOneWidget);
    expect((b.progresso.faseLiberada, b.progresso.gemas, b.progresso.recorde), (12, 77, 4321));
    expect(b.progresso.estrelasDaFase(5), 3);
    expect(b.progresso.assinante, isFalse, reason: 'compra não vai no código (volta por Restaurar compras)');
  });

  testWidgets('código errado mostra aviso e não mexe no progresso', (tester) async {
    telaDeCelular(tester);
    _simularClipboard(tester);
    final s = await servicosDeTeste(valores: {'gemas': 5});
    await tester.pumpWidget(appDeTeste(s, tela: ProgressoTela(servicos: s)));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ENCAIXA1-isto-nao-e-um-codigo');
    await tester.pump();
    await tester.tap(find.text('RECUPERAR').first);
    await tester.pump();
    expect(find.textContaining('Código inválido'), findsOneWidget);
    expect(s.progresso.gemas, 5);
    await capturar(tester, '28-codigo-invalido');
  });

  testWidgets('colar o código do próprio celular é recusado (não duplica gemas)', (tester) async {
    telaDeCelular(tester);
    _simularClipboard(tester);
    final s = await servicosDeTeste(valores: {'gemas': 100});
    await tester.pumpWidget(appDeTeste(s, tela: ProgressoTela(servicos: s)));
    await tester.pump();
    await tester.tap(find.text('COPIAR CÓDIGO').first);
    await tester.pump();
    await tester.enterText(find.byType(TextField), _clipboard!);
    await tester.pump();
    await tester.tap(find.text('RECUPERAR').first);
    await tester.pump();
    expect(find.textContaining('já está neste celular'), findsOneWidget);
    expect(CodigoProgresso.ler(_clipboard!), isNotNull);
  });
}
