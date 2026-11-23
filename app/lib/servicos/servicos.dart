import 'anuncios.dart';
import 'compras.dart';
import 'copia_automatica.dart';
import 'lembrete.dart';
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
    this.copia,
    this.lembrete = const SemLembrete(),
  });

  final Progresso progresso;
  final Anuncios anuncios;
  final Compras compras;
  final Sons sons;

  /// Cópia automática do progresso (recupera sozinho depois de reinstalar). `null` nos testes de tela.
  final SalvamentoAutomatico? copia;

  /// Lembrete diário do Desafio (notificação às 19h).
  final Lembrete lembrete;

  /// Agenda o próximo lembrete conforme o estado de agora (ligado? Desafio de hoje já feito?).
  Future<void> reagendarLembrete() {
    final agora = hoje();
    return lembrete.reagendar(
      ligado: progresso.lembreteLigado,
      desafioFeitoHoje: progresso.desafioFeito == agora.year * 10000 + agora.month * 100 + agora.day,
      agora: agora,
    );
  }

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
const linkDaLoja = 'https://play.google.com/store/apps/details?id=com.agsterr.encaixa2';

/// Número do desafio (o primeiro foi em 1º/11/2026).
int numeroDoDesafio(DateTime dia) =>
    DateTime.utc(dia.year, dia.month, dia.day).difference(DateTime.utc(2026, 11, 1)).inDays + 1;
