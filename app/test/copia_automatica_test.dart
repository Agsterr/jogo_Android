import 'dart:convert';
import 'dart:typed_data';

import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/servicos/copia_automatica.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:encaixa/telas/inicio_tela.dart';
import 'package:encaixa/telas/progresso_tela.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'suporte/capturas.dart';

/// Block Store de mentira: guarda os bytes fora do "celular", como o Google guarda (sobrevive à reinstalação).
class _BlockStoreFalso implements CopiaAutomatica {
  _BlockStoreFalso({this.nuvem = true, this.indisponivel = false});

  final bool nuvem;
  final bool indisponivel;
  Uint8List? guardado;
  int gravacoes = 0;

  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async {
    if (indisponivel) return const ResultadoCopia(ok: false);
    gravacoes++;
    guardado = bytes;
    return ResultadoCopia(ok: true, nuvem: nuvem);
  }

  @override
  Future<Uint8List?> ler() async => indisponivel ? null : guardado;
}

class _Explosivo implements CopiaAutomatica {
  @override
  Future<ResultadoCopia> salvar(Uint8List bytes) async => throw StateError('quebrou');

  @override
  Future<Uint8List?> ler() async => throw StateError('quebrou');
}

/// "Instala" o jogo num celular: SharedPreferences novo com [valores].
Future<Progresso> _instalar(Map<String, Object> valores) async {
  SharedPreferences.setMockInitialValues(valores);
  return Progresso.carregar();
}

const _jogador = <String, Object>{
  'gemas': 120,
  'faseLiberada': 31,
  'recorde': 6400,
  'partidas': 40,
  'estrelas_29': 3,
  'estrelas_30': 2,
};

