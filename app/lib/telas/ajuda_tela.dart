import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../widgets/dicas.dart';
import '../widgets/doce.dart';

/// "Como jogar": todos os textos de ajuda numa tela só.
class AjudaTela extends StatelessWidget {
  const AjudaTela({super.key});

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
