import 'package:encaixa/jogo/missoes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('faixas do Desafio pela pontuação', () {
    expect(Faixa.de(0), Faixa.nenhuma);
    expect(Faixa.de(1499), Faixa.nenhuma);
    expect(Faixa.de(1500), Faixa.bronze);
    expect(Faixa.de(4000), Faixa.prata);
    expect(Faixa.de(7999), Faixa.prata);
    expect(Faixa.de(8000), Faixa.ouro);
    expect(Faixa.de(50000), Faixa.ouro);
  });

  test('o bônus da faixa paga só a diferença quando o jogador melhora no mesmo dia', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final p = s.progresso;
    const dia = 20261112;
    final base = await p.concluirDesafio(dia, 1600);
    expect(base, 5, reason: 'o retorno continua sendo só as gemas do Desafio (+ sequência)');
    expect(p.pegarFaixaRecente()?.faixa, Faixa.bronze);
    expect(p.pegarFaixaRecente(), isNull, reason: 'só aparece uma vez');
    expect(p.gemas, 5 + 3);
    await p.concluirDesafio(dia, 1700); // melhorou, mas continua bronze
    expect(p.pegarFaixaRecente(), isNull);
    expect(p.gemas, 5 + 3);
    await p.concluirDesafio(dia, 9000); // pulou para ouro: paga 15 - 3
    expect(p.pegarFaixaRecente()?.gemas, 12);
    expect(p.gemas, 5 + 15);
    await p.concluirDesafio(dia, 9500);
    expect(p.gemas, 5 + 15, reason: 'ouro não paga de novo');
    // no dia seguinte começa do zero
    await p.concluirDesafio(dia + 1, 4100);
    expect(p.pegarFaixaRecente()?.faixa, Faixa.prata);
  });

  test('pontuação abaixo de bronze não dá bônus', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    await s.progresso.concluirDesafio(20261112, 300);
    expect(s.progresso.pegarFaixaRecente(), isNull);
    expect(s.progresso.gemas, 5);
  });

  test('presente da noite: só depois das 19h e uma vez por dia', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final p = s.progresso;
    const dia = 20261112;
    expect(p.presenteDaNoiteDisponivel(dia, DateTime(2026, 11, 12, 18, 59)), isFalse);
    expect(await p.pegarPresenteDaNoite(dia, DateTime(2026, 11, 12, 18, 59)), 0);
    expect(p.presenteDaNoiteDisponivel(dia, DateTime(2026, 11, 12, 19)), isTrue);
    expect(await p.pegarPresenteDaNoite(dia, DateTime(2026, 11, 12, 21)), gemasDaNoite);
    expect(await p.pegarPresenteDaNoite(dia, DateTime(2026, 11, 12, 22)), 0, reason: 'uma vez por dia');
    expect(p.presenteDaNoiteDisponivel(dia + 1, DateTime(2026, 11, 13, 20)), isTrue, reason: 'no dia seguinte volta');
    expect(p.gemas, gemasDaNoite);
    expect(p.passeXp(dia), 20);
  });

  testWidgets('tela inicial depois das 19h mostra o presente da noite e pega', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(hoje: DateTime(2026, 11, 12, 20), valores: {'gemas': 0});
    await tester.pumpWidget(appDeTeste(s));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Presente da noite!'), findsOneWidget);
    await capturar(tester, '38-presente-da-noite');
    await tester.tap(find.text('Presente da noite!'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(s.progresso.gemas, gemasDaNoite);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Presente da noite!'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
