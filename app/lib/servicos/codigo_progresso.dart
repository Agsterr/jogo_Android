import 'dart:convert';
import 'dart:io';

/// Código de progresso: o jogador copia num celular e cola em outro (ou depois de reinstalar).
///
/// Não precisa de servidor nem de conta. Limites (veja docs/PROGRESSO.md): quem sabe mexer em
/// Base64/gzip consegue editar um código, então ele não prova nada. Compras (Sem anúncios,
/// Encaixa+) nunca vão no código: voltam por "Restaurar compras". A partida em andamento e as
/// missões do dia também não vão.
abstract final class CodigoProgresso {
  static const prefixo = 'ENCAIXA1-';
  static const _tamanhoMaximo = 20000;

  static const _inteiros = {
    'recorde',
    'gemas',
    'partidas',
    'desafioFeito',
    'desafioPontos',
    'sequencia',
    'sequenciaMax',
    'relampagoMelhor',
    'desafiosTotal',
    'linhasMax',
    'comboMax',
    'amigosVencidos',
    'sequenciaSalva',
    'presenteDia',
    'presenteSeq',
    'faseLiberada',
    'arenaSemana',
    'arenaMelhor',
  };
  static const _listas = {'temas', 'dicas', 'arenaPremios', 'figurinhas', 'conquistas', 'amigosFeitos'};

  /// Esta chave do `SharedPreferences` faz parte do progresso que vai no código?
  static bool vai(String chave) =>
      _inteiros.contains(chave) ||
      _listas.contains(chave) ||
      chave == 'tema' ||
      chave == 'som' ||
      chave == 'simbolos' ||
      _ehEstrela(chave);

  static bool _ehEstrela(String chave) => chave.startsWith('estrelas_') && int.tryParse(chave.substring(9)) != null;

  static bool _valido(String chave, Object? v) {
    if (_ehEstrela(chave)) return v is int && v >= 0 && v <= 3;
    if (_inteiros.contains(chave)) return v is int && v >= 0 && v <= 2000000000;
    if (_listas.contains(chave)) return v is List && v.length <= 400 && v.every((e) => e is String && e.length <= 40);
    if (chave == 'tema') return v is String && v.length <= 30;
    if (chave == 'som' || chave == 'simbolos') return v is bool;
    return false;
  }

  /// Monta o código com o que estiver em [dados] e fizer parte do progresso. [agora] em ms.
  static String gerar(Map<String, Object?> dados, {required int agora}) {
    final saida = <String, Object>{
      for (final e in dados.entries)
        if (e.value != null && vai(e.key) && _valido(e.key, e.value)) e.key: e.value!,
      'salvoEm': agora,
    };
    return empacotar(saida);
  }

  /// JSON > gzip > Base64 + `.` + soma de verificação (pega código cortado ou com letra trocada).
  /// Público só para os testes montarem códigos "à mão".
  static String empacotar(Map<String, Object?> json) {
    final bytes = gzip.encode(utf8.encode(jsonEncode(json)));
    return '$prefixo${base64Url.encode(bytes).replaceAll('=', '')}.${_soma(bytes)}';
  }

  /// FNV-1a de 32 bits em hexadecimal (8 caracteres).
  static String _soma(List<int> bytes) {
    var h = 0x811C9DC5;
    for (final b in bytes) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  /// Lê um código. Devolve `null` se estiver errado, cortado ou adulterado de forma óbvia.
  /// Chaves desconhecidas (ex.: `assinante`) são ignoradas; valor de tipo errado recusa o código.
  static Map<String, Object>? ler(String texto) {
    final limpo = texto.replaceAll(RegExp(r'\s+'), ''); // apps de mensagem quebram linhas
    if (limpo.length <= prefixo.length || limpo.length > _tamanhoMaximo) return null;
    if (limpo.substring(0, prefixo.length).toUpperCase() != prefixo) return null;
    try {
      final resto = limpo.substring(prefixo.length);
      final ponto = resto.lastIndexOf('.');
      if (ponto < 0 || resto.length - ponto - 1 != 8) return null;
      var corpo = resto.substring(0, ponto);
      corpo = corpo.padRight((corpo.length + 3) ~/ 4 * 4, '=');
      final bytes = base64Url.decode(corpo);
      if (_soma(bytes) != resto.substring(ponto + 1).toLowerCase()) return null;
      final json = jsonDecode(utf8.decode(gzip.decode(bytes)));
      if (json is! Map) return null;
      final saida = <String, Object>{};
      for (final e in json.entries) {
        final chave = e.key as String;
        if (chave == 'salvoEm') {
          if (e.value is! int || (e.value as int) <= 0) return null;
          saida[chave] = e.value as int;
        } else if (vai(chave)) {
          if (!_valido(chave, e.value)) return null;
          saida[chave] = e.value is List ? List<String>.from(e.value as List) : e.value as Object;
        }
      }
      return saida.containsKey('salvoEm') ? saida : null;
    } on Object {
      return null; // base64, gzip ou JSON inválidos
    }
  }

  /// O que mostrar ao jogador antes de trocar o progresso: fase, estrelas, gemas e recorde.
  static ({int fase, int estrelas, int gemas, int recorde}) resumo(Map<String, Object> dados) => (
    fase: (dados['faseLiberada'] as int?) ?? 1,
    estrelas: dados.entries.where((e) => _ehEstrela(e.key)).fold(0, (soma, e) => soma + (e.value as int)),
    gemas: (dados['gemas'] as int?) ?? 0,
    recorde: (dados['recorde'] as int?) ?? 0,
  );
}
