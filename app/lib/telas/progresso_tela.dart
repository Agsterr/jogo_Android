import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../app.dart';
import '../jogo/fases.dart';
import '../servicos/codigo_progresso.dart';
import '../servicos/copia_automatica.dart';
import '../servicos/servicos.dart';
import '../tema.dart';
import '../widgets/doce.dart';
import '../widgets/peca_widget.dart';
import '../idioma.dart';

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
  void initState() {
    super.initState();
    _s.copia?.salvarAgora(); // atualiza a cópia automática e o estado mostrado abaixo
  }

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
    _avisar(t('Código copiado! Guarde num lugar seguro (WhatsApp, e-mail, notas).'));
  }

  Future<void> _enviar() async {
    final codigo = await _codigo();
    await SharePlus.instance.share(ShareParams(text: t('Meu progresso no Encaixa:\n{0}', [codigo])));
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
      setState(() => _erro = t('Código inválido. Confira se copiou o código inteiro, começando com ENCAIXA1-.'));
      return;
    }
    if (!_s.progresso.codigoRecente(dados)) {
      setState(() => _erro = t('Este código é do progresso que já está neste celular (ou é mais antigo que ele).'));
      return;
    }
    setState(() => _erro = null);
    final r = CodigoProgresso.resumo(dados);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Cores.painel,
        title: Text(t('Recuperar este progresso?'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t('Fase {0} · {1} estrelas\nRecorde {2}', [r.fase.clamp(1, Fase.total), r.estrelas, r.recorde]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const IconeGema(tamanho: 20),
                Text(t(' {0} gemas', [r.gemas]), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t('Isso substitui o progresso que está neste celular.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Cores.ouro),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t('Cancelar'))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t('Recuperar'))),
        ],
      ),
    );
    if (confirmou != true) return;
    await _s.progresso.restaurarCodigo(dados);
    if (!mounted) return;
    _campo.clear();
    _avisar(t('Progresso recuperado!'));
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
                      tooltip: t('Voltar'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(child: TextoContornado(t('Salvar progresso'), tamanho: 26, alinhamento: TextAlign.start)),
                  ],
                ),
                const SizedBox(height: 8),
                CartaoVidro(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t('Seu progresso agora'), style: TextStyle(color: Cores.textoFraco)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.map_rounded, color: Cores.brilhoCiano),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t('  Fase {0} de {1}', [p.faseLiberada.clamp(1, Fase.total), Fase.total]),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
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
                          Text(t(' {0} gemas', [p.gemas]), style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          const Icon(Icons.emoji_events_rounded, color: Cores.ouro, size: 22),
                          Text(' ${p.recorde}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_s.copia case final copia?) ...[
                  const SizedBox(height: 12),
                  _CartaoCopiaAutomatica(copia.status),
                  if (copia.suportaConta) ...[const SizedBox(height: 12), _CartaoContaGoogle(copia)],
                ],
                const SizedBox(height: 20),
                TextoContornado(t('1. Salvar'), tamanho: 22, alinhamento: TextAlign.start),
                const SizedBox(height: 4),
                Text(
                  t(
                    'Se você vai trocar de celular ou desinstalar o jogo, copie o código e guarde (mande para você mesmo no WhatsApp ou e-mail, ou anote nas notas).',
                  ),
                  style: TextStyle(fontSize: 15, height: 1.3),
                ),
                const SizedBox(height: 10),
                BotaoDoce(
                  texto: t('COPIAR CÓDIGO'),
                  icone: Icons.copy_rounded,
                  cor: Cores.blocos[3],
                  altura: 54,
                  tamanhoTexto: 20,
                  aoTocar: _copiar,
                ),
                const SizedBox(height: 10),
                BotaoDoce(
                  texto: t('ENVIAR POR APP'),
                  icone: Icons.share_rounded,
                  cor: Cores.blocos[4],
                  altura: 46,
                  tamanhoTexto: 18,
                  aoTocar: _enviar,
                ),
                const SizedBox(height: 22),
                TextoContornado(t('2. Recuperar'), tamanho: 22, alinhamento: TextAlign.start),
                const SizedBox(height: 4),
                Text(
                  t('No celular novo (ou depois de reinstalar), cole aqui o código que você salvou.'),
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
                    hintText: t('Cole aqui o código (começa com ENCAIXA1-)'),
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
                        label: Text(t('Colar')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: BotaoDoce(
                        texto: t('RECUPERAR'),
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
                Text(
                  t('As compras (Sem anúncios e Encaixa+) não vão no código: voltam em Loja > Restaurar compras.'),
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

/// Conta do Play Games em que o progresso é salvo; sem conta, pede para conectar.
class _CartaoContaGoogle extends StatefulWidget {
  const _CartaoContaGoogle(this.copia);

  final SalvamentoAutomatico copia;

  @override
  State<_CartaoContaGoogle> createState() => _CartaoContaGoogleState();
}

class _CartaoContaGoogleState extends State<_CartaoContaGoogle> {
  bool _conectando = false;
  bool _falhou = false;

  Future<void> _conectar() async {
    setState(() {
      _conectando = true;
      _falhou = false;
    });
    final ok = await widget.copia.conectar();
    if (!mounted) return;
    setState(() {
      _conectando = false;
      _falhou = !ok;
    });
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: widget.copia.conta,
    builder: (context, nome, _) {
      final conectado = nome != null;
      final cor = conectado ? Cores.blocos[3] : Cores.ouro;
      return CartaoVidro(
        cores: [cor, Cores.brilhoCiano],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(conectado ? Icons.account_circle_rounded : Icons.login_rounded, color: cor, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conectado ? t('Conectado ao Play Games') : t('Conecte ao Play Games'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conectado
                            ? t(
                                'Conta: {0}. Seu progresso é salvo na sua conta Google e volta se você trocar de celular.',
                                [nome],
                              )
                            : t(
                                'Sem a conta do Play Games, o progresso pode se perder se você trocar de celular ou desinstalar o jogo. Conecte para salvar na sua conta Google.',
                              ),
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                      if (_falhou && !conectado)
                        Text(
                          t('Não deu para conectar agora. Confira a internet e tente de novo.'),
                          style: TextStyle(fontSize: 13, color: Cores.textoFraco),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!conectado) ...[
              const SizedBox(height: 10),
              BotaoDoce(
                texto: _conectando ? t('CONECTANDO...') : t('CONECTAR AO PLAY GAMES'),
                icone: Icons.sports_esports_rounded,
                cor: Cores.blocos[4],
                altura: 46,
                tamanhoTexto: 18,
                aoTocar: _conectando ? null : _conectar,
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Mostra se a cópia automática está funcionando neste celular.
class _CartaoCopiaAutomatica extends StatelessWidget {
  const _CartaoCopiaAutomatica(this.status);

  final ValueListenable<StatusCopia> status;

  static String _hora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<StatusCopia>(
    valueListenable: status,
    builder: (context, s, _) {
      final (icone, cor, titulo, texto) = switch (s.estado) {
        EstadoCopia.aindaNao => (
          Icons.sync_rounded,
          Cores.textoFraco,
          t('Cópia automática'),
          t('Salvando o seu progresso automaticamente...'),
        ),
        EstadoCopia.naNuvem => (
          Icons.cloud_done_rounded,
          Cores.blocos[3],
          t('Cópia automática ligada'),
          t(
            'Seu progresso está salvo no Google (backup na nuvem). Se reinstalar o jogo ou trocar de celular, ele volta sozinho.',
          ),
        ),
        EstadoCopia.soNoCelular => (
          Icons.check_circle_rounded,
          Cores.blocos[3],
          t('Cópia automática ligada'),
          t(
            'Salva neste celular: se reinstalar o jogo, ele volta sozinho (com o Backup do Google ligado). Para trocar de celular, use o código abaixo.',
          ),
        ),
        EstadoCopia.indisponivel => (
          Icons.warning_amber_rounded,
          Cores.ouro,
          t('Cópia automática indisponível'),
          t('Este celular não permitiu a cópia automática. Use o código abaixo para não perder o progresso.'),
        ),
      };
      return CartaoVidro(
        cores: [cor, Cores.brilhoCiano],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(texto, style: const TextStyle(fontSize: 14, height: 1.3)),
                  if (s.quando != null && s.estado != EstadoCopia.indisponivel)
                    Text(
                      t('Última cópia: {0}', [_hora(s.quando!)]),
                      style: const TextStyle(fontSize: 13, color: Cores.textoFraco),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
