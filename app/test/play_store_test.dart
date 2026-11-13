import 'package:encaixa/app.dart';
import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/telas/arena_tela.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:encaixa/telas/jogo_tela.dart';
import 'package:encaixa/telas/loja_tela.dart';
import 'package:encaixa/telas/mapa_tela.dart';
import 'package:encaixa/telas/roda_tela.dart';
import 'package:encaixa/servicos/servicos.dart';
import 'package:encaixa/tema.dart';
import 'package:encaixa/widgets/doce.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';
import 'telas_test.dart' show dedoPara, partidaDeExemplo;

/// Imagens da ficha da Play Store (1080 x 1920): título grande + tela real do jogo num celular.
/// Gere com: flutter test test/play_store_test.dart --dart-define=CAPTURAS=true  (salva em docs/play-store)
const _pasta = '../docs/play-store';
const _celular = Size(360, 780);

void main() {
  setUpAll(carregarFontes);

  Future<Servicos> servicos() => servicosDeTeste(
    valores: {
      'recorde': 4820,
      'gemas': 248,
      'sequencia': 6,
      'desafioFeito': 20261111,
      'faseLiberada': 23,
      for (var n = 1; n < 23; n++) 'estrelas_$n': [3, 3, 2, 3][n % 4],
      'missoesDia': 20261112,
      'missao_linhas': 11,
      'missao_umaCor': 2,
      'missao_combo': 4,
      'missao_pontos': 1100,
      'missao_partidas': 2,
      'missao_limpo': 1,
      'arenaSemana': 20261109,
      'arenaMelhor': 3260,
      'arenaPremios': <String>['Bronze', 'Prata'],
    },
  );

  Future<void> vitrine(
    WidgetTester tester,
    String nome,
    String titulo,
    String subtitulo,
    Widget tela, {
    Future<void> Function()? antes,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(1080, 1920);
    addTearDown(tester.view.reset);
    final s = await servicos();
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: _Vitrine(titulo: titulo, subtitulo: subtitulo, tela: tela),
      ),
    );
    await tester.pump();
    await antes?.call();
    await capturar(tester, nome, pasta: _pasta);
  }

  testWidgets('1 jogar', (tester) async {
    final s = await servicos();
    final partida = partidaDeExemplo();
    await vitrine(
      tester,
      '1-encaixe',
      'Encaixe e limpe!',
      'Arraste os blocos e complete linhas',
      JogoTela(servicos: s, partida: partida),
    );
  });

  testWidgets('2 combo', (tester) async {
    final s = await servicos();
    final partida = partidaDeExemplo();
    await vitrine(
      tester,
      '2-combos',
      'Combos explosivos!',
      'Linhas seguidas multiplicam os pontos',
      JogoTela(servicos: s, partida: partida),
      antes: () async {
        final gesto = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('mao-0'))));
        await gesto.moveTo(dedoPara(tester, partida.mao[0]!, 6, 5));
        await tester.pump();
        await gesto.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 260));
      },
    );
    await tester.pumpAndSettle();
  });

  testWidgets('3 mapa', (tester) async {
    await vitrine(tester, '3-fases', '300 fases', '15 mundos para explorar', MapaTela(servicos: await servicos()));
  });

  testWidgets('4 pedras', (tester) async {
    await vitrine(
      tester,
      '4-desafios',
      'Desafios inteligentes',
      'Quebre pedras, faça combos, cumpra metas',
      JogoTela(servicos: await servicos(), fase: Fase.numero(121)),
    );
  });

  testWidgets('5 arena', (tester) async {
    await vitrine(
      tester,
      '5-arena',
      'Arena da semana',
      'Ganhe troféus e prêmios',
      ArenaTela(servicos: await servicos()),
    );
  });

  testWidgets('6 diario', (tester) async {
    await vitrine(
      tester,
      '6-todo-dia',
      'Novidades todo dia',
      'Missões, presentes e desafio diário',
      InicioTela(servicos: await servicos()),
    );
  });

  testWidgets('8 roleta', (tester) async {
    await vitrine(
      tester,
      '8-roleta',
      'Prêmios toda hora',
      'Roda da sorte diária e roleta após cada partida',
      RodaTela(servicos: await servicos()),
    );
  });

  testWidgets('7 temas', (tester) async {
    await vitrine(
      tester,
      '7-temas',
      'Cores que brilham',
      'Escolha o seu tema de blocos',
      LojaTela(servicos: await servicos()),
      antes: () async {
        await tester.scrollUntilVisible(find.text('Galáxia'), 300);
        await tester.pump();
      },
    );
  });
}

/// Fundo do jogo, título com contorno e a tela num celular.
class _Vitrine extends StatelessWidget {
  const _Vitrine({required this.titulo, required this.subtitulo, required this.tela});

  final String titulo, subtitulo;
  final Widget tela;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: FundoJogo(
      child: Column(
        children: [
          const SizedBox(height: 90),
          TextoContornado(titulo, tamanho: 92, contorno: const Color(0xFF1E0750)),
          const SizedBox(height: 14),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: fonteJogo,
              fontSize: 44,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xFF1E0750), offset: Offset(0, 3), blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 60),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _celular.width / _celular.height,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0420),
                    borderRadius: BorderRadius.circular(72),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Cores.brilhoRosa.withValues(alpha: 0.55),
                        blurRadius: 70,
                        offset: const Offset(-20, 0),
                      ),
                      BoxShadow(
                        color: Cores.brilhoCiano.withValues(alpha: 0.45),
                        blurRadius: 70,
                        offset: const Offset(20, 30),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(56),
                    child: FittedBox(
                      child: SizedBox.fromSize(
                        size: _celular,
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(size: _celular, padding: EdgeInsets.zero),
                          child: tela,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 70),
        ],
      ),
    ),
  );
}
