import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../idioma.dart';
import '../jogo/bau.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';
import '../widgets/mascote.dart';
import '../widgets/peca_widget.dart';

/// Baús de itens: abrir, ver as chances e a garantia, e equipar o que já se tem. Só aparência.
class BausTela extends StatefulWidget {
  const BausTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<BausTela> createState() => _BausTelaState();
}

class _BausTelaState extends State<BausTela> {
  Servicos get _s => widget.servicos;
  bool _abrindo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) mostrarDicaUmaVez(context, _s, Dicas.baus);
    });
  }

  Future<void> _abrir() async {
    if (_abrindo || _s.progresso.baus <= 0) return;
    setState(() => _abrindo = true);
    final resultado = await _s.progresso.abrirBauDeItens();
    if (!mounted) return;
    if (resultado != null) {
      HapticFeedback.mediumImpact();
      await showDialog<void>(
        context: context,
        builder: (_) => AberturaDeBau(resultado: resultado),
      );
    }
    if (mounted) setState(() => _abrindo = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = _s.progresso;
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: p,
            builder: (context, _) {
              final estado = p.estadoDoBau;
              final itens = p.itensDeBau;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: t('Voltar'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: TextoContornado(t('Baús e coleção'), tamanho: 26, alinhamento: TextAlign.start),
                        ),
                      ),
                      GemasChip(gemas: p.gemas),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CartaoVidro(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 56, color: Cores.ouro),
                        const SizedBox(height: 4),
                        Text(
                          p.baus == 0 ? t('Nenhum baú agora') : t('Baús para abrir: {0}', [p.baus]),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t(
                            'Ganhe baús jogando: Desafio do dia, Passe, álbum completo e sequência. Eles só trazem itens de aparência.',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, height: 1.3, color: Cores.textoFraco),
                        ),
                        const SizedBox(height: 10),
                        BotaoDoce(
                          texto: t('ABRIR BAÚ'),
                          icone: Icons.lock_open_rounded,
                          cor: Cores.blocos[3],
                          altura: 54,
                          tamanhoTexto: 20,
                          aoTocar: p.baus > 0 && !_abrindo ? _abrir : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CartaoVidro(child: _Chances(estado: estado)),
                  const SizedBox(height: 12),
                  for (final c in Categoria.values) ...[
                    _SecaoDaColecao(categoria: c, servicos: _s, niveis: itens),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    t('Baús abertos: {0}', [p.bausAbertos]),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Cores.textoFraco),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A tabela de chances e a garantia, sempre à vista.
class _Chances extends StatelessWidget {
  const _Chances({required this.estado});

  final EstadoDoBau estado;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t('Chances de cada baú'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      for (final r in Raridade.values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: Color(r.cor), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(t(r.nome), style: const TextStyle(fontSize: 15))),
              Text('${r.chance}%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      const SizedBox(height: 8),
      Text(
        t('Garantia: a cada {0} baús sai pelo menos um Raro, e a cada {1} um Lendário.', [
          garantiaRaro,
          garantiaLendario,
        ]),
        style: const TextStyle(fontSize: 13, height: 1.3, color: Cores.textoFraco),
      ),
      Text(
        t('Faltam {0} baús para o próximo Raro garantido.', [math.max(1, garantiaRaro - estado.semRaro)]),
        style: const TextStyle(fontSize: 13, height: 1.3, color: Cores.ouro),
      ),
    ],
  );
}

class _SecaoDaColecao extends StatelessWidget {
  const _SecaoDaColecao({required this.categoria, required this.servicos, required this.niveis});

  final Categoria categoria;
  final Servicos servicos;
  final Map<String, int> niveis;

  @override
  Widget build(BuildContext context) {
    final p = servicos.progresso;
    final itens = ItensDeBau.todos.where((i) => i.categoria == categoria).toList();
    final tem = itens.where((i) => (niveis[i.id] ?? 0) > 0).length;
    final padraoAtivo = !itens.any(p.equipado);
    return CartaoVidro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t(categoria.nome), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Text('$tem/${itens.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: [
              _CartaDoItem.padrao(categoria: categoria, ativo: padraoAtivo, aoTocar: () => p.usarPadrao(categoria)),
              for (final i in itens)
                _CartaDoItem(item: i, nivel: niveis[i.id] ?? 0, ativo: p.equipado(i), aoTocar: () => p.equipar(i)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Prévia de um item: blocos do tema, moldura do tabuleiro ou o Quadrinho na cor.
class PreviaDoItem extends StatelessWidget {
  const PreviaDoItem({super.key, required this.categoria, required this.cores, this.tamanho = 56});

  final Categoria categoria;
  final List<Color> cores;
  final double tamanho;

  @override
  Widget build(BuildContext context) => switch (categoria) {
    Categoria.mascote => Mascote(cor: cores.first, tamanho: tamanho),
    Categoria.moldura => Container(
      width: tamanho,
      height: tamanho,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tamanho * 0.2),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cores),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Cores.painel, borderRadius: BorderRadius.circular(tamanho * 0.15)),
      ),
    ),
    Categoria.tema => SizedBox(
      width: tamanho,
      height: tamanho * 0.7,
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          for (final c in cores.take(6))
            DecoratedBox(
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
            ),
        ],
      ),
    ),
  };
}

Color _corDoPadrao(Categoria c) => switch (c) {
  Categoria.mascote => Cores.blocos[3],
  _ => Cores.brilhoCiano,
};

class _CartaDoItem extends StatelessWidget {
  const _CartaDoItem({
    required ItemDeBau this.item,
    required int this.nivel,
    required this.ativo,
    required this.aoTocar,
  }) : categoria = null;

  const _CartaDoItem.padrao({required Categoria this.categoria, required this.ativo, required this.aoTocar})
    : item = null,
      nivel = 1;

  final ItemDeBau? item;
  final Categoria? categoria;
  final int? nivel;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final i = item;
    final tem = (nivel ?? 0) > 0;
    final cat = i?.categoria ?? categoria!;
    final corBorda = i == null ? Colors.white24 : Color(i.raridade.cor);
    final cores = i != null
        ? [for (final c in i.cores) Color(c)]
        : switch (cat) {
            Categoria.tema => Cores.blocos,
            Categoria.moldura => const [Cores.brilhoRosa, Color(0xFF8B5CFF), Cores.brilhoCiano],
            Categoria.mascote => [_corDoPadrao(cat)],
          };
    return Semantics(
      button: tem,
      label: i == null ? t('Padrão') : (tem ? t(i.nome) : t('Item ainda não conquistado')),
      child: GestureDetector(
        onTap: tem ? aoTocar : null,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: tem ? Cores.painel : Cores.casa,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ativo ? Cores.ouro : (tem ? corBorda : Colors.white10), width: ativo ? 3 : 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: tem
                      ? FittedBox(
                          child: PreviaDoItem(categoria: cat, cores: cores),
                        )
                      : const Icon(Icons.help_outline_rounded, size: 34, color: Colors.white24),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  i == null ? t('Padrão') : (tem ? t(i.nome) : '???'),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tem ? null : Colors.white38),
                ),
              ),
              if (i != null && tem)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var n = 1; n <= nivelMaximoDoItem; n++)
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: n <= (nivel ?? 0) ? Color(i.raridade.cor) : Colors.white12,
                      ),
                  ],
                )
              else if (i != null)
                Text(t(i.raridade.nome), style: TextStyle(fontSize: 10, color: Color(i.raridade.cor))),
              if (ativo) Text(t('Em uso'), style: const TextStyle(fontSize: 10, color: Cores.ouro)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A abertura: o baú balança e depois mostra o que saiu (item novo, subiu de nível ou virou gemas).
class AberturaDeBau extends StatefulWidget {
  const AberturaDeBau({super.key, required this.resultado});

  final ({ItemDeBau item, int nivelAntes, int nivelDepois, int gemas, bool garantido}) resultado;

  @override
  State<AberturaDeBau> createState() => _AberturaDeBauState();
}

class _AberturaDeBauState extends State<AberturaDeBau> with SingleTickerProviderStateMixin {
  late final AnimationController _balanco = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _balanco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final cor = Color(r.item.raridade.cor);
    return AlertDialog(
      backgroundColor: Cores.painel,
      scrollable: true,
      content: AnimatedBuilder(
        animation: _balanco,
        builder: (context, _) {
          final aberto = _balanco.isCompleted;
          if (!aberto) {
            return SizedBox(
              height: 180,
              child: Center(
                child: Transform.rotate(
                  angle: math.sin(_balanco.value * math.pi * 10) * 0.18 * (1 - _balanco.value * 0.4),
                  child: const Icon(Icons.inventory_2_rounded, size: 110, color: Cores.ouro),
                ),
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(r.item.raridade.nome).toUpperCase(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cor, letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cor, width: 3),
                  color: Cores.casa,
                  boxShadow: [BoxShadow(color: cor.withValues(alpha: 0.5), blurRadius: 22)],
                ),
                child: PreviaDoItem(
                  categoria: r.item.categoria,
                  cores: [for (final c in r.item.cores) Color(c)],
                  tamanho: 96,
                ),
              ),
              const SizedBox(height: 10),
              Text(t(r.item.nome), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Text(t(r.item.categoria.nome), style: const TextStyle(color: Cores.textoFraco)),
              const SizedBox(height: 6),
              Text(
                r.nivelAntes == 0
                    ? t('Item novo na coleção!')
                    : (r.gemas > 0
                          ? t('Repetido no nível máximo: +{0} gemas', [r.gemas])
                          : t('Subiu para o nível {0}!', [r.nivelDepois])),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Cores.gema),
              ),
              if (r.garantido) Text(t('Garantia de raridade'), style: const TextStyle(fontSize: 12, color: Cores.ouro)),
            ],
          );
        },
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('Legal!')))],
    );
  }
}
