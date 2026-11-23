import 'package:flutter/widgets.dart';

import 'idioma_textos.dart';

/// Idiomas do jogo. O texto em português fica no próprio código e serve de chave da tabela de tradução
/// (`t('Jogar de novo')`), então o português nunca depende da tabela. Veja docs/IDIOMAS.md.
abstract final class Idioma {
  static const suportados = ['pt', 'en', 'es'];

  /// Nome de cada idioma, sempre no próprio idioma.
  static const nomes = {'pt': 'Português', 'en': 'English', 'es': 'Español'};

  /// Idioma em uso agora.
  static String atual = 'pt';

  /// "auto" segue o idioma do celular; se ele não for suportado, usa o inglês.
  static String resolver(String? escolha) {
    if (escolha != null && suportados.contains(escolha)) return escolha;
    final doCelular = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return suportados.contains(doCelular) ? doCelular : 'en';
  }

  static void definir(String? escolha) => atual = resolver(escolha);
}

/// Traduz [pt] (o texto em português) para o idioma em uso. Os `{0}`, `{1}`... do texto recebem [args]; um `{}`
/// sozinho é tratado por quem chama (modelos de missão). Sem tradução, devolve o português.
String t(String pt, [List<Object?> args = const []]) {
  var texto = Idioma.atual == 'pt' ? pt : (Textos.porIdioma[Idioma.atual]?[pt] ?? pt);
  for (var i = 0; i < args.length; i++) {
    texto = texto.replaceAll('{$i}', '${args[i]}');
  }
  return texto;
}
