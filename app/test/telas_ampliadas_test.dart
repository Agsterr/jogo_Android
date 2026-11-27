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
}
