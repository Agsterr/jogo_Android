import 'package:encaixa/jogo/album.dart';
import 'package:encaixa/jogo/missoes.dart';
import 'package:encaixa/telas/album_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'suporte/capturas.dart';

void main() {
  setUpAll(carregarFontes);

  test('os ids são únicos e os álbuns têm 12 figurinhas', () {
    final ids = [for (final a in Album.todos) ...a.figurinhas.map((f) => f.id)];
    expect(ids.toSet().length, ids.length);
    for (final a in Album.todos) {
      expect(a.figurinhas.length, 12);
    }
  });

  test('sortear nunca repete, é determinístico e só passa ao 2º álbum com o 1º completo', () {
    final tenho = <String>{};
    expect(Album.sortear(tenho, 5)?.figurinha.id, Album.sortear(tenho, 5)?.figurinha.id);
    for (var i = 0; i < 12; i++) {
      final s = Album.sortear(tenho, i * 17)!;
      expect(s.album.id, 'tesouros');
      expect(tenho.add(s.figurinha.id), isTrue, reason: 'não repete');
    }
    expect(Album.tesouros.completo(tenho), isTrue);
    expect(Album.sortear(tenho, 3)!.album.id, 'natureza');
    expect(Album.liberados(tenho).map((a) => a.id), ['tesouros', 'natureza']);
    expect(Album.liberados({}).map((a) => a.id), ['tesouros']);
    tenho.addAll(Album.natureza.figurinhas.map((f) => f.id));
    expect(Album.sortear(tenho, 1), isNull);
  });

  test('Desafio dá uma figurinha por dia (não repete no mesmo dia) e completar o álbum paga gemas', () async {
    final s = await servicosDeTeste(valores: {'gemas': 0});
    final p = s.progresso;
    await p.concluirDesafio(20261112, 100);
    expect(p.figurinhas.length, 1);
    expect(p.pegarFigurinhaRecente(), isNotNull);
    expect(p.pegarFigurinhaRecente(), isNull, reason: 'só aparece uma vez');
    await p.concluirDesafio(20261112, 300); // melhorou a pontuação: não é um novo dia
    expect(p.figurinhas.length, 1);
    await p.concluirDesafio(20261113, 100);
    expect(p.figurinhas.length, 2);

    final antes = p.gemas;
    for (var i = 0; i < 10; i++) {
      await p.ganharFigurinha(i);
    }
    expect(p.figurinhas.length, 12);
    final ultima = p.pegarFigurinhaRecente();
    expect(ultima!.completou, isTrue);
    expect(ultima.album.id, 'tesouros');
    expect(p.gemas, antes + Album.tesouros.premioGemas);
  });

  test('o baú das missões também dá figurinha (uma vez por dia)', () async {
    final s = await servicosDeTeste();
    final p = s.progresso;
    const dia = 20261112;
    for (final m in missoesDoDia(dia)) {
      await p.contarMissao(dia, m.tipo, m.alvo);
    }
    for (var i = 0; i < missoesPorDia; i++) {
      expect(await p.pegarMissao(dia, i), isTrue);
    }
    expect(p.figurinhas, isEmpty);
    expect(await p.abrirBau(dia), isTrue);
    expect(p.figurinhas.length, 1);
    expect(await p.abrirBau(dia), isFalse);
    expect(p.figurinhas.length, 1, reason: 'abrir de novo não dá outra');
  });

  testWidgets('tela do álbum com algumas figurinhas (e com fonte grande)', (tester) async {
    for (final (fonte, nome) in [(1.0, '26-album'), (1.5, '27-album-fonte-grande')]) {
      telaDeCelular(tester, tamanho: const Size(360, 800), fonte: fonte);
      final s = await servicosDeTeste(
        valores: {
          'figurinhas': ['estrela', 'lua', 'raio', 'coracao', 'diamante', 'nuvem', 'foguete'],
        },
      );
      await tester.pumpWidget(appDeTeste(s, tela: AlbumTela(servicos: s)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Estrela'), findsOneWidget);
      expect(find.text('7/12'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturar(tester, nome);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('figurinha nova: diálogo ao ganhar', (tester) async {
    telaDeCelular(tester, tamanho: const Size(360, 800));
    final s = await servicosDeTeste();
    final ganhou = await s.progresso.ganharFigurinha(1);
    await tester.pumpWidget(
      appDeTeste(
        s,
        tela: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => mostrarFigurinhaNova(context, ganhou!), child: const Text('abrir')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Figurinha nova!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capturar(tester, '28-figurinha-nova');
  });
}
