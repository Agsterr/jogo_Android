import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/telas/loja_tela.dart';
import 'package:encaixa/widgets/tabuleiro_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// Partida no meio: tabuleiro com blocos e a linha 6 quase completa.
Partida partidaDeExemplo() {
  final p = Partida(semente: 2026);
  const desenho = ['........', '......44', '3.....45', '33...055', '311..000', '2222.500', '55555...', '1144.223'];
  for (var l = 0; l < 8; l++) {
    for (var k = 0; k < 8; k++) {
      final ch = desenho[l][k];
      if (ch != '.') p.tabuleiro.definir(l, k, int.parse(ch));
    }
  }
  p
    ..mao = [
      Peca(Formato.desenho(['###']), 5),
      Peca(Formato.desenho(['##', '##']), 2),
      Peca(Formato.desenho(['#.', '#.', '##']), 0),
    ]
    ..pontos = 1240
    ..combo = 2;
  return p;
}

/// Tabuleiro sem lugar para a peça da mão.
Partida partidaSemEspaco() {
  final p = Partida(semente: 1);
  for (var l = 0; l < 8; l++) {
    for (var k = 0; k < 8; k++) {
      if ((l + k).isOdd || l == 0) p.tabuleiro.definir(l, k, (l * 3 + k) % 6);
    }
  }
  p
    ..mao = [
      Peca(Formato.desenho(['##', '##']), 4),
      null,
      null,
    ]
    ..pontos = 2380;
  return p;
}

/// Ponto onde o dedo precisa estar para a peça [i] cair em (linha, coluna).
Offset dedoPara(WidgetTester tester, Peca peca, int linha, int coluna) {
  final caixa = tester.renderObject<RenderBox>(find.byType(TabuleiroWidget));
  final casa = caixa.size.width / 8;
  final canto = caixa.localToGlobal(Offset(coluna * casa, linha * casa));
  return canto + Offset(peca.formato.colunas * casa / 2, peca.formato.linhas * casa + casa * 1.2);
}

void main() {
  setUpAll(carregarFontes);

  testWidgets('tela inicial', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'recorde': 3120, 'gemas': 42});
    await tester.pumpWidget(appDeTeste(s));
    await tester.pumpAndSettle();
    expect(find.text('JOGAR'), findsOneWidget);
    expect(find.text('Desafio do dia #12'), findsOneWidget);
    await capturar(tester, '1-inicio');
  });

  testWidgets('arrastar a peça mostra a prévia e completar a linha pontua', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'recorde': 3120, 'gemas': 42});
    final partida = partidaDeExemplo();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partida),
      ),
    );
    await tester.pump();

    final peca = partida.mao[0]!;
    final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
    await gesto.moveTo(dedoPara(tester, peca, 6, 5));
    await tester.pump();
    await capturar(tester, '2-jogo-arrastando');

    await gesto.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 260));
    expect(partida.pontos, greaterThan(1240));
    expect(partida.tabuleiro.cor(6, 0), isNull, reason: 'a linha 6 sumiu');
    await capturar(tester, '3-jogo-combo');
    await tester.pumpAndSettle();
  });

  testWidgets('sem espaço oferece segunda chance e depois o resultado', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'recorde': 1500, 'gemas': 12});
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaSemEspaco()),
      ),
    );
    await tester.pump();
    expect(find.text('Sem espaço!'), findsOneWidget);
    await capturar(tester, '4-segunda-chance');

    await tester.tap(find.text('Não, obrigado'));
    await tester.pumpAndSettle();
    expect(find.text('Novo recorde!'), findsOneWidget);
    expect(s.progresso.recorde, 2380);
    await capturar(tester, '5-novo-recorde');
  });

  testWidgets('segunda chance com gemas continua a partida', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 12});
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaSemEspaco()),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Usar 10 gemas'));
    await tester.pump();
    expect(find.text('Sem espaço!'), findsNothing);
    expect(s.progresso.gemas, 2);
  });

  testWidgets('loja: comprar "sem anúncios" libera na hora', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 42});
    await tester.pumpWidget(appDeTeste(s, tela: LojaTela(servicos: s)));
    await tester.pump();
    await capturar(tester, '6-loja');
    await tester.tap(find.text(r'R$ 14,90'));
    await tester.pump();
    expect(s.progresso.semAnuncios, isTrue);
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('loja: gemas por anúncio param depois de 5 no dia', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: {'gemas': 0, 'premiadosDia': 20261112, 'premiadosQtd': 4});
    await tester.pumpWidget(appDeTeste(s, tela: LojaTela(servicos: s)));
    await tester.pump();
    expect(find.textContaining('4 de 5 hoje'), findsOneWidget);
    await tester.tap(find.text('Assistir'));
    await tester.pump();
    expect(s.progresso.gemas, 5);
    expect(find.textContaining('5 de 5 hoje'), findsOneWidget);
    await tester.tap(find.text('Assistir'));
    await tester.pump();
    expect(s.progresso.gemas, 5, reason: 'botão desativado');
    expect(s.progresso.premiadosNoDia(20261113), 0, reason: 'zera no dia seguinte');
  });

  testWidgets('tela pequena com fonte grande não estoura', (tester) async {
    telaDeCelular(tester, tamanho: const Size(320, 600), fonte: 1.3);
    final s = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(s));
    await tester.pumpAndSettle();
    await capturar(tester, '7-pequena-inicio');
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaDeExemplo()),
      ),
    );
    await tester.pump();
    await capturar(tester, '8-pequena-jogo');
    await tester.pumpWidget(appDeTeste(s, tela: LojaTela(servicos: s)));
    await tester.pump();
  });
}
