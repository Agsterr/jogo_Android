import 'dart:convert';
import 'dart:typed_data';

import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/servicos/copia_automatica.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Falsa implements CopiaAutomatica {
  _Falsa({this.guardado, this.nuvem = false, this.ok = true, this.quebra = false});

  Uint8List? guardado;
  final bool nuvem;
  final bool ok;
  final bool quebra;

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    if (quebra) throw StateError('quebrou');
    if (ok) guardado = bytes;
    return ResultadoCopia(ok: ok, nuvem: nuvem);
  }

  @override
  Future<Uint8List?> ler() async {
    if (quebra) throw StateError('quebrou');
    return guardado;
  }
}

Uint8List _codigo(Map<String, Object?> dados, int agora) =>
    Uint8List.fromList(utf8.encode(CodigoProgresso.gerar(dados, agora: agora)));

void main() {
  _contaTests();
  test('grava nas duas cópias e conta como nuvem se alguma for nuvem', () async {
    final a = _Falsa(nuvem: true);
    final b = _Falsa();
    final r = await CopiaDupla([a, b]).salvar(_codigo({'faseLiberada': 3}, 1000));
    expect(r.ok, isTrue);
    expect(r.nuvem, isTrue);
    expect(a.guardado, isNotNull);
    expect(b.guardado, isNotNull);
  });

  test('uma cópia quebrada não derruba a outra', () async {
    final boa = _Falsa();
    final copia = CopiaDupla([_Falsa(quebra: true), boa]);
    final r = await copia.salvar(_codigo({'faseLiberada': 3}, 1000));
    expect(r.ok, isTrue);
    expect(r.nuvem, isFalse);
    expect(boa.guardado, isNotNull);
    expect(await copia.ler(), boa.guardado);
  });

  test('todas falhando = não ok', () async {
    final r = await CopiaDupla([_Falsa(ok: false), _Falsa(quebra: true)]).salvar(_codigo({'faseLiberada': 3}, 1000));
    expect(r.ok, isFalse);
  });

  test('ao ler, fica com o progresso mais avançado, mesmo sendo o mais antigo', () async {
    final avancado = _codigo({'faseLiberada': 30, 'estrelas_29': 3}, 1000);
    final recente = _codigo({'faseLiberada': 5}, 9000);
    expect(await CopiaDupla([_Falsa(guardado: recente), _Falsa(guardado: avancado)]).ler(), avancado);
    expect(await CopiaDupla([_Falsa(guardado: avancado), _Falsa(guardado: recente)]).ler(), avancado);
  });

  test('empate de progresso: vale o mais recente', () async {
    final velho = _codigo({'faseLiberada': 5}, 1000);
    final novo = _codigo({'faseLiberada': 5}, 2000);
    expect(await CopiaDupla([_Falsa(guardado: velho), _Falsa(guardado: novo)]).ler(), novo);
  });

  test('ignora cópia vazia ou lixo e devolve null se nada servir', () async {
    final bom = _codigo({'faseLiberada': 2}, 1000);
    expect(
      await CopiaDupla([_Falsa(guardado: Uint8List.fromList(utf8.encode('lixo'))), _Falsa(guardado: bom)]).ler(),
      bom,
    );
    expect(await CopiaDupla([_Falsa(), _Falsa(guardado: Uint8List(0))]).ler(), isNull);
  });
}

/// Play Games de mentira: começa desconectado e conecta quando o jogador toca em "Conectar".
class _ContaFalsa extends _Falsa implements ContaDoJogador {
  _ContaFalsa({this.aceita = true}) : super(nuvem: true);

  final bool aceita;
  String? logado;
  int pedidos = 0;

  @override
  Future<bool> conectar() async {
    pedidos++;
    if (aceita) logado = 'Agster';
    return aceita;
  }

  @override
  Future<String?> nome() async => logado;
}

void _contaTests() {
  group('conta do Play Games', () {
    test('sem suporte (fora do Android) não pede para conectar', () async {
      SharedPreferences.setMockInitialValues({});
      final auto = SalvamentoAutomatico(await Progresso.carregar(), _Falsa());
      expect(auto.suportaConta, isFalse);
      expect(await auto.conectar(), isFalse);
      expect(auto.conta.value, isNull);
    });

    test('desconectado: sem nome; ao conectar mostra o nome e já salva na conta', () async {
      SharedPreferences.setMockInitialValues({'faseLiberada': 4, 'partidas': 3});
      final conta = _ContaFalsa();
      final auto = SalvamentoAutomatico(await Progresso.carregar(), conta);
      expect(auto.suportaConta, isTrue);
      await auto.atualizarConta();
      expect(auto.conta.value, isNull);
      expect(await auto.conectar(), isTrue);
      expect(auto.conta.value, 'Agster');
      expect(conta.pedidos, 1);
      expect(conta.guardado, isNotNull);
    });

    test('o jogador recusa o login: continua sem nome e não salva', () async {
      SharedPreferences.setMockInitialValues({'faseLiberada': 4, 'partidas': 3});
      final conta = _ContaFalsa(aceita: false);
      final auto = SalvamentoAutomatico(await Progresso.carregar(), conta);
      expect(await auto.conectar(), isFalse);
      expect(auto.conta.value, isNull);
      expect(conta.guardado, isNull);
    });

    test('CopiaDupla repassa o nome e o pedido de conexão ao Play Games', () async {
      final conta = _ContaFalsa();
      final dupla = CopiaDupla([conta, _Falsa()]);
      expect(await dupla.nome(), isNull);
      expect(await dupla.conectar(), isTrue);
      expect(await dupla.nome(), 'Agster');
      expect(await CopiaDupla([_Falsa()]).conectar(), isFalse);
    });
  });
}
