import 'dart:io';

import 'package:encaixa/jogo/elogios.dart';
import 'package:encaixa/jogo/marcos.dart';
import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/jogo/robo.dart';
import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/servicos/sons.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show dedoPara, partidaDeExemplo;

Jogada _jogada({int linhas = 1, int combo = 1, bool limpo = false}) => Jogada(
  pontos: 10,
  linhasLimpas: linhas,
  linhasDeUmaCor: 0,
  combo: linhas > 0 ? combo : 0,
  tabuleiroLimpo: limpo,
  removidos: const [],
);

final _um = Formato.desenho(['#']);

void main() {
  setUpAll(carregarFontes);

  group('elogios', () {
    test('quanto mais forte a jogada, maior o elogio', () {
      expect(elogioDaJogada(_jogada(linhas: 0)), isNull);
      expect(elogioDaJogada(_jogada())!.texto, 'Boa!');
      expect(elogioDaJogada(_jogada(linhas: 2))!.texto, 'Ótimo!');
      expect(elogioDaJogada(_jogada(combo: 2))!.texto, 'Ótimo!', reason: '1 linha no combo x2');
      expect(elogioDaJogada(_jogada(linhas: 4))!.texto, 'Incrível!');
      expect(elogioDaJogada(_jogada(linhas: 2, combo: 3))!.texto, 'Incrível!');
      expect(elogioDaJogada(_jogada(linhas: 4, combo: 3))!.texto, 'Fantástico!');
      expect(elogioDaJogada(_jogada(limpo: true))!.texto, 'Perfeito!');
    });

    test('os níveis vão de 1 a 5 e nunca descem quando a jogada melhora', () {
      var anterior = 0;
      for (final j in [
        _jogada(),
        _jogada(linhas: 2),
        _jogada(linhas: 4),
        _jogada(linhas: 4, combo: 3),
        _jogada(limpo: true),
      ]) {
        final n = elogioDaJogada(j)!.nivel;
        expect(n, greaterThan(anterior));
        anterior = n;
      }
    });

    test('todo som usado tem o arquivo de áudio (senão o jogo falha ao carregar os sons)', () {
      for (final som in Som.values) {
        expect(File('assets/sons/${som.name}.wav').existsSync(), isTrue, reason: 'falta assets/sons/${som.name}.wav');
      }
    });
  });

  group('metas de pontos', () {
    test('metas, próxima meta e formato do número', () {
      expect(Marcos.novas(999, 0), isEmpty);
      expect(Marcos.novas(1000, 0).map((m) => m.pontos), [1000]);
      expect(Marcos.novas(6000, 0).map((m) => m.pontos), [1000, 2500, 5000], reason: 'várias de uma vez');
      expect(Marcos.novas(6000, 2).map((m) => m.pontos), [5000], reason: 'as pagas não repetem');
      expect(Marcos.proximo(0)!.pontos, 1000);
      expect(Marcos.proximo(Marcos.todos.length), isNull);
      expect(
        [Marcos.formatar(500), Marcos.formatar(1000), Marcos.formatar(40000), Marcos.formatar(1234567)],
        ['500', '1.000', '40.000', '1.234.567'],
      );
    });

    test('a meta é paga uma vez só, mesmo desfazendo e jogando de novo', () {
      final p = Partida(semente: 3)
        ..rampa = true
        ..pontos =
            999 // 1 bloco colocado = 1 ponto: passa de 1.000
        ..mao = [Peca(_um, 0), Peca(_um, 1), Peca(_um, 2)];
      final j = p.colocar(0, 4, 4)!;
      expect(j.marcos.map((m) => m.pontos), [1000]);
      expect(p.marcosPagos, 1);
      expect(p.nivel, 1);
      expect(p.desfazer(), isTrue);
      expect(p.pontos, 999);
      expect(p.colocar(0, 4, 4)!.marcos, isEmpty, reason: 'já foi paga');
      expect(p.marcosPagos, 1);
    });

    test('só o Infinito (rampa ligada) tem metas', () {
      final p = Partida(semente: 3)
        ..pontos = 9990
        ..mao = [Peca(_um, 0), null, null];
      expect(p.colocar(0, 0, 0)!.marcos, isEmpty);
      expect(p.nivel, 0);
    });

    test('a partida salva guarda as metas; partida antiga não paga o que já passou', () {
      final p = Partida(semente: 3)
        ..rampa = true
        ..pontos = 2600
        ..marcosPagos = 2;
      final volta = Partida.deJson(p.paraJson());
      expect((volta.rampa, volta.marcosPagos), (true, 2));
      final antiga = p.paraJson()
        ..remove('marcosPagos')
        ..remove('rampa');
      final deAntes = Partida.deJson(antiga);
      expect(deAntes.rampa, isFalse);
      expect(deAntes.marcosPagos, 2, reason: '1.000 e 2.500 já tinham passado: sem pagamento retroativo');
    });
  });

  group('dificuldade que sobe', () {
    double tamanhoMedio(int nivel) {
      final s = Sorteio(77);
      var total = 0;
      const n = 3000;
      for (var i = 0; i < n; i++) {
        total += Peca.sortear(s, totalCores, nivel).formato.celulas.length;
      }
      return total / n;
    }

    test('cada nível deixa as peças maiores', () {
      final medias = [for (var n = 0; n <= 4; n++) tamanhoMedio(n)];
      for (var n = 1; n < medias.length; n++) {
        expect(medias[n], greaterThan(medias[n - 1]), reason: 'nível $n: ${medias.map((m) => m.toStringAsFixed(2))}');
      }
    });

    test('nível 0 sorteia exatamente como antes (fases, Desafio e Arena não mudam)', () {
      for (var semente = 1; semente <= 5; semente++) {
        final a = Sorteio(semente), b = Sorteio(semente);
        for (var i = 0; i < 100; i++) {
          final x = Peca.sortear(a), y = Peca.sortear(b, totalCores, 0);
          expect((Formato.todos.indexOf(x.formato), x.cor), (Formato.todos.indexOf(y.formato), y.cor));
        }
      }
    });

    test('mesmo no nível mais alto a mão sempre tem uma peça que cabe, e o robô joga até o fim sem erro', () {
      final p = Partida(semente: 11)
        ..rampa = true
        ..marcosPagos = Marcos.nivelMaximoDasPecas;
      p.trocarMao();
      var jogadas = 0;
      while (!p.fimDeJogo && jogadas < 400 && Robo.jogar(p)) {
        jogadas++;
      }
      expect(jogadas, greaterThan(5));
      expect(p.marcosPagos, greaterThanOrEqualTo(Marcos.nivelMaximoDasPecas));
    });
  });

  group('na tela do Infinito', () {
    testWidgets('mostra o nível e a próxima meta; passar da meta dá gemas e avisa o nível', (tester) async {
      telaDeCelular(tester);
      final s = await servicosDeTeste(valores: {'gemas': 10, 'recorde': 5000});
      final partida = partidaDeExemplo()
        ..rampa = true
        ..pontos = 998;
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: JogoTela(servicos: s, partida: partida),
        ),
      );
      await tester.pump();
      expect(find.text('Nível 1'), findsOneWidget);
      expect(find.textContaining('Meta 1.000 · +3'), findsOneWidget);
      await capturar(tester, '33-infinito-meta');

      final peca = partida.mao[0]!; // ### = 3 blocos: 998 + 3 = 1001
      final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
      await gesto.moveTo(dedoPara(tester, peca, 0, 0));
      await tester.pump();
      await gesto.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Meta 1.000!'), findsWidgets);
      expect(find.textContaining('Nível 2: peças maiores'), findsWidgets);
      expect(s.progresso.gemas, 13);
      expect(find.text('Nível 2'), findsOneWidget);
      await capturar(tester, '34-infinito-meta-alcancada');
      await tester.pumpAndSettle();
    });

    testWidgets('limpar 4 linhas de uma vez mostra "Incrível!"', (tester) async {
      telaDeCelular(tester);
      final s = await servicosDeTeste();
      final partida = Partida(semente: 2)..rampa = true;
      for (var l = 0; l < 4; l++) {
        for (var k = 0; k < 7; k++) {
          partida.tabuleiro.definir(l, k, (l + k) % 6);
        }
      }
      partida.tabuleiro.definir(7, 0, 3); // sobra um bloco: se esvaziasse tudo, seria "Perfeito!"
      partida.mao = [
        Peca(Formato.desenho(['#', '#', '#', '#']), 2),
        Peca(_um, 1),
        null,
      ];
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: JogoTela(servicos: s, partida: partida),
        ),
      );
      await tester.pump();
      final peca = partida.mao[0]!;
      final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
      await gesto.moveTo(dedoPara(tester, peca, 0, 7));
      await tester.pump();
      await gesto.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Incrível!'), findsWidgets);
      await capturar(tester, '35-elogio-incrivel');
      await tester.pumpAndSettle();
    });

    testWidgets('Desafio e Arena não têm metas nem nível', (tester) async {
      telaDeCelular(tester);
      final s = await servicosDeTeste();
      await tester.pumpWidget(appDeTeste(s, tela: JogoTela(servicos: s, diario: true)));
      await tester.pump();
      expect(find.textContaining('Nível'), findsNothing);
      expect(find.textContaining('Meta '), findsNothing);
    });

    testWidgets('o Infinito novo já começa com nível e meta', (tester) async {
      telaDeCelular(tester);
      final s = await servicosDeTeste();
      await tester.pumpWidget(appDeTeste(s, tela: JogoTela(servicos: s)));
      await tester.pump();
      expect(find.text('Nível 1'), findsOneWidget);
    });
  });
}
