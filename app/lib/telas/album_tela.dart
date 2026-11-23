import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/album.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';

const _icones = <String, IconData>{
  'star': Icons.star_rounded,
  'moon': Icons.nightlight_round,
  'sun': Icons.wb_sunny_rounded,
  'bolt': Icons.bolt_rounded,
  'heart': Icons.favorite_rounded,
  'crown': Icons.workspace_premium_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'key': Icons.vpn_key_rounded,
  'diamond': Icons.diamond_rounded,
  'trophy': Icons.emoji_events_rounded,
  'flower': Icons.local_florist_rounded,
  'cloud': Icons.cloud_rounded,
  'leaf': Icons.eco_rounded,
  'drop': Icons.water_drop_rounded,
  'fire': Icons.local_fire_department_rounded,
  'snow': Icons.ac_unit_rounded,
  'mountain': Icons.terrain_rounded,
  'tree': Icons.park_rounded,
  'paw': Icons.pets_rounded,
  'bee': Icons.emoji_nature_rounded,
  'wind': Icons.air_rounded,
  'beach': Icons.beach_access_rounded,
  'grass': Icons.grass_rounded,
  'storm': Icons.thunderstorm_rounded,
};

IconData iconeDaFigurinha(Figurinha f) => _icones[f.icone] ?? Icons.star_rounded;

/// Mostra a figurinha que acabou de ser ganha (e o prêmio, se completou o álbum).
Future<void> mostrarFigurinhaNova(BuildContext context, ({Album album, Figurinha figurinha, bool completou}) ganhou) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.painel,
        scrollable: true,
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Figurinha nova!', textAlign: TextAlign.center),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 110, height: 140, child: _Figurinha(ganhou.figurinha, tenho: true)),
            const SizedBox(height: 10),
            Text(
              ganhou.completou
                  ? 'Álbum ${ganhou.album.nome} completo! +${ganhou.album.premioGemas} gemas'
                  : 'Álbum ${ganhou.album.nome}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: ganhou.completou ? Cores.gema : null),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Legal!'))],
      ),
    );

class AlbumTela extends StatefulWidget {
  const AlbumTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<AlbumTela> createState() => _AlbumTelaState();
}

class _AlbumTelaState extends State<AlbumTela> {
  Servicos get _s => widget.servicos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostrarDicaUmaVez(context, _s, Dicas.album);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoJogo(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _s.progresso,
          builder: (context, _) {
            final tenho = _s.progresso.figurinhas;
            final liberados = Album.liberados(tenho);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: TextoContornado('Álbum de figurinhas', tamanho: 24, alinhamento: TextAlign.start),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Text(
                    'Ganhe uma figurinha ao concluir o Desafio do dia e outra ao abrir o baú das missões. '
                    'Complete o álbum e leve gemas!',
                    style: TextStyle(fontSize: 14, height: 1.3),
                  ),
                ),
                for (final a in liberados) _SecaoAlbum(album: a, tenho: tenho),
                if (liberados.length < Album.todos.length)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Complete este álbum para liberar o próximo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Cores.textoFraco),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _SecaoAlbum extends StatelessWidget {
  const _SecaoAlbum({required this.album, required this.tenho});

  final Album album;
  final Set<String> tenho;

  @override
  Widget build(BuildContext context) {
    final quantas = album.quantas(tenho);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CartaoVidro(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextoContornado(album.nome, tamanho: 21, alinhamento: TextAlign.start)),
                Text(
                  '$quantas/${album.figurinhas.length}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: quantas / album.figurinhas.length,
                minHeight: 8,
                backgroundColor: Cores.casa,
                color: Cores.gema,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              album.completo(tenho) ? 'Completo!' : 'Completo: +${album.premioGemas} gemas',
              style: const TextStyle(fontSize: 13, color: Cores.textoFraco),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
              children: [for (final f in album.figurinhas) _Figurinha(f, tenho: tenho.contains(f.id))],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figurinha extends StatelessWidget {
  const _Figurinha(this.figurinha, {required this.tenho});

  final Figurinha figurinha;
  final bool tenho;

  @override
  Widget build(BuildContext context) {
    final cor = Color(figurinha.cor);
    return Semantics(
      label: tenho ? figurinha.nome : 'Figurinha ainda não conquistada',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: tenho ? null : Cores.casa,
          gradient: tenho
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cor.withValues(alpha: 0.95), Color.lerp(cor, Colors.black, 0.35)!],
                )
              : null,
          border: Border.all(color: tenho ? Colors.white.withValues(alpha: 0.5) : Colors.white12, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                child: Icon(
                  tenho ? iconeDaFigurinha(figurinha) : Icons.help_outline_rounded,
                  color: tenho ? Colors.white : Colors.white24,
                  shadows: tenho ? const [Shadow(color: Color(0x66000000), offset: Offset(0, 2))] : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tenho ? figurinha.nome : '???',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tenho ? null : Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
