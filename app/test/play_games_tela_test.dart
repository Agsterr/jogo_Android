import 'dart:typed_data';

import 'package:encaixa/servicos/copia_automatica.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:encaixa/telas/progresso_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

/// Play Games de mentira: [logado] é o nome da conta conectada (`null` = ainda sem conta).
class _PlayGamesFalso implements CopiaAutomatica, ContaDoJogador {
  _PlayGamesFalso({this.logado});

  String? logado;
  Uint8List? guardado;

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    guardado = bytes;
    return const ResultadoCopia(ok: true, nuvem: true);
  }

  @override
  Future<Uint8List?> ler() async => guardado;

  @override
  Future<String?> nome() async => logado;

  @override
  Future<bool> conectar() async {
    logado = 'Agster';
    return true;
  }
}

const _jogador = <String, Object>{'faseLiberada': 9, 'partidas': 12, 'recorde': 4200, 'gemas': 60};

/// Capturas da tela Salvar progresso com e sem a conta do Play Games.
/// Gere com: flutter test test/play_games_tela_test.dart --dart-define=CAPTURAS=true
void main() {
  setUpAll(carregarFontes);

  Future<void> abrir(WidgetTester tester, {String? conta}) async {
    final s = await servicosDeTeste(
      valores: _jogador,
      copia: _PlayGamesFalso(logado: conta),
    );
    await tester.pumpWidget(appDeTeste(s, tela: ProgressoTela(servicos: s)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('conectado: mostra a conta do Play Games', (tester) async {
    telaDeCelular(tester);
    await abrir(tester, conta: 'Agster');
    expect(find.text('Conectado ao Play Games'), findsOneWidget);
    expect(find.textContaining('Conta: Agster'), findsOneWidget);
    await capturar(tester, '60-play-games-conectado');
  });

  testWidgets('sem conta: pede para conectar e o botão conecta', (tester) async {
    telaDeCelular(tester);
    await abrir(tester);
    expect(find.text('Conecte ao Play Games'), findsOneWidget);
    expect(find.text('CONECTAR AO PLAY GAMES'), findsWidgets);
    await capturar(tester, '61-play-games-conectar');
    await tester.tap(find.text('CONECTAR AO PLAY GAMES').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Conectado ao Play Games'), findsOneWidget);
  });

  for (final (nome, conta) in [('conectado', 'Agster'), ('sem conta', null)]) {
    testWidgets('tela pequena (320x600) com fonte 1,3x: nada estoura ($nome)', (tester) async {
      telaDeCelular(tester, tamanho: const Size(320, 600), fonte: 1.3);
      await abrir(tester, conta: conta);
      expect(tester.takeException(), isNull);
      await capturar(tester, '62-play-games-${conta == null ? 'conectar' : 'conectado'}-pequena');
    });
  }

  testWidgets('fim da tela inicial (tela alta, para ver tudo até o fim)', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 1900));
    final s = await servicosDeTeste(
      valores: _jogador,
      copia: _PlayGamesFalso(logado: 'Agster'),
    );
    await tester.pumpWidget(appDeTeste(s, tela: InicioTela(servicos: s)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capturar(tester, '63-inicio-fim');
  });
}
