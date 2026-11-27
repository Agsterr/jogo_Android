import 'package:encaixa/telas/ajuda_tela.dart';
import 'package:encaixa/telas/album_tela.dart';
import 'package:encaixa/telas/arena_tela.dart';
import 'package:encaixa/telas/baus_tela.dart';
import 'package:encaixa/telas/conquistas_tela.dart';
import 'package:encaixa/telas/estatisticas_tela.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:encaixa/telas/loja_tela.dart';
import 'package:encaixa/telas/mapa_tela.dart';
import 'package:encaixa/telas/passe_tela.dart';
import 'package:encaixa/telas/progresso_tela.dart';
import 'package:encaixa/telas/roda_tela.dart';
import 'package:encaixa/telas/roleta_partida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// Celular com "tamanho da tela" ampliado e fonte grande: só uns 280 dp de largura útil. As telas não podem estourar
/// nem quebrar palavra no meio. Pasta das imagens: `--dart-define=AMPLIADAS=<pasta>` (padrão: `docs/telas/ampliadas`).
const _pasta = String.fromEnvironment('AMPLIADAS', defaultValue: '../docs/telas/ampliadas');

void main() {
  setUpAll(carregarFontes);

  final telas = <String, Widget Function(dynamic s)>{
    'inicio': (s) => InicioTela(servicos: s),
    'passe': (s) => PasseTela(servicos: s),
    'conquistas': (s) => ConquistasTela(servicos: s),
    'baus': (s) => BausTela(servicos: s),
    'estatisticas': (s) => EstatisticasTela(servicos: s),
    'mapa': (s) => MapaTela(servicos: s),
    'arena': (s) => ArenaTela(servicos: s),
    'album': (s) => AlbumTela(servicos: s),
    'ajuda': (s) => AjudaTela(servicos: s),
    'progresso': (s) => ProgressoTela(servicos: s),
    'roda': (s) => RodaTela(servicos: s),
    'loja': (s) => LojaTela(servicos: s),
  };

  for (final MapEntry(key: nome, value: tela) in telas.entries) {
    testWidgets('tela ampliada: $nome', (tester) async {
      telaDeCelular(tester, tamanho: const Size(280, 600), fonte: 1.3);
      final s = await servicosDeTeste(valores: const {'gemas': 120, 'faseLiberada': 9, 'partidas': 8});
      await tester.pumpWidget(appDeTeste(s, tela: tela(s)));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await capturar(tester, nome, pasta: _pasta);
      expect(tester.takeException(), isNull, reason: nome);
    });
  }

  // Diálogo da roleta em tela baixa, com a barra de navegação do Android: os botões de baixo não podem ficar cobertos.
  for (final (nome, tamanho, fonte) in [
    ('roleta-360x640', const Size(360, 640), 1.0),
    ('roleta-360x560-fonte-1-3', const Size(360, 560), 1.3),
    ('roleta-280x600', const Size(280, 600), 1.3),
  ]) {
    testWidgets('roleta da partida cabe na tela: $nome', (tester) async {
      telaDeCelular(tester, tamanho: tamanho, fonte: fonte);
      tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 144); // 24 dp em cima e 48 dp embaixo
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final s = await servicosDeTeste(valores: const {'gemas': 10});
      await tester.pumpWidget(
        appDeTeste(
          s,
          tela: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => RoletaDaPartida(servicos: s, semente: 7),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('GIRAR'), findsWidgets);
      final fundoDoTexto = tester.getBottomLeft(find.text('Agora não')).dy;
      expect(fundoDoTexto, lessThanOrEqualTo(tamanho.height - 48), reason: 'texto sob a barra do sistema');
      await capturar(tester, nome, pasta: _pasta);
      expect(tester.takeException(), isNull);
    });
  }
}
