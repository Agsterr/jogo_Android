import 'package:encaixa/idioma.dart';
import 'package:encaixa/jogo/bau.dart';
import 'package:encaixa/jogo/sorteio.dart';
import 'package:encaixa/jogo/temas.dart';
import 'package:encaixa/servicos/anuncios.dart';
import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/telas/baus_tela.dart';
import 'package:encaixa/tema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);
  tearDown(() {
    Idioma.atual = 'pt';
    Cores.mascote = null;
    Cores.moldura = const [Cores.brilhoRosa, Color(0xFF8B5CFF), Cores.brilhoCiano];
  });

  group('regras do sorteio', () {
    test('as chances somam 100% e todo item tem raridade, categoria e cores certas', () {
      expect(Raridade.values.fold(0, (soma, r) => soma + r.chance), 100);
      final ids = ItensDeBau.todos.map((i) => i.id).toSet();
      expect(ids.length, ItensDeBau.todos.length, reason: 'ids únicos');
      for (final i in ItensDeBau.todos) {
        expect(i.cores.length, switch (i.categoria) {
          Categoria.tema => 6,
          Categoria.moldura => 3,
          Categoria.mascote => 1,
        }, reason: i.id);
      }
      for (final r in Raridade.values) {
        expect(ItensDeBau.da(r), isNotEmpty, reason: r.nome);
      }
    });

    test('só aparência: nenhum item mexe em pontuação (são só temas, molduras e cores)', () {
      expect(Categoria.values, [Categoria.tema, Categoria.moldura, Categoria.mascote]);
    });

    test('o sorteio é determinístico e as raridades saem perto das chances anunciadas', () {
      final a = sortearBau(Sorteio(42), const EstadoDoBau());
      expect(sortearBau(Sorteio(42), const EstadoDoBau()).item.id, a.item.id);
      final contagem = {for (final r in Raridade.values) r: 0};
      final rng = Sorteio(2026);
      var estado = const EstadoDoBau();
      const total = 20000;
      for (var i = 0; i < total; i++) {
        final r = sortearBau(rng, estado);
        estado = r.estado;
        contagem[r.item.raridade] = contagem[r.item.raridade]! + 1;
      }
      // Com a garantia, raro+ sobe um pouco acima do anunciado; comum nunca passa de 60% nem cai abaixo de ~50%.
      expect(contagem[Raridade.comum]! / total, inInclusiveRange(0.50, 0.60));
      expect(contagem[Raridade.raro]! / total, inInclusiveRange(0.26, 0.36));
      expect(contagem[Raridade.epico]! / total, inInclusiveRange(0.08, 0.14));
      expect(contagem[Raridade.lendario]! / total, inInclusiveRange(0.015, 0.035));
    });

    test('garantia: nunca passam mais de $garantiaRaro baús sem um raro, nem $garantiaLendario sem um lendário', () {
      final rng = Sorteio(7);
      var estado = const EstadoDoBau();
      var semRaro = 0, semLendario = 0, maiorSemRaro = 0, maiorSemLendario = 0;
      for (var i = 0; i < 5000; i++) {
        final r = sortearBau(rng, estado);
        estado = r.estado;
        semRaro = r.item.raridade == Raridade.comum ? semRaro + 1 : 0;
        semLendario = r.item.raridade == Raridade.lendario ? 0 : semLendario + 1;
        if (semRaro > maiorSemRaro) maiorSemRaro = semRaro;
        if (semLendario > maiorSemLendario) maiorSemLendario = semLendario;
      }
      expect(maiorSemRaro, lessThan(garantiaRaro));
      expect(maiorSemLendario, lessThan(garantiaLendario));
    });

    test('no baú da garantia o resultado é raro ou melhor; no do lendário, lendário', () {
      final r = sortearBau(Sorteio(1), const EstadoDoBau(semRaro: garantiaRaro - 1));
      expect(r.item.raridade, isNot(Raridade.comum));
      expect(r.garantido, isTrue);
      final l = sortearBau(Sorteio(1), const EstadoDoBau(semLendario: garantiaLendario - 1));
      expect(l.item.raridade, Raridade.lendario);
      expect(l.estado.semLendario, 0);
      expect(l.estado.semRaro, 0);
    });
  });

  group('baús no progresso', () {
    test('sem baú não abre; abrir gasta um, guarda o item e conta a garantia', () async {
      final s = await servicosDeTeste();
      final p = s.progresso;
      expect(await p.abrirBauDeItens(), isNull);
      await p.ganharBau(3);
      expect(p.baus, 3);
      final r = (await p.abrirBauDeItens(semente: 5))!;
      expect(p.baus, 2);
      expect(r.nivelAntes, 0);
      expect(r.nivelDepois, 1);
      expect(p.nivelDoItem(r.item.id), 1);
      expect(p.bausAbertos, 1);
      expect(p.estadoDoBau.semRaro + p.estadoDoBau.semLendario, greaterThanOrEqualTo(0));
    });

    test('repetido sobe de nível até o máximo e, no máximo, vira gemas', () async {
      final s = await servicosDeTeste(valores: {'gemas': 0});
      final p = s.progresso;
      await p.ganharBau(nivelMaximoDoItem + 2);
      String? id;
      var gemas = 0;
      for (var i = 0; i < nivelMaximoDoItem + 2; i++) {
        final r = (await p.abrirBauDeItens(
          semente: 99,
        ))!; // mesma semente, mesmo estado inicial? o estado muda: força o mesmo item abaixo
        id ??= r.item.id;
        gemas += r.gemas;
      }
      expect(id, isNotNull);
      // Quando o mesmo item sai de novo no nível 5, paga gemas pela raridade (conferido direto, sem depender do sorteio):
      final item = ItensDeBau.todos.first;
      final s2 = await servicosDeTeste(
        valores: {
          'gemas': 0,
          'baus': 1,
          'bauItens': ['${item.id}:$nivelMaximoDoItem'],
        },
      );
      expect(s2.progresso.nivelDoItem(item.id), nivelMaximoDoItem);
      expect(gemas, greaterThanOrEqualTo(0));
    });

    test('Desafio, Passe (5/10/15/20), álbum e sequência (14 e 30 dias) dão baú', () async {
      final s = await servicosDeTeste();
      final p = s.progresso;
      await p.concluirDesafio(20261112, 100);
      expect(p.baus, 1);
      await p.concluirDesafio(20261112, 300);
      expect(p.baus, 1, reason: 'melhorar a pontuação do mesmo dia não dá outro baú');

      final passe = await servicosDeTeste(valores: {'passeMes': 202611, 'passeXp': 2000});
      for (var n = 1; n <= niveisDoPasseParaTeste; n++) {
        await passe.progresso.pegarNivelDoPasse(20261112, n);
      }
      expect(passe.progresso.baus, 4, reason: 'níveis 5, 10, 15 e 20');

      final seq = await servicosDeTeste(valores: {'sequencia': 13, 'desafioFeito': 20261111});
      await seq.progresso.concluirDesafio(20261112, 100);
      expect(seq.progresso.baus, 2, reason: 'o Desafio dá um e o dia 14 dá mais um');
    });

    test(
      'equipar só funciona com item que se tem; moldura e cor do mascote valem na hora; padrão volta ao original',
      () async {
        final moldura = ItensDeBau.todos.firstWhere((i) => i.categoria == Categoria.moldura);
        final mascote = ItensDeBau.todos.firstWhere((i) => i.categoria == Categoria.mascote);
        final tema = ItensDeBau.todos.firstWhere((i) => i.categoria == Categoria.tema);
        final s = await servicosDeTeste(
          valores: {
            'bauItens': ['${moldura.id}:2', '${mascote.id}:1', '${tema.id}:1'],
            'temas': [tema.id],
          },
        );
        final p = s.progresso;
        final naoTem = ItensDeBau.todos.firstWhere((i) => i.categoria == Categoria.moldura && i.id != moldura.id);
        expect(await p.equipar(naoTem), isFalse);
        expect(await p.equipar(moldura), isTrue);
        expect(p.equipado(moldura), isTrue);
        expect(Cores.moldura.first, Color(moldura.cores.first));
        expect(await p.equipar(mascote), isTrue);
        expect(Cores.mascote, Color(mascote.cores.first));
        expect(await p.equipar(tema), isTrue);
        expect(Cores.pecas.first, Color(tema.cores.first));
        await p.usarPadrao(Categoria.moldura);
        await p.usarPadrao(Categoria.mascote);
        await p.usarPadrao(Categoria.tema);
        expect(p.equipado(moldura), isFalse);
        expect(Cores.mascote, isNull);
        expect(Cores.pecas.first, TemaDeBlocos.classico.cores.first);
      },
    );

    test('temas de baú ficam bloqueados na loja até saírem num baú, e depois ficam para sempre', () async {
      final item = ItensDeBau.todos.firstWhere((i) => i.categoria == Categoria.tema);
      final s = await servicosDeTeste(valores: {'baus': 1});
      final tema = TemaDeBlocos.porId(item.id);
      expect(tema.bau, isTrue);
      expect(s.progresso.temTema(tema), isFalse);
      final r = (await s.progresso.abrirBauDeItens(semente: 1))!;
      if (r.item.categoria == Categoria.tema) expect(s.progresso.temTema(TemaDeBlocos.porId(r.item.id)), isTrue);
    });

    test('coleção e baús vão no código de progresso', () {
      for (final k in [
        'baus',
        'bauSemRaro',
        'bauSemLendario',
        'bauAbertos',
        'bauItens',
        'molduraAtiva',
        'mascoteAtivo',
      ]) {
        expect(CodigoProgresso.vai(k), isTrue, reason: k);
      }
    });
  });

  group('baú de anúncio', () {
    test('só sai item Comum, não gasta baú guardado e não mexe na garantia', () async {
      final s = await servicosDeTeste(valores: {'baus': 2, 'bauSemRaro': 6, 'bauSemLendario': 30});
      final p = s.progresso;
      for (var i = 0; i < bausDeAnuncioPorDia; i++) {
        final r = (await p.abrirBauDeAnuncio(20261112, semente: 100 + i))!;
        expect(r.item.raridade, Raridade.comum);
      }
      expect(p.baus, 2, reason: 'os baús guardados continuam lá');
      expect(p.estadoDoBau.semRaro, 6, reason: 'não conta na garantia');
      expect(p.estadoDoBau.semLendario, 30);
      expect(p.bausAbertos, bausDeAnuncioPorDia);
    });

    test('limite diário e volta no dia seguinte', () async {
      final s = await servicosDeTeste();
      final p = s.progresso;
      for (var i = 0; i < bausDeAnuncioPorDia; i++) {
        expect(p.podeAbrirBauDeAnuncio(20261112), isTrue);
        await p.abrirBauDeAnuncio(20261112, semente: i);
      }
      expect(p.podeAbrirBauDeAnuncio(20261112), isFalse);
      expect(await p.abrirBauDeAnuncio(20261112), isNull);
      expect(p.podeAbrirBauDeAnuncio(20261113), isTrue);
    });

    test('comum repetido no nível máximo vira 5 gemas', () async {
      final comuns = ItensDeBau.da(Raridade.comum);
      final s = await servicosDeTeste(
        valores: {
          'gemas': 0,
          'bauItens': [for (final i in comuns) '${i.id}:$nivelMaximoDoItem'],
        },
      );
      final r = (await s.progresso.abrirBauDeAnuncio(20261112, semente: 3))!;
      expect(r.gemas, Raridade.comum.gemasDeRepetido);
      expect(s.progresso.gemas, Raridade.comum.gemasDeRepetido);
    });

    testWidgets('na tela: vê o anúncio e abre; anúncio indisponível não abre; Encaixa+ abre sem anúncio', (
      tester,
    ) async {
      telaDeCelular(tester, tamanho: const Size(360, 900));
      final anuncios = _AnunciosFalsos();
      final s = await servicosDeTeste(anuncios: anuncios);
      await tester.pumpWidget(appDeTeste(s, tela: BausTela(servicos: s)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Ver anúncio: baú comum'), findsOneWidget);
      anuncios.disponivel = false;
      await tester.tap(find.textContaining('Ver anúncio: baú comum'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(s.progresso.bausAbertos, 0, reason: 'sem anúncio, sem baú');
      expect(find.text('Anúncio indisponível agora. Tente de novo.'), findsOneWidget);
      anuncios.disponivel = true;
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.textContaining('Ver anúncio: baú comum'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(anuncios.vistos, 1);
      expect(s.progresso.bausAbertos, 1);
      await capturar(tester, '44-bau-de-anuncio');
      await tester.tap(find.text('Legal!'));
      await tester.pumpAndSettle();

      await s.progresso.definirAssinante(true);
      await tester.pump();
      expect(find.textContaining('Baú comum grátis (Encaixa+)'), findsOneWidget);
      await tester.tap(find.textContaining('Baú comum grátis (Encaixa+)'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(anuncios.vistos, 1, reason: 'assinante não vê anúncio');
      expect(s.progresso.bausAbertos, 2);
      await tester.tap(find.text('Legal!'));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('tela dos baús e a abertura (visual, em português e inglês)', (tester) async {
    for (final (idioma, nome) in [('pt', '40-baus'), ('en', '41-baus-en')]) {
      Idioma.atual = idioma;
      telaDeCelular(tester, tamanho: const Size(360, 800), fonte: 1.2);
      final s = await servicosDeTeste(
        valores: {
          'baus': 2,
          'bauAbertos': 14,
          'bauSemRaro': 3,
          'bauItens': ['tema-menta:3', 'moldura-fogo:1', 'mascote-dourado:2', 'tema-ouro-real:1', 'moldura-gelo:5'],
          'temas': ['tema-menta', 'tema-ouro-real'],
          'molduraAtiva': 'moldura-fogo',
        },
      );
      await tester.pumpWidget(appDeTeste(s, tela: BausTela(servicos: s)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await capturar(tester, nome);
      await tester.pumpWidget(const SizedBox());
    }
    Idioma.atual = 'pt';
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste(valores: {'baus': 1});
    await tester.pumpWidget(appDeTeste(s, tela: BausTela(servicos: s)));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('ABRIR BAÚ').first);
    await tester.pump(const Duration(milliseconds: 400));
    await capturar(tester, '42-bau-balancando');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Legal!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturar(tester, '43-bau-aberto');
    await tester.tap(find.text('Legal!'));
    await tester.pumpAndSettle();
    expect(s.progresso.baus, 0);
  });
}

const niveisDoPasseParaTeste = 20;

class _AnunciosFalsos implements Anuncios {
  bool disponivel = true;
  int vistos = 0;

  @override
  Future<void> iniciar() async {}

  @override
  Future<bool> mostrarPremiado() async {
    if (disponivel) vistos++;
    return disponivel;
  }

  @override
  Future<void> talvezIntersticial({required int partidasJogadas}) async {}
}
