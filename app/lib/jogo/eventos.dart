/// Eventos com prazo. A lista fica no app; quando houver Remote Config, ela pode vir de lá (#15).
class Evento {
  const Evento(this.id, this.nome, this.inicio, this.fim, {this.tema, this.gemasEmDobro = true});

  final String id;
  final String nome;
  final DateTime inicio;

  /// Fim exclusivo (o evento acaba neste instante).
  final DateTime fim;

  /// Tema de blocos que pode ser pego de graça durante o evento.
  final String? tema;
  final bool gemasEmDobro;

  bool ativo(DateTime agora) => !agora.isBefore(inicio) && agora.isBefore(fim);
}

final eventos = [
  Evento('natal-2026', 'Natal', DateTime(2026, 12, 18), DateTime(2026, 12, 27), tema: 'natal'),
  Evento('carnaval-2027', 'Carnaval', DateTime(2027, 2, 5), DateTime(2027, 2, 11)),
];

Evento? eventoAtivo(DateTime agora) {
  for (final e in eventos) {
    if (e.ativo(agora)) return e;
  }
  return null;
}

/// Sexta 18h até domingo 23h59.
bool fimDeSemana(DateTime d) =>
    (d.weekday == DateTime.friday && d.hour >= 18) || d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

/// Gemas de linha de uma cor e tabuleiro limpo valem o dobro no fim de semana e em eventos.
int multiplicadorDeGemas(DateTime agora) => fimDeSemana(agora) || (eventoAtivo(agora)?.gemasEmDobro ?? false) ? 2 : 1;

/// "3d 4h", "5h 12min" ou "12min".
String tempoRestante(DateTime agora, DateTime fim) {
  final d = fim.difference(agora);
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}min';
  return '${d.inMinutes}min';
}
