import 'package:encaixa/jogo/missoes.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Progresso> _progresso([Map<String, Object> v = const {}]) async {
  SharedPreferences.setMockInitialValues(v);
  return Progresso.carregar();
}

void main() {
  const hoje = 20261112;

  test('3 missões de tipos diferentes, iguais no mesmo dia', () {
    final a = missoesDoDia(hoje), b = missoesDoDia(hoje);
    expect(a.map((m) => m.texto), b.map((m) => m.texto));
    expect(a.map((m) => m.tipo).toSet(), hasLength(missoesPorDia));
    expect(missoesDoDia(20261113).map((m) => m.texto), isNot(a.map((m) => m.texto)));
  });

  test('dia anterior atravessa mês e ano', () {
    expect(diaAnterior(20261201), 20261130);
    expect(diaAnterior(20270101), 20261231);
  });

  test('progresso soma, guarda o máximo e zera no dia seguinte', () async {
    final p = await _progresso();
    await p.contarMissao(hoje, TipoMissao.linhas, 3);
    await p.contarMissao(hoje, TipoMissao.linhas, 4);
    await p.contarMissao(hoje, TipoMissao.combo, 5);
    await p.contarMissao(hoje, TipoMissao.combo, 2);
    expect(p.progressoMissao(hoje, TipoMissao.linhas), 7);
    expect(p.progressoMissao(hoje, TipoMissao.combo), 5);
    expect(p.progressoMissao(20261113, TipoMissao.linhas), 0);
  });

  test('pegar missões e abrir o baú dá gemas uma vez só', () async {
    final p = await _progresso({'gemas': 0});
    final missoes = missoesDoDia(hoje);
    expect(await p.pegarMissao(hoje, 0), isFalse, reason: 'ainda não concluída');
    for (final m in missoes) {
      await p.contarMissao(hoje, m.tipo, m.alvo);
    }
    expect(await p.abrirBau(hoje), isFalse, reason: 'precisa pegar as 3 antes');
    for (var i = 0; i < missoesPorDia; i++) {
      expect(await p.pegarMissao(hoje, i), isTrue);
      expect(await p.pegarMissao(hoje, i), isFalse);
    }
    expect(await p.abrirBau(hoje), isTrue);
    expect(await p.abrirBau(hoje), isFalse);
    expect(p.gemas, missoes.fold(0, (s, m) => s + m.gemas) + gemasDoBau);
  });

  test('sequência de dias cresce, dá prêmio no 3º dia e zera se pular', () async {
    final p = await _progresso({'gemas': 0});
    expect(await p.concluirDesafio(20261110, 100), 5);
    expect(await p.concluirDesafio(20261111, 100), 5);
    expect(await p.concluirDesafio(20261112, 100), 5 + 5, reason: 'prêmio de 3 dias');
    expect(p.sequencia(20261112), 3);
    expect(p.sequencia(20261113), 3, reason: 'ainda dá para jogar hoje');
    expect(p.sequencia(20261114), 0, reason: 'pulou um dia');
    await p.concluirDesafio(20261114, 100);
    expect(p.sequencia(20261114), 1);
    expect(await p.concluirDesafio(20261114, 50), 0, reason: 'repetir não dá gemas');
  });

  test('presente de 7 dias: segue em dias seguidos e recomeça se pular', () async {
    final p = await _progresso({'gemas': 0});
    expect(await p.pegarPresente(20261110), 5);
    expect(await p.pegarPresente(20261110), 0, reason: 'uma vez por dia');
    expect(await p.pegarPresente(20261111), 5);
    expect(await p.pegarPresente(20261112), 10);
    expect(p.presenteDeHoje(20261114), 1, reason: 'pulou o dia 13');
    for (var d = 13; d <= 16; d++) {
      await p.pegarPresente(20261100 + d);
    }
    expect(p.presentePego(20261116), 7);
    expect(p.presenteDeHoje(20261117), 1, reason: 'depois do 7º recomeça');
  });

  test('recuperar sequência: só se pulou um dia e no máximo 1 vez por semana', () async {
    final p = await _progresso({'desafioFeito': 20261110, 'sequencia': 6});
    expect(p.sequencia(20261112), 0);
    expect(p.sequenciaPerdida(20261112), 6);
    expect(p.sequenciaPerdida(20261113), 0, reason: 'pulou dois dias');
    expect(await p.recuperarSequencia(20261112), isTrue);
    expect(p.sequencia(20261112), 6);
    await p.concluirDesafio(20261112, 10);
    expect(p.sequencia(20261112), 7);
    // pula de novo 3 dias depois: ainda não passou uma semana
    expect(p.sequenciaPerdida(20261114), 0);
  });
}
