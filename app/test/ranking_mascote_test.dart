import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/servicos/ranking.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/widgets/mascote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaDeExemplo;

class _RankingFalso implements Ranking {
  _RankingFalso({this.pronto = true});

  final bool pronto;
  final enviados = <int>[];
  int aberturas = 0;

  @override
  Future<bool> disponivel() async => pronto;

  @override
  Future<void> enviar(int pontos) async => enviados.add(pontos);

  @override
  Future<bool> abrir() async {
    aberturas++;
    return true;
  }
}

void main() {
  setUpAll(carregarFontes);

  group('fala do mascote', () {
    test('elogio forte vira "Uau", elogio normal vira festa', () {
      final uau = falaAposJogada(elogioNivel: 4, elogioTexto: 'Fantástico!', semLimpar: 0, ocupadas: 10, jogadas: 3)!;
      expect(uau.humor, Humor.uau);
      expect(uau.texto, contains('Fantástico'));
      final festa = falaAposJogada(elogioNivel: 1, elogioTexto: 'Boa!', semLimpar: 0, ocupadas: 10, jogadas: 3)!;
      expect(festa.humor, Humor.festa);
      expect(festa.texto, 'Boa!');
    });

    test('tabuleiro quase cheio avisa; a cada 5 jogadas sem limpar dá uma dica; senão fica quieto', () {
      expect(falaAposJogada(elogioNivel: 0, semLimpar: 1, ocupadas: 52, jogadas: 9)!.humor, Humor.triste);
      final dica = falaAposJogada(elogioNivel: 0, semLimpar: 5, ocupadas: 20, jogadas: 10)!;
      expect(dica.texto, startsWith('Dica'));
      expect(falaAposJogada(elogioNivel: 0, semLimpar: 3, ocupadas: 20, jogadas: 8), isNull);
      expect(falaAposJogada(elogioNivel: 0, semLimpar: 0, ocupadas: 20, jogadas: 8), isNull);
    });

    test('as dicas rodam sem repetir em sequência', () {
      final textos = {
        for (var j = 0; j < dicasDoMascote.length; j++)
          falaAposJogada(elogioNivel: 0, semLimpar: 5, ocupadas: 10, jogadas: j * 5)!.texto,
      };
      expect(textos.length, dicasDoMascote.length);
    });
  });

  group('ranking mundial', () {
    test('sem placar configurado nada é enviado nem aparece', () async {
      const r = SemRanking();
      expect(await r.disponivel(), isFalse);
      expect(await r.abrir(), isFalse);
    });

    testWidgets('o botão Ranking mundial só aparece com o placar configurado', (tester) async {
      telaDeCelular(tester, tamanho: const Size(360, 1400));
      final sem = await servicosDeTeste(ranking: _RankingFalso(pronto: false));
      await tester.pumpWidget(appDeTeste(sem));
      await tester.pumpAndSettle();
      expect(find.text('Ranking mundial'), findsNothing);
      await tester.pumpWidget(const SizedBox());

      final falso = _RankingFalso();
      final com = await servicosDeTeste(ranking: falso);
      await tester.pumpWidget(appDeTeste(com));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pump();
      expect(find.text('Ranking mundial'), findsOneWidget);
      await tester.tap(find.text('Ranking mundial'));
      await tester.pump();
      expect(falso.aberturas, 1);
    });
  });

  testWidgets('o mascote fala na partida (visual)', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaDeExemplo()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Mascote), findsOneWidget);
    final estado = tester.state<State<JogoTela>>(find.byType(JogoTela));
    (estado as dynamic).mascoteDizParaTeste('Fantástico! Uau!', Humor.uau);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fantástico! Uau!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await capturar(tester, '39-mascote-na-partida');
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fantástico! Uau!'), findsNothing, reason: 'o balão some sozinho');
  });

  testWidgets('em tela baixa o mascote some e o tabuleiro não encolhe nem estoura', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 560));
    final s = await servicosDeTeste();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: JogoTela(servicos: s, partida: partidaDeExemplo()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Mascote), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Partida expõe jogadas seguidas sem limpar linha', () {
    final p = Partida(semente: 3);
    expect(p.semLimpar, 0);
  });
}
