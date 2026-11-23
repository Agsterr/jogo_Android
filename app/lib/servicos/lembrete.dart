import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdados;
import 'package:timezone/timezone.dart' as tz;

/// Hora do lembrete do Desafio do dia (horário do celular).
const horaDoLembrete = 19;

/// Próximo lembrete: hoje às 19h, ou amanhã se já passou das 19h ou se o Desafio de hoje já foi feito.
DateTime proximoLembrete(DateTime agora, {required bool desafioFeitoHoje}) {
  final hoje = DateTime(agora.year, agora.month, agora.day, horaDoLembrete);
  if (!desafioFeitoHoje && agora.isBefore(hoje)) return hoje;
  return DateTime(agora.year, agora.month, agora.day + 1, horaDoLembrete);
}

/// Lembrete diário do Desafio. A notificação é agendada uma vez por vez (a cada abertura do jogo e a cada
/// Desafio concluído), então quem não abre o jogo por dias recebe no máximo uma por dia, e nunca depois de jogar.
abstract class Lembrete {
  /// Pede a permissão de notificação (Android 13+). `true` se pode notificar.
  Future<bool> pedirPermissao();

  /// Agenda (ou desagenda, se [ligado] for falso) o próximo lembrete.
  Future<void> reagendar({required bool ligado, required bool desafioFeitoHoje, required DateTime agora});
}

class SemLembrete implements Lembrete {
  const SemLembrete();

  @override
  Future<bool> pedirPermissao() async => false;

  @override
  Future<void> reagendar({required bool ligado, required bool desafioFeitoHoje, required DateTime agora}) async {}
}

/// Notificação local do Android (flutter_local_notifications). Não precisa de internet nem de servidor.
class LembreteLocal implements Lembrete {
  static const _id = 19;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> _iniciar() async {
    if (_pronto) return true;
    final android = _android;
    if (android == null) return false;
    tzdados.initializeTimeZones();
    await android.initialize(settings: const AndroidInitializationSettings('@mipmap/ic_launcher'));
    return _pronto = true;
  }

  @override
  Future<bool> pedirPermissao() async {
    try {
      if (!await _iniciar()) return false;
      return await _android!.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('Lembrete: não deu para pedir permissão: $e');
      return false;
    }
  }

  @override
  Future<void> reagendar({required bool ligado, required bool desafioFeitoHoje, required DateTime agora}) async {
    try {
      if (!await _iniciar()) return;
      await _android!.cancel(id: _id);
      if (!ligado) return;
      final quando = proximoLembrete(agora, desafioFeitoHoje: desafioFeitoHoje);
      // O instante certo, sem depender do fuso: diferença até a hora local somada ao agora em UTC.
      final instante = tz.TZDateTime.now(tz.UTC).add(quando.difference(agora));
      await _android!.zonedSchedule(
        id: _id,
        title: 'Desafio do dia no Encaixa',
        body: 'O desafio de hoje está esperando. Mantenha a sua sequência!',
        scheduledDate: instante,
        notificationDetails: const AndroidNotificationDetails(
          'desafio',
          'Desafio do dia',
          channelDescription: 'Lembrete diário do Desafio do dia',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        // Inexato: não precisa da permissão de alarme exato (o horário pode variar alguns minutos).
        scheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Lembrete: não deu para agendar: $e');
    }
  }
}
