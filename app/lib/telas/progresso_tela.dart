import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../jogo/fases.dart';
import '../servicos/codigo_progresso.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';

/// Salvar o progresso num código e recuperá-lo em outro celular (ou depois de reinstalar).
class ProgressoTela extends StatefulWidget {
  const ProgressoTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<ProgressoTela> createState() => _ProgressoTelaState();
}

class _ProgressoTelaState extends State<ProgressoTela> {
  final _campo = TextEditingController();
  String? _erro;

  Servicos get _s => widget.servicos;

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  /// Mostra a mensagem na hora (tira a anterior da frente).
  void _avisar(String texto) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(texto)));

  Future<String> _codigo() => _s.progresso.gerarCodigo(_s.hoje().millisecondsSinceEpoch);

  Future<void> _copiar() async {
    final codigo = await _codigo();
    await Clipboard.setData(ClipboardData(text: codigo));
    if (!mounted) return;
    _avisar('Código copiado! Guarde num lugar seguro (WhatsApp, e-mail, notas).');
  }

  Future<void> _enviar() async {
    final codigo = await _codigo();
    await SharePlus.instance.share(ShareParams(text: 'Meu progresso no Encaixa:\n$codigo'));
  }

  Future<void> _colar() async {
    final dados = await Clipboard.getData(Clipboard.kTextPlain);
    if (dados?.text == null) return;
    setState(() {
      _campo.text = dados!.text!;
      _erro = null;
    });
  }

  Future<void> _recuperar() async {
    final dados = CodigoProgresso.ler(_campo.text);
    if (dados == null) {
      setState(() => _erro = 'Código inválido. Confira se copiou o código inteiro, começando com ENCAIXA1-.');
      return;
    }
    if (!_s.progresso.codigoRecente(dados)) {
      setState(() => _erro = 'Este código é do progresso que já está neste celular (ou é mais antigo que ele).');
      return;
    }
    setState(() => _erro = null);
    final r = CodigoProgresso.resumo(dados);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.painel,
        title: const Text('Recuperar este progresso?', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Fase ${r.fase.clamp(1, Fase.total)} · ${r.estrelas} estrelas\nRecorde ${r.recorde}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconeGema(tamanho: 20),
                Text(' ${r.gemas} gemas', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Isso substitui o progresso que está neste celular.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.ouro),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Recuperar')),
        ],
      ),
    );
    if (confirmou != true) return;
    await _s.progresso.restaurarCodigo(dados);
    if (!mounted) return;
    _campo.clear();
    _avisar('Progresso recuperado!');
  }

  @override
  Widget build(BuildContext context) {
    final p = _s.progresso;
    return Scaffold(
      body: FundoJogo(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: p,
            builder: (context, _) => ListView(
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
                      child: TextoContornado('Salvar progresso', tamanho: 26, alinhamento: TextAlign.start),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CartaoVidro(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seu progresso agora', style: TextStyle(color: Cores.textoFraco)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.map_rounded, color: Cores.brilhoCiano),
                          Text(
                            '  Fase ${p.faseLiberada.clamp(1, Fase.total)} de ${Fase.total}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          const Icon(Icons.star_rounded, color: Cores.ouro),
                          Text(
                            ' ${p.estrelasTotais}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const IconeGema(tamanho: 22),
                          Text(' ${p.gemas} gemas', style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          const Icon(Icons.emoji_events_rounded, color: Cores.ouro, size: 22),
                          Text(' ${p.recorde}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const TextoContornado('1. Salvar', tamanho: 22, alinhamento: TextAlign.start),
                const SizedBox(height: 4),
                const Text(
                  'Se você vai trocar de celular ou desinstalar o jogo, copie o código e guarde (mande para você '
                  'mesmo no WhatsApp ou e-mail, ou anote nas notas).',
                  style: TextStyle(fontSize: 15, height: 1.3),
                ),
                const SizedBox(height: 10),
                BotaoDoce(
                  texto: 'COPIAR CÓDIGO',
                  icone: Icons.copy_rounded,
                  cor: Cores.blocos[3],
                  altura: 54,
                  tamanhoTexto: 20,
                  aoTocar: _copiar,
                ),
                const SizedBox(height: 10),
                BotaoDoce(
                  texto: 'ENVIAR POR APP',
                  icone: Icons.share_rounded,
                  cor: Cores.blocos[4],
                  altura: 46,
                  tamanhoTexto: 18,
                  aoTocar: _enviar,
                ),
                const SizedBox(height: 22),
                const TextoContornado('2. Recuperar', tamanho: 22, alinhamento: TextAlign.start),
                const SizedBox(height: 4),
                const Text(
                  'No celular novo (ou depois de reinstalar), cole aqui o código que você salvou.',
                  style: TextStyle(fontSize: 15, height: 1.3),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _campo,
                  minLines: 3,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 14),
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: InputDecoration(
                    hintText: 'Cole aqui o código (começa com ENCAIXA1-)',
                    filled: true,
                    fillColor: Cores.painel,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _erro!,
                      style: const TextStyle(color: Cores.destaque, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
                        onPressed: _colar,
                        icon: const Icon(Icons.content_paste_rounded),
                        label: const Text('Colar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: BotaoDoce(
                        texto: 'RECUPERAR',
                        icone: Icons.restore_rounded,
                        cor: Cores.blocos[5],
                        altura: 52,
                        tamanhoTexto: 19,
                        aoTocar: _campo.text.trim().isEmpty ? null : _recuperar,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'As compras (Sem anúncios e Encaixa+) não vão no código: voltam em Loja > Restaurar compras.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Cores.textoFraco, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
