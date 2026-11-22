import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'codigo_progresso.dart';
import 'progresso.dart';

/// Resultado de uma gravação na cópia automática.
class ResultadoCopia {
  const ResultadoCopia({required this.ok, this.nuvem = false});

  final bool ok;

  /// Também vai para o backup na nuvem do Google (precisa de Android 9+ e tela de bloqueio).
  final bool nuvem;
}

/// Onde a cópia automática do progresso fica guardada (fora dos dados do app).
abstract class CopiaAutomatica {
  Future<ResultadoCopia> salvar(Uint8List bytes);

  /// `null` se não houver nada guardado ou se der erro.
  Future<Uint8List?> ler();
}

/// Para testes, web e aparelhos sem Google Play services: não guarda nada.
class SemCopia implements CopiaAutomatica {
  const SemCopia();

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async => const ResultadoCopia(ok: false);

  @override
  Future<Uint8List?> ler() async => null;
}

/// Block Store do Google Play services (código nativo em `MainActivity.kt`).
/// Sobrevive a desinstalar e reinstalar quando o Backup do Google está ligado no celular.
class CopiaBlockStore implements CopiaAutomatica {
  static const _canal = MethodChannel('encaixa/copia');

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    try {
      final r = await _canal.invokeMapMethod<String, Object?>('salvar', {'bytes': bytes});
      return ResultadoCopia(ok: true, nuvem: r?['nuvem'] == true);
    } on Object catch (e) {
      debugPrint('cópia automática (salvar): $e');
      return const ResultadoCopia(ok: false);
    }
  }

  @override
  Future<Uint8List?> ler() async {
    try {
      return await _canal.invokeMethod<Uint8List>('ler');
    } on Object catch (e) {
      debugPrint('cópia automática (ler): $e');
      return null;
    }
  }
}

enum EstadoCopia { aindaNao, naNuvem, soNoCelular, indisponivel }

/// Último resultado da cópia automática (a tela Salvar progresso mostra isto).
class StatusCopia {
  const StatusCopia(this.estado, [this.quando]);

  final EstadoCopia estado;
  final DateTime? quando;
}

/// Salva o progresso sozinho e o recupera depois de reinstalar.
///
/// - A cada mudança no progresso, espera [pausa] sem novidades e grava a cópia (várias mudanças seguidas = 1 gravação).
/// - Na primeira abertura, se o aparelho ainda não tem progresso, procura a cópia e recupera sozinho.
/// - Nunca grava um progresso vazio: assim um celular recém-instalado não apaga a cópia boa antes de recuperá-la.
class SalvamentoAutomatico {
  SalvamentoAutomatico(
    this._progresso,
    this._copia, {
    this.pausa = const Duration(seconds: 5),
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  /// O código gerado precisa caber nos 4 KB de cada item do Block Store.
  static const limiteDeBytes = 3800;

  final Progresso _progresso;
  final CopiaAutomatica _copia;
  final Duration pausa;
  final DateTime Function() _relogio;
  final status = ValueNotifier<StatusCopia>(const StatusCopia(EstadoCopia.aindaNao));
  Timer? _timer;

  /// Tem algo que valha guardar? (Gemas sozinhas não contam: todo mundo começa com algumas.)
  bool get temProgresso =>
      _progresso.partidas > 0 || _progresso.faseLiberada > 1 || _progresso.recorde > 0 || _progresso.estrelasTotais > 0;

  /// Começa a salvar sozinho a cada mudança no progresso.
  void iniciar() => _progresso.addListener(_agendar);

  void _agendar() {
    _timer?.cancel();
    _timer = Timer(pausa, salvarAgora);
  }

  Future<void> salvarAgora() async {
    _timer?.cancel();
    if (!temProgresso) return;
    final agora = _relogio();
    final codigo = await _progresso.gerarCodigo(agora.millisecondsSinceEpoch);
    final bytes = Uint8List.fromList(utf8.encode(codigo));
    if (bytes.length > limiteDeBytes) {
      status.value = StatusCopia(EstadoCopia.indisponivel, agora);
      return;
    }
    ResultadoCopia r;
    try {
      r = await _copia.salvar(bytes);
    } on Object {
      r = const ResultadoCopia(ok: false);
    }
    status.value = StatusCopia(
      !r.ok ? EstadoCopia.indisponivel : (r.nuvem ? EstadoCopia.naNuvem : EstadoCopia.soNoCelular),
      agora,
    );
  }

  /// Aparelho sem progresso + cópia guardada = recupera. Devolve `true` se recuperou.
  Future<bool> recuperarSeVazio() async {
    if (temProgresso) return false;
    Uint8List? bytes;
    try {
      bytes = await _copia.ler();
    } on Object {
      return false;
    }
    if (bytes == null || bytes.isEmpty) return false;
    final dados = CodigoProgresso.ler(utf8.decode(bytes, allowMalformed: true));
    if (dados == null || !_progresso.codigoRecente(dados)) return false;
    await _progresso.restaurarCodigo(dados);
    _progresso.recuperadoAutomaticamente = true;
    return true;
  }

  void dispose() {
    _timer?.cancel();
    _progresso.removeListener(_agendar);
    status.dispose();
  }
}
