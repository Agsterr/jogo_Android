import 'dart:io';
import 'dart:ui';

import 'package:encaixa/idioma.dart';
import 'package:encaixa/idioma_textos.dart';
import 'package:encaixa/jogo/album.dart';
import 'package:encaixa/jogo/arena.dart';
import 'package:encaixa/jogo/bau.dart';
import 'package:encaixa/jogo/conquistas.dart';
import 'package:encaixa/jogo/eventos.dart';
import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/missoes.dart';
import 'package:encaixa/jogo/passe.dart';
import 'package:encaixa/jogo/temas.dart';
import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/widgets/dicas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

String _desescapar(String s) =>
    s.replaceAll(r"\'", "'").replaceAll(r'\$', r'$').replaceAll(r'\n', '\n').replaceAll(r'\\', r'\');

/// Textos escritos em português que NÃO são mostrados ao jogador: pedaços usados só para trocar palavras no código.
const _ignorar = {'línea', 'líneas'};

void main() {
  setUpAll(carregarFontes);
  tearDown(() => Idioma.atual = 'pt');

  final en = Textos.porIdioma['en']!;
  final es = Textos.porIdioma['es']!;

  List<String> marcadores(String s) => RegExp(r'\{\d*\}').allMatches(s).map((m) => m[0]!).toList()..sort();

  test('todo t(...) do código tem tradução em inglês e espanhol', () {
    final chamada = RegExp(r"""(?<![\w.])t\(\s*'((?:[^'\\]|\\.)*)'""");
    final faltando = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('idioma.dart') || f.path.endsWith('idioma_textos.dart')) {
        continue;
      }
      for (final m in chamada.allMatches(f.readAsStringSync())) {
        final pt = _desescapar(m[1]!);
        if (!en.containsKey(pt) || !es.containsKey(pt)) faltando.add('${f.path}: $pt');
      }
    }
    expect(faltando, isEmpty, reason: 'faltam traduções:\n${faltando.join('\n')}');
  });

  test('os textos que vêm de dados (dicas, conquistas, álbuns, temas...) também têm tradução', () {
    final pt = <String>{
      for (final d in Dicas.todas) ...[d.titulo, d.botao, ...d.linhas],
      for (final c in Conquista.todas) ...[c.nome, c.descricao],
      for (final a in Album.todos) ...[a.nome, for (final f in a.figurinhas) f.nome],
      for (final f in Faixa.values)
        if (f.nome.isNotEmpty) f.nome,
      for (final tema in TemaDeBlocos.todos) tema.nome,
      for (final e in eventos) e.nome,
      for (final o in Objetivo.values) o.modelo,
      for (final tipo in TipoMissao.values) tipo.modelo,
      for (final tr in Arena.trofeus) tr.nome,
      for (final i in ItensDeBau.todos) i.nome,
      for (final r in Raridade.values) r.nome,
      for (final c in Categoria.values) c.nome,
      'Perfeito!',
      'Fantástico!',
      'Incrível!',
      'Ótimo!',
      'Boa!',
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    };
    final faltando = [
      for (final s in pt)
        if (!en.containsKey(s) || !es.containsKey(s)) s,
    ];
    expect(faltando, isEmpty, reason: 'faltam traduções:\n${faltando.join('\n')}');
  });

  test('os marcadores {0}, {1}, {} e as quebras de linha são os mesmos em todos os idiomas', () {
    expect(en.keys.toSet(), es.keys.toSet(), reason: 'inglês e espanhol têm as mesmas chaves');
    for (final pt in en.keys) {
      expect(marcadores(en[pt]!), marcadores(pt), reason: 'inglês: $pt');
      expect(marcadores(es[pt]!), marcadores(pt), reason: 'espanhol: $pt');
      expect('\n'.allMatches(en[pt]!).length, '\n'.allMatches(pt).length, reason: 'quebras (en): $pt');
      expect('\n'.allMatches(es[pt]!).length, '\n'.allMatches(pt).length, reason: 'quebras (es): $pt');
    }
  });

  test('não sobrou tradução vazia nem esquecida em português', () {
    for (final pt in en.keys) {
      if (_ignorar.contains(pt)) continue;
      expect(en[pt]!.trim(), isNotEmpty, reason: pt);
      expect(es[pt]!.trim(), isNotEmpty, reason: pt);
    }
  });

  test('t() troca o idioma, preenche os marcadores e cai no português sem tradução', () {
    expect(t('Jogar de novo'), 'Jogar de novo');
    Idioma.atual = 'en';
    expect(t('Jogar de novo'), 'Play again');
    expect(t('Fase {0} concluída!', [7]), 'Stage 7 complete!');
    expect(t('Texto que ninguém traduziu'), 'Texto que ninguém traduziu');
    Idioma.atual = 'es';
    expect(t('Jogar de novo'), 'Jugar de nuevo');
    expect(t('{0} de {1} figurinhas', [5, 24]), '5 de 24 cromos');
    expect(t('Fase {0} concluída!', [7]), '¡Fase 7 completada!');
  });

  test('Missão e Fase falam no idioma escolhido, com o singular certo', () {
    final missao = Missao(TipoMissao.linhas, 15, 3);
    expect(missao.texto, 'Limpe 15 linhas');
    Idioma.atual = 'en';
    expect(missao.texto, 'Clear 15 lines');
    Idioma.atual = 'es';
    expect(missao.texto, 'Limpia 15 líneas');
    Idioma.atual = 'en';
    expect(nomeDoMes(202611), 'November');
    expect(Fase.numero(1).texto, isNotEmpty);
    Idioma.atual = 'es';
    expect(nomeDoMes(202611), 'noviembre');
  });

  test('"auto" segue o idioma do celular e cai no inglês se não houver o dele', () {
    final lista = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
    addTearDown(lista.clearLocaleTestValue);
    lista.localeTestValue = const Locale('pt', 'BR');
    expect(Idioma.resolver('auto'), 'pt');
    lista.localeTestValue = const Locale('es', 'MX');
    expect(Idioma.resolver('auto'), 'es');
    lista.localeTestValue = const Locale('de', 'DE');
    expect(Idioma.resolver('auto'), 'en', reason: 'alemão ainda não existe: inglês');
    lista.localeTestValue = const Locale('en', 'US');
    expect(Idioma.resolver(null), 'en');
    expect(Idioma.resolver('es'), 'es', reason: 'a escolha manual vale mais que o celular');
    expect(Idioma.resolver('xx'), 'en');
  });

  testWidgets('trocar o idioma na tela Como jogar refaz o texto e guarda a escolha', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 900));
    final s = await servicosDeTeste();
    await tester.pumpWidget(appDeTeste(s, tela: AjudaTela(servicos: s)));
    await tester.pump();
    expect(find.text('Símbolos nas peças'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pump();
    expect(s.progresso.idioma, 'en');
    expect(Idioma.atual, 'en');
    await tester.tap(find.text('Español'));
    await tester.pump();
    expect(s.progresso.idioma, 'es');
    await s.progresso.definirIdioma('pt');
    expect(Idioma.atual, 'pt');
  });
}
