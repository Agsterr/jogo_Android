import 'package:encaixa/idioma.dart';
import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/telas/album_tela.dart';
import 'package:encaixa/telas/arena_tela.dart';
import 'package:encaixa/telas/conquistas_tela.dart';
import 'package:encaixa/telas/mapa_tela.dart';
import 'package:encaixa/telas/progresso_tela.dart';
import 'package:encaixa/telas/roda_tela.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/telas/loja_tela.dart';
import 'package:encaixa/telas/passe_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show partidaDeExemplo, partidaSemEspaco;

/// As telas principais em inglês e espanhol, com a fonte do sistema grande (1,3x), sem estouro de layout.
void main() {
  setUpAll(carregarFontes);
  tearDown(() => Idioma.atual = 'pt');

  for (final idioma in ['en', 'es']) {
    group('telas em $idioma', () {
      Future<void> abrir(
        WidgetTester tester,
        Widget Function(dynamic s) tela,
        String nome, {
        Map<String, Object>? valores,
      }) async {
        Idioma.atual = idioma;
        telaDeCelular(tester, tamanho: const Size(360, 800), fonte: 1.3);
        final s = await servicosDeTeste(valores: valores ?? const {});
        await tester.pumpWidget(appDeTeste(s, tela: tela(s)));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: nome);
        await capturar(tester, 'idioma-$idioma-$nome');
      }

      testWidgets('início', (tester) async {
        Idioma.atual = idioma;
        telaDeCelular(tester, tamanho: const Size(360, 800), fonte: 1.3);
        final s = await servicosDeTeste(
          hoje: DateTime(2026, 11, 12, 20),
          valores: {'sequencia': 5, 'desafioFeito': 20261111, 'faseLiberada': 14},
        );
        await tester.pumpWidget(appDeTeste(s));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await capturar(tester, 'idioma-$idioma-inicio');
        await tester.drag(find.byType(ListView).first, const Offset(0, -900));
        await tester.pump();
        expect(tester.takeException(), isNull);
        await capturar(tester, 'idioma-$idioma-inicio-2');
      });

      testWidgets('partida', (tester) async {
        await abrir(tester, (s) => JogoTela(servicos: s, partida: partidaDeExemplo()), 'partida');
      });

      testWidgets('fim de partida', (tester) async {
        await abrir(tester, (s) => JogoTela(servicos: s, partida: partidaSemEspaco()), 'fim');
      });

      testWidgets('passe', (tester) async {
        await abrir(tester, (s) => PasseTela(servicos: s), 'passe', valores: {'passeMes': 202611, 'passeXp': 740});
      });

      testWidgets('conquistas', (tester) async {
        await abrir(
          tester,
          (s) => ConquistasTela(servicos: s),
          'conquistas',
          valores: {'partidas': 60, 'recorde': 5400},
        );
      });

      testWidgets('roda da sorte', (tester) async {
        await abrir(tester, (s) => RodaTela(servicos: s), 'roda');
      });

      testWidgets('arena', (tester) async {
        await abrir(
          tester,
          (s) => ArenaTela(servicos: s),
          'arena',
          valores: {'arenaSemana': 20261109, 'arenaMelhor': 3260},
        );
      });

      testWidgets('mapa', (tester) async {
        await abrir(tester, (s) => MapaTela(servicos: s), 'mapa', valores: {'faseLiberada': 23});
      });

      testWidgets('salvar progresso', (tester) async {
        await abrir(tester, (s) => ProgressoTela(servicos: s), 'progresso');
      });

      testWidgets('como jogar', (tester) async {
        await abrir(tester, (s) => AjudaTela(servicos: s), 'ajuda');
      });

      testWidgets('álbum', (tester) async {
        await abrir(
          tester,
          (s) => AlbumTela(servicos: s),
          'album',
          valores: {
            'figurinhas': ['estrela', 'lua'],
          },
        );
      });

      testWidgets('partida de fase com pedras', (tester) async {
        await abrir(tester, (s) => JogoTela(servicos: s, fase: Fase.numero(121)), 'fase');
      });

      testWidgets('desafio e arena', (tester) async {
        await abrir(tester, (s) => JogoTela(servicos: s, diario: true), 'desafio');
      });

      testWidgets('loja', (tester) async {
        await abrir(tester, (s) => LojaTela(servicos: s), 'loja');
      });
    });
  }
}
