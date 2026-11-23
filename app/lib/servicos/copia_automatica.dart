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

/// Quem sabe dizer em que conta Google o progresso está sendo salvo.
abstract interface class ContaDoJogador {
  /// Nome do jogador conectado, ou `null` se não houver conta conectada (ou der erro).
  Future<String?> nome();

  /// Abre o login do Play Games. `true` se o jogador ficou conectado.
  Future<bool> conectar();
}

/// Jogo salvo do Play Games Services, na conta Google (código nativo em `MainActivity.kt`).
/// Entra sozinho com a conta; sem conta ou sem rede o canal devolve erro e o jogo segue sem a nuvem.
class CopiaPlayGames implements CopiaAutomatica, ContaDoJogador {
  static const _canal = MethodChannel('encaixa/nuvem');

  @override
  Future<bool> conectar() async {
    try {
      return await _canal.invokeMethod<bool>('conectar') ?? false;
    } on Object catch (e) {
      debugPrint('Play Games (conectar): $e');
      return false;
    }
  }

  @override
  Future<String?> nome() async {
    try {
      final nome = await _canal.invokeMethod<String>('jogador');
      return (nome == null || nome.trim().isEmpty) ? null : nome.trim();
    } on Object catch (e) {
      debugPrint('Play Games (jogador): $e');
      return null;
    }
  }

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    try {
      await _canal.invokeMapMethod<String, Object?>('salvar', {'bytes': bytes});
      return const ResultadoCopia(ok: true, nuvem: true);
    } on Object catch (e) {
      debugPrint('Play Games (salvar): $e');
      return const ResultadoCopia(ok: false);
    }
  }

  @override
  Future<Uint8List?> ler() async {
    try {
      return await _canal.invokeMethod<Uint8List>('ler');
    } on Object catch (e) {
      debugPrint('Play Games (ler): $e');
      return null;
    }
  }
}

/// Grava em todas as cópias e, ao ler, fica com o progresso **mais avançado** (fase, depois estrelas, recorde e,
/// por fim, o mais recente). Assim a conta Google e o Block Store se complementam.
class CopiaDupla implements CopiaAutomatica, ContaDoJogador {
  const CopiaDupla(this._copias);

  final List<CopiaAutomatica> _copias;

  @override
  Future<bool> conectar() async {
    for (final c in _copias) {
      if (c is! ContaDoJogador) continue;
      try {
        return await (c as ContaDoJogador).conectar();
      } on Object {
        return false;
      }
    }
    return false;
  }

  @override
  Future<String?> nome() async {
    for (final c in _copias) {
      if (c is! ContaDoJogador) continue;
      try {
        final nome = await (c as ContaDoJogador).nome();
        if (nome != null) return nome;
      } on Object {
        continue;
      }
    }
    return null;
  }

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    final rs = await Future.wait(
      _copias.map((c) => c.salvar(bytes).catchError((Object _) => const ResultadoCopia(ok: false))),
    );
    return ResultadoCopia(ok: rs.any((r) => r.ok), nuvem: rs.any((r) => r.ok && r.nuvem));
  }

  @override
  Future<Uint8List?> ler() async {
    final lidos = await Future.wait(_copias.map((c) => c.ler().catchError((Object _) => null)));
    Uint8List? melhor;
    List<int>? melhorNota;
    for (final bytes in lidos) {
      if (bytes == null || bytes.isEmpty) continue;
      final dados = CodigoProgresso.ler(utf8.decode(bytes, allowMalformed: true));
      if (dados == null) continue;
      final r = CodigoProgresso.resumo(dados);
      final nota = [r.fase, r.estrelas, r.recorde, dados['salvoEm']! as int];
      if (melhorNota == null || _maior(nota, melhorNota)) {
        melhor = bytes;
        melhorNota = nota;
      }
    }
    return melhor;
  }

  static bool _maior(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
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

  /// Nome da conta Google (Play Games) em que o progresso está sendo salvo; `null` se não houver conta conectada.
  final conta = ValueNotifier<String?>(null);

  /// Este aparelho tem Play Games? (Falso nos testes, na web e fora do Android: aí a tela não pede para conectar.)
  bool get suportaConta => _copia is ContaDoJogador;

  /// Abre o login do Play Games. Se conectou, mostra o nome e já salva o progresso na conta.
  Future<bool> conectar() async {
    final copia = _copia;
    if (copia is! ContaDoJogador) return false;
    bool ok;
    try {
      ok = await (copia as ContaDoJogador).conectar();
    } on Object {
      ok = false;
    }
    await atualizarConta();
    if (ok) await salvarAgora();
    return ok;
  }

  /// Pergunta ao Play Games quem está conectado (a tela Salvar progresso mostra o nome).
  Future<void> atualizarConta() async {
    final copia = _copia;
    if (copia is! ContaDoJogador) return;
    try {
      conta.value = await (copia as ContaDoJogador).nome();
    } on Object {
      conta.value = null;
    }
  }

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
    unawaited(atualizarConta());
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
    conta.dispose();
  }
}
