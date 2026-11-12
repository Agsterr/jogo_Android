import 'anuncios.dart';
import 'compras.dart';
import 'progresso.dart';

/// O que as telas precisam do "mundo lá fora". Passado pelo construtor.
class Servicos {
  const Servicos({required this.progresso, required this.anuncios, required this.compras, this.hoje = _agora});

  final Progresso progresso;
  final Anuncios anuncios;
  final Compras compras;

  /// Relógio injetável: os testes fixam o dia do desafio.
  final DateTime Function() hoje;

  static DateTime _agora() => DateTime.now();
}

/// Link da loja usado no compartilhamento.
const linkDaLoja = 'https://play.google.com/store/apps/details?id=com.agsterr.encaixa';

/// Número do desafio (o primeiro foi em 1º/11/2026).
int numeroDoDesafio(DateTime dia) =>
    DateTime.utc(dia.year, dia.month, dia.day).difference(DateTime.utc(2026, 11, 1)).inDays + 1;
