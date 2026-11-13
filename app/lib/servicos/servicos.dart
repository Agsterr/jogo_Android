import 'anuncios.dart';
import 'compras.dart';
import 'progresso.dart';
import 'sons.dart';

/// O que as telas precisam do "mundo lá fora". Passado pelo construtor.
class Servicos {
  const Servicos({
    required this.progresso,
    required this.anuncios,
    required this.compras,
    this.sons = const SemSons(),
    this.hoje = _agora,
    this.mostrarPresenteAoAbrir = true,
    this.mostrarDicas = true,
    this.roletaAposPartida = true,
  });

  final Progresso progresso;
  final Anuncios anuncios;
  final Compras compras;
  final Sons sons;

  /// Relógio injetável: os testes fixam o dia do desafio.
  final DateTime Function() hoje;

  /// Abre o presente do dia sozinho na tela inicial (desligado nos testes).
  final bool mostrarPresenteAoAbrir;

  /// Dicas de primeira vez e tutorial (desligados nos testes de tela, ligados nos do tutorial).
  final bool mostrarDicas;

  /// Roleta de prêmios no fim de cada partida (desligada nos testes de tela).
  final bool roletaAposPartida;

  static DateTime _agora() => DateTime.now();
}

/// Link da loja usado no compartilhamento.
const linkDaLoja = 'https://play.google.com/store/apps/details?id=com.agsterr.encaixa';

/// Número do desafio (o primeiro foi em 1º/11/2026).
int numeroDoDesafio(DateTime dia) =>
    DateTime.utc(dia.year, dia.month, dia.day).difference(DateTime.utc(2026, 11, 1)).inDays + 1;
