import 'package:encaixa/servicos/lembrete.dart';
import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

class _Falso implements Lembrete {
  bool permissao = true;
  ({bool ligado, bool feito})? ultimo;

  @override
  Future<bool> pedirPermissao() async => permissao;

  @override
  Future<void> reagendar({required bool ligado, required bool desafioFeitoHoje, required DateTime agora}) async =>
      ultimo = (ligado: ligado, feito: desafioFeitoHoje);
}

void main() {
  setUpAll(carregarFontes);

  group('proximoLembrete', () {
    test('antes das 19h e Desafio por fazer: hoje às 19h', () {
      expect(proximoLembrete(DateTime(2026, 11, 23, 9), desafioFeitoHoje: false), DateTime(2026, 11, 23, 19));
    });
    test('Desafio de hoje já feito: amanhã às 19h', () {
      expect(proximoLembrete(DateTime(2026, 11, 23, 9), desafioFeitoHoje: true), DateTime(2026, 11, 24, 19));
    });
    test('depois das 19h: amanhã às 19h', () {
      expect(proximoLembrete(DateTime(2026, 11, 23, 20), desafioFeitoHoje: false), DateTime(2026, 11, 24, 19));
      expect(proximoLembrete(DateTime(2026, 11, 23, 19), desafioFeitoHoje: false), DateTime(2026, 11, 24, 19));
    });
    test('virada de mês e de ano', () {
      expect(proximoLembrete(DateTime(2026, 12, 31, 22), desafioFeitoHoje: false), DateTime(2027, 1, 1, 19));
    });
  });

  testWidgets('ligar o lembrete pede permissão, guarda e agenda; sem permissão continua desligado', (tester) async {
    telaDeCelular(tester);
    final falso = _Falso();
    final s = await servicosDeTeste(lembrete: falso);
    await tester.pumpWidget(appDeTeste(s, tela: AjudaTela(servicos: s)));
    await tester.pump();
    expect(find.text('Lembrete do Desafio'), findsOneWidget);
    await capturar(tester, '19-lembrete');

    falso.permissao = false;
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(s.progresso.lembreteLigado, isFalse);
    expect(find.textContaining('Sem permissão'), findsOneWidget);

    falso.permissao = true;
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(s.progresso.lembreteLigado, isTrue);
    expect(falso.ultimo, (ligado: true, feito: false));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(s.progresso.lembreteLigado, isFalse);
    expect(falso.ultimo, (ligado: false, feito: false));
  });
}
