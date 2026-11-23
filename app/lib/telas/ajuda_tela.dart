import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../servicos/servicos.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';

/// "Como jogar": todos os textos de ajuda numa tela só.
class AjudaTela extends StatefulWidget {
  const AjudaTela({super.key, required this.servicos});

  final Servicos servicos;

  @override
  State<AjudaTela> createState() => _AjudaTelaState();
}

class _AjudaTelaState extends State<AjudaTela> {
  Servicos get _s => widget.servicos;

  Future<void> _alternarLembrete(bool ligar) async {
    if (ligar && !await _s.lembrete.pedirPermissao()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Sem permissão de notificação. Ative nas configurações do celular.')),
        );
      return;
    }
    await _s.progresso.definirLembrete(ligar);
    await _s.reagendarLembrete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoJogo(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const TextoContornado('Como jogar', tamanho: 26),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  ListenableBuilder(
                    listenable: _s.progresso,
                    builder: (context, _) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CartaoVidro(
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lembrete do Desafio',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Um aviso às 19h, só se você ainda não jogou o Desafio do dia.',
                                    style: TextStyle(fontSize: 14, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            Switch(value: _s.progresso.lembreteLigado, onChanged: _alternarLembrete),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ListenableBuilder(
                    listenable: _s.progresso,
                    builder: (context, _) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CartaoVidro(
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_rounded, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Símbolos nas peças',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    'Um desenho em cada cor, para quem tem dificuldade de distinguir cores.',
                                    style: TextStyle(fontSize: 14, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            Switch(value: _s.progresso.simbolos, onChanged: (_) => _s.progresso.alternarSimbolos()),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final d in Dicas.todas)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CartaoVidro(
                        cores: [d.cor, d.cor.withValues(alpha: 0.3)],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(d.icone, color: d.cor, size: 28),
                                const SizedBox(width: 8),
                                TextoContornado(d.titulo, tamanho: 21, alinhamento: TextAlign.start),
                              ],
                            ),
                            const SizedBox(height: 6),
                            for (final l in d.linhas)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('• $l', style: const TextStyle(fontSize: 15, height: 1.3)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