void main() {
  setUpAll(carregarFontes);

  test('reinstalar: o progresso volta sozinho do Block Store', () async {
    final bloco = _BlockStoreFalso();
    final antes = await _instalar(_jogador);
    await SalvamentoAutomatico(antes, bloco).salvarAgora();
    expect(bloco.guardado, isNotNull);
    expect(bloco.guardado!.length, lessThan(SalvamentoAutomatico.limiteDeBytes));

    // Desinstalou e instalou de novo: os dados do app sumiram, o Block Store ficou.
    final depois = await _instalar({});
    expect(depois.faseLiberada, 1);
    final recuperou = await SalvamentoAutomatico(depois, bloco).recuperarSeVazio();
    expect(recuperou, isTrue);
    expect((depois.faseLiberada, depois.gemas, depois.recorde, depois.estrelasDaFase(29)), (31, 120, 6400, 3));
    expect(depois.recuperadoAutomaticamente, isTrue);
  });

  test('não mexe em quem já tem progresso (não troca o progresso por uma cópia velha)', () async {
    final bloco = _BlockStoreFalso();
    final velho = await _instalar({'faseLiberada': 5, 'partidas': 8, 'gemas': 10});
    await SalvamentoAutomatico(velho, bloco).salvarAgora();

    final atual = await _instalar({'faseLiberada': 20, 'partidas': 50, 'gemas': 99});
    expect(await SalvamentoAutomatico(atual, bloco).recuperarSeVazio(), isFalse);
    expect(atual.faseLiberada, 20);
  });

  test('progresso vazio nunca é gravado (não apaga a cópia boa antes de recuperá-la)', () async {
    final bloco = _BlockStoreFalso();
    final bom = await _instalar(_jogador);
    await SalvamentoAutomatico(bom, bloco).salvarAgora();
    final guardadoAntes = bloco.guardado;

    final novo = await _instalar({}); // celular recém-instalado
    final auto = SalvamentoAutomatico(novo, bloco);
    await auto.salvarAgora();
    expect(bloco.guardado, guardadoAntes);
    expect(bloco.gravacoes, 1);
  });

  test('nada guardado, lixo guardado ou Google indisponível: segue sem recuperar e sem erro', () async {
    final p = await _instalar({});
    expect(await SalvamentoAutomatico(p, _BlockStoreFalso()).recuperarSeVazio(), isFalse);

    final lixo = _BlockStoreFalso()..guardado = Uint8List.fromList(utf8.encode('isto não é um código'));
    expect(await SalvamentoAutomatico(p, lixo).recuperarSeVazio(), isFalse);

    expect(await SalvamentoAutomatico(p, _BlockStoreFalso(indisponivel: true)).recuperarSeVazio(), isFalse);
    expect(await SalvamentoAutomatico(p, const SemCopia()).recuperarSeVazio(), isFalse);
    expect(p.faseLiberada, 1);
  });

  test('uma cópia que quebra não derruba o jogo', () async {
    final p = await _instalar(_jogador);
    final auto = SalvamentoAutomatico(p, _Explosivo());
    await auto.salvarAgora();
    expect(auto.status.value.estado, EstadoCopia.indisponivel);
    final novo = await _instalar({});
    expect(await SalvamentoAutomatico(novo, _Explosivo()).recuperarSeVazio(), isFalse);
  });

  test('o estado mostrado ao jogador acompanha o resultado', () async {
    final p = await _instalar(_jogador);
    final agora = DateTime(2026, 11, 22, 14, 5);
    for (final (copia, esperado) in [
      (_BlockStoreFalso(), EstadoCopia.naNuvem),
      (_BlockStoreFalso(nuvem: false), EstadoCopia.soNoCelular),
      (_BlockStoreFalso(indisponivel: true), EstadoCopia.indisponivel),
    ]) {
      final auto = SalvamentoAutomatico(p, copia, relogio: () => agora);
      expect(auto.status.value.estado, EstadoCopia.aindaNao);
      await auto.salvarAgora();
      expect(auto.status.value.estado, esperado);
      expect(auto.status.value.quando, agora);
    }
  });

  test('o que foi guardado é um código de progresso válido (e sem compras)', () async {
    final bloco = _BlockStoreFalso();
    final p = await _instalar({..._jogador, 'assinante': true});
    await SalvamentoAutomatico(p, bloco).salvarAgora();
    final dados = CodigoProgresso.ler(utf8.decode(bloco.guardado!))!;
    expect(dados['faseLiberada'], 31);
    expect(dados.containsKey('assinante'), isFalse);
  });

  testWidgets('salva sozinho depois da pausa; várias mudanças seguidas viram uma gravação só', (tester) async {
    final bloco = _BlockStoreFalso();
    final p = await _instalar(_jogador);
    final auto = SalvamentoAutomatico(p, bloco, pausa: const Duration(seconds: 5))..iniciar();
    addTearDown(auto.dispose);

    await p.ganharGemas(5);
    await tester.pump(const Duration(seconds: 2));
    await p.ganharGemas(5);
    await tester.pump(const Duration(seconds: 2));
    expect(bloco.gravacoes, 0, reason: 'ainda dentro da pausa');
    await tester.pump(const Duration(seconds: 6));
    expect(bloco.gravacoes, 1);
    expect(CodigoProgresso.ler(utf8.decode(bloco.guardado!))!['gemas'], 130);
  });

  testWidgets('tela Salvar progresso mostra que a cópia automática está ligada', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: _jogador, copia: _BlockStoreFalso());
    await tester.pumpWidget(appDeTeste(s, tela: ProgressoTela(servicos: s)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cópia automática ligada'), findsOneWidget);
    expect(find.textContaining('Última cópia: 09:00'), findsOneWidget);
    await capturar(tester, '30-copia-automatica');
  });

  testWidgets('tela Salvar progresso avisa quando a cópia automática não funciona', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: _jogador, copia: _BlockStoreFalso(indisponivel: true));
    await tester.pumpWidget(appDeTeste(s, tela: ProgressoTela(servicos: s)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Cópia automática indisponível'), findsOneWidget);
    expect(find.textContaining('Use o código abaixo'), findsOneWidget);
    await capturar(tester, '31-copia-indisponivel');
  });

  testWidgets('tela inicial avisa uma vez que o progresso foi recuperado sozinho', (tester) async {
    telaDeCelular(tester);
    final s = await servicosDeTeste(valores: _jogador);
    s.progresso.recuperadoAutomaticamente = true;
    await tester.pumpWidget(appDeTeste(s, tela: InicioTela(servicos: s)));
    await tester.pumpAndSettle();
    expect(find.text('Progresso recuperado!'), findsWidgets);
    expect(find.textContaining('Fase 31 ·'), findsOneWidget);
    expect(s.progresso.recuperadoAutomaticamente, isFalse);
    await capturar(tester, '32-recuperado-sozinho');
    await tester.tap(find.text('CONTINUAR').first);
    await tester.pumpAndSettle();
    expect(find.text('Progresso recuperado!'), findsNothing);
  });
}
