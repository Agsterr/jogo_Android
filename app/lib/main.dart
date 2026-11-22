import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'jogo/sorteio.dart';
import 'servicos/anuncios.dart';
import 'servicos/compras.dart';
import 'servicos/copia_automatica.dart';
import 'servicos/progresso.dart';
import 'servicos/servicos.dart';
import 'servicos/sons.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final progresso = await Progresso.carregar();
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  // Reinstalou? Recupera o progresso antes de mostrar a primeira tela (no máximo 3 s de espera).
  final automatico = SalvamentoAutomatico(progresso, android ? CopiaBlockStore() : const SemCopia());
  await automatico.recuperarSeVazio().timeout(const Duration(seconds: 3), onTimeout: () => false);
  automatico.iniciar();
  final servicos = Servicos(
    progresso: progresso,
    anuncios: android ? AnunciosAdMob() : SemAnuncios(),
    compras: android ? ComprasPlay(progresso) : ComprasFicticias(progresso),
    sons: SonsDoJogo(progresso),
    copia: automatico,
  );
  runApp(EncaixaApp(servicos: servicos));

  // Depois do primeiro quadro, para o jogo abrir rápido.
  await servicos.sons.iniciar();
  await servicos.compras.iniciar();
  await progresso.darBonusDoAssinante(Sorteio.sementeDoDia(DateTime.now()));
  await servicos.anuncios.iniciar();
}
