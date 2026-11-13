import 'dart:io';
import 'dart:ui' as ui;

import 'package:encaixa/app.dart';
import 'package:encaixa/servicos/anuncios.dart';
import 'package:encaixa/servicos/compras.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:encaixa/servicos/servicos.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Salva PNG só com `--dart-define=CAPTURAS=true` (veja docs/TELAS.md).
const salvarCapturas = bool.fromEnvironment('CAPTURAS');

final _raiz = GlobalKey();

/// Carrega a fonte do jogo e os ícones de verdade (sem isso o teste mostra caixinhas).
Future<void> carregarFontes() async {
  final fredoka = FontLoader('Fredoka')
    ..addFont(rootBundle.load('assets/fontes/Fredoka-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fontes/Fredoka-Bold.ttf'));
  await fredoka.load();
  final flutter = Platform.environment['FLUTTER_ROOT'];
  final icones = File('$flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icones.existsSync()) {
    final bytes = icones.readAsBytesSync();
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

Future<Servicos> servicosDeTeste({
  Map<String, Object> valores = const {},
  DateTime? hoje,
  bool dicas = false,
  bool roleta = false,
}) async {
  SharedPreferences.setMockInitialValues(valores);
  final progresso = await Progresso.carregar();
  return Servicos(
    progresso: progresso,
    anuncios: SemAnuncios(),
    compras: ComprasFicticias(progresso),
    hoje: () => hoje ?? DateTime(2026, 11, 12, 9),
    mostrarPresenteAoAbrir: false,
    mostrarDicas: dicas,
    roletaAposPartida: roleta,
  );
}

/// Tela de celular comum (360 x 780 dp, 3x).
void telaDeCelular(WidgetTester tester, {Size tamanho = const Size(360, 780), double fonte = 1}) {
  tester.view
    ..devicePixelRatio = 3
    ..physicalSize = tamanho * 3;
  tester.platformDispatcher.textScaleFactorTestValue = fonte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// O app inteiro, envolto para poder virar imagem.
Widget appDeTeste(Servicos servicos, {Widget? tela}) => RepaintBoundary(
  key: _raiz,
  child: tela == null
      ? EncaixaApp(servicos: servicos)
      : MaterialApp(debugShowCheckedModeBanner: false, theme: EncaixaApp.tema, home: tela),
);

Future<void> capturar(WidgetTester tester, String nome, {String pasta = '../docs/telas'}) async {
  if (!salvarCapturas) return;
  await tester.runAsync(() async {
    final caixa = _raiz.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagem = await caixa.toImage(pixelRatio: tester.view.devicePixelRatio);
    final png = await imagem.toByteData(format: ui.ImageByteFormat.png);
    File('$pasta/$nome.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}
