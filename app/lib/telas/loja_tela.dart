import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../jogo/eventos.dart';
import '../jogo/sorteio.dart';
import '../jogo/temas.dart';
import '../servicos/compras.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/peca_widget.dart';

class LojaTela extends StatelessWidget {
  const LojaTela({super.key, required this.servicos});

  final Servicos servicos;

  static const gemasPorAnuncio = 5;

  /// Para não desvalorizar os pacotes nem cansar o inventário do AdMob.
  static const premiadosPorDia = 5;

  int get _dia => Sorteio.sementeDoDia(servicos.hoje());

  Future<void> _gemasComAnuncio(BuildContext context) async {
    final ganhou = await servicos.anuncios.mostrarPremiado();
    if (ganhou) {
      await servicos.progresso.registrarPremiado(_dia);
      await servicos.progresso.ganharGemas(gemasPorAnuncio);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Anúncio indisponível agora. Tente de novo.')));
    }
  }

  Future<void> _escolherTema(BuildContext context, TemaDeBlocos t) async {
    final p = servicos.progresso;
    final evento = eventoAtivo(servicos.hoje())?.id;
    if (p.temTema(t, eventoAtivo: evento)) {
      if (t.evento != null) await p.guardarTema(t);
      return p.usarTema(t);
    }
    if (await p.comprarTema(t)) return p.usarTema(t);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gemas insuficientes.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso, compras = servicos.compras;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loja', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Cores.fundoTopo,
        actions: [
          ListenableBuilder(
            listenable: p,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: GemasChip(gemas: p.gemas)),
            ),
          ),
        ],
      ),
      body: FundoJogo(
        child: ListenableBuilder(
          listenable: Listenable.merge([p, compras]),
          builder: (context, _) {
            String preco(String id) => compras.produtos[id]?.preco ?? '—';
            final pode = compras.disponivel;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (!pode) const _Aviso('A loja do Google Play não está disponível neste aparelho.'),
                if (compras.erro case final erro?) _Aviso(erro),
                _CartaoAssinatura(
                  preco: preco(Produtos.assinatura),
                  ativo: p.assinante,
                  aoAssinar: pode ? () => compras.comprar(Produtos.assinatura) : null,
                ),
                const SizedBox(height: 12),
                _Item(
                  icone: const Icon(Icons.block_rounded, color: Cores.destaque, size: 32),
                  titulo: 'Sem anúncios',
                  descricao: 'Para sempre, entre partidas.',
                  botao: p.semAnuncios ? 'Ativo' : preco(Produtos.semAnuncios),
                  aoTocar: pode && !p.semAnuncios ? () => compras.comprar(Produtos.semAnuncios) : null,
                ),
                const SizedBox(height: 20),
                const Text('Gemas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Text('Use em Desfazer, Trocar e Continuar.', style: TextStyle(color: Cores.textoFraco)),
                const SizedBox(height: 8),
                _Item(
                  icone: const Icon(Icons.smart_display_rounded, color: Cores.gema, size: 32),
                  titulo: '+$gemasPorAnuncio gemas grátis',
                  descricao: 'Anúncio curto · ${p.premiadosNoDia(_dia)} de $premiadosPorDia hoje',
                  botao: 'Assistir',
                  aoTocar: p.premiadosNoDia(_dia) < premiadosPorDia ? () => _gemasComAnuncio(context) : null,
                ),
                for (final MapEntry(key: id, value: qtd) in Produtos.gemas.entries) ...[
                  const SizedBox(height: 8),
                  _Item(
                    icone: const IconeGema(tamanho: 32),
                    titulo: '$qtd gemas',
                    descricao: qtd >= 1000 ? 'Melhor valor' : (qtd >= 300 ? 'Mais popular' : 'Para começar'),
                    botao: preco(id),
                    aoTocar: pode ? () => compras.comprar(id) : null,
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Temas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Text('Mude as cores das peças.', style: TextStyle(color: Cores.textoFraco)),
                for (final t in TemaDeBlocos.todos) ...[
                  const SizedBox(height: 8),
                  _ItemTema(
                    tema: t,
                    temTema: p.temTema(t, eventoAtivo: eventoAtivo(servicos.hoje())?.id),
                    emUso: p.temaAtivo.id == t.id,
                    aoTocar: () => _escolherTema(context, t),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton(onPressed: pode ? compras.restaurar : null, child: const Text('Restaurar compras')),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartaoAssinatura extends StatelessWidget {
  const _CartaoAssinatura({required this.preco, required this.ativo, this.aoAssinar});

  final String preco;
  final bool ativo;
  final VoidCallback? aoAssinar;

  static const _beneficios = ['Sem anúncios entre partidas', 'Continuar grátis em toda partida', '+10 gemas todo dia'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Cores.blocos[5], Cores.destaque],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Cores.ouro, size: 30),
            SizedBox(width: 8),
            Text('Encaixa+', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        for (final b in _beneficios)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(b, style: const TextStyle(fontSize: 16))),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Cores.fundoTopo),
            onPressed: ativo ? null : aoAssinar,
            child: Text(ativo ? 'Assinatura ativa' : 'Assinar por $preco/mês'),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Renova todo mês. Cancele quando quiser no Google Play.',
          style: TextStyle(fontSize: 12, color: Color(0xDDFFFFFF)),
        ),
      ],
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item({required this.icone, required this.titulo, required this.descricao, required this.botao, this.aoTocar});

  final Widget icone;
  final String titulo, descricao, botao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
    decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        icone,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(descricao, style: const TextStyle(color: Cores.textoFraco)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: aoTocar,
          child: Text(botao),
        ),
      ],
    ),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(texto, style: const TextStyle(color: Cores.ouro)),
  );
}

class _ItemTema extends StatelessWidget {
  const _ItemTema({required this.tema, required this.temTema, required this.emUso, required this.aoTocar});

  final TemaDeBlocos tema;
  final bool temTema, emUso;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final bloqueado = !temTema && (tema.assinante || tema.evento != null);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(color: Cores.painel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          SizedBox(width: 96, height: 32, child: CustomPaint(painter: _Amostra(tema))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tema.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (tema.assinante || tema.evento != null)
                  Text(
                    tema.assinante ? 'Exclusivo Encaixa+' : 'Grátis no evento',
                    style: const TextStyle(color: Cores.textoFraco, fontSize: 13),
                  ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
            onPressed: emUso || bloqueado ? null : aoTocar,
            child: emUso
                ? const Text('Em uso')
                : temTema
                ? const Text('Usar')
                : bloqueado
                ? const Icon(Icons.lock_rounded, size: 20)
                : Row(mainAxisSize: MainAxisSize.min, children: [const IconeGema(tamanho: 16), Text(' ${tema.preco}')]),
          ),
        ],
      ),
    );
  }
}

/// Seis blocos pequenos com as cores do tema.
class _Amostra extends CustomPainter {
  const _Amostra(this.tema);

  final TemaDeBlocos tema;

  @override
  void paint(Canvas canvas, Size s) {
    final lado = s.width / 6;
    for (var i = 0; i < 6; i++) {
      final r = Rect.fromLTWH(i * lado + 1, (s.height - lado) / 2, lado - 2, lado - 2);
      pintarBloco(canvas, r, tema.cores[i]);
    }
  }

  @override
  bool shouldRepaint(_Amostra antigo) => antigo.tema != tema;
}
