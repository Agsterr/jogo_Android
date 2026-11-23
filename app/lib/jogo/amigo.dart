/// Desafio de amigo: um código com a semente das peças e a pontuação a bater.
/// O amigo cola o código e joga com as mesmas peças. Não precisa de servidor.
class DesafioAmigo {
  const DesafioAmigo({required this.semente, required this.pontos, this.infinito = false});

  /// Semente do sorteio das peças.
  final int semente;

  /// Pontuação de quem desafiou.
  final int pontos;

  /// Veio do Infinito (peças maiores a cada nível) em vez de peças iguais para todos.
  final bool infinito;

  /// Identifica o desafio (o prêmio por vencer vale uma vez só por desafio).
  String get id => semente.toRadixString(36);

  String get codigo => 'ENCAIXA-AMIGO-$id-$pontos-${infinito ? 'i' : 'f'}';

  static final _padrao = RegExp(r'encaixa-amigo-([0-9a-z]{1,12})-(\d{1,8})-([if])');

  /// Acha o código em qualquer texto colado (inclusive a mensagem inteira do amigo). `null` se não achar.
  static DesafioAmigo? ler(String texto) {
    final m = _padrao.firstMatch(texto.toLowerCase());
    if (m == null) return null;
    final semente = int.tryParse(m.group(1)!, radix: 36);
    final pontos = int.tryParse(m.group(2)!);
    if (semente == null || pontos == null || semente <= 0) return null;
    return DesafioAmigo(semente: semente, pontos: pontos, infinito: m.group(3) == 'i');
  }
}

/// Gemas por vencer o desafio de um amigo (uma vez por desafio).
const gemasPorVencerAmigo = 10;
