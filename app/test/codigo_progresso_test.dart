import 'package:encaixa/servicos/codigo_progresso.dart';
import 'package:encaixa/servicos/progresso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monta um código "à mão" (com soma de verificação certa), como alguém mal-intencionado faria.
String _codigoFalso(Map<String, Object?> json) => CodigoProgresso.empacotar(json);

Future<Progresso> _progresso(Map<String, Object> valores) async {
  SharedPreferences.setMockInitialValues(valores);
  return Progresso.carregar();
}

void main() {
  test('gerar e ler devolvem o mesmo progresso', () {
    final dados = <String, Object?>{
      'gemas': 321,
      'faseLiberada': 47,
      'recorde': 5120,
      'estrelas_1': 3,
      'estrelas_46': 2,
      'temas': <String>['doce', 'neon'],
      'tema': 'neon',
      'som': false,
    };
    final codigo = CodigoProgresso.gerar(dados, agora: 1000);
    expect(codigo, startsWith('ENCAIXA1-'));
    final lido = CodigoProgresso.ler(codigo)!;
    expect(lido, {...dados, 'salvoEm': 1000});
    final r = CodigoProgresso.resumo(lido);
    expect((r.fase, r.estrelas, r.gemas, r.recorde), (47, 5, 321, 5120));
  });

  test('o código de 300 fases continua curto o bastante para copiar', () {
    final dados = <String, Object?>{'faseLiberada': 300, for (var n = 1; n <= 300; n++) 'estrelas_$n': 1 + n % 3};
    expect(CodigoProgresso.gerar(dados, agora: 1).length, lessThan(1200));
  });

  test('compras, partida em andamento e missões do dia ficam de fora', () {
    final codigo = CodigoProgresso.gerar({
      'gemas': 5,
      'assinante': true,
      'semAnuncios': true,
      'partida_classico': '{"pontos":99}',
      'missoesDia': 20261113,
      'missao_linhas': 7,
      'rodaGiros': 2,
    }, agora: 1);
    expect(CodigoProgresso.ler(codigo), {'gemas': 5, 'salvoEm': 1});
  });

  test('tolera espaços e quebras de linha (apps de mensagem) e letras minúsculas no prefixo', () {
    final codigo = CodigoProgresso.gerar({'gemas': 9}, agora: 5);
    final partido = codigo.replaceAllMapped(RegExp('.{20}'), (m) => '${m[0]}\n ');
    expect(CodigoProgresso.ler(partido), {'gemas': 9, 'salvoEm': 5});
    expect(CodigoProgresso.ler(codigo.replaceFirst('ENCAIXA1-', 'encaixa1-')), isNotNull);
  });

  test('recusa lixo, código cortado e prefixo errado', () {
    final codigo = CodigoProgresso.gerar({'gemas': 9}, agora: 5);
    expect(CodigoProgresso.ler(''), isNull);
    expect(CodigoProgresso.ler('ENCAIXA1-'), isNull);
    expect(CodigoProgresso.ler('oi, tudo bem?'), isNull);
    expect(CodigoProgresso.ler(codigo.substring(0, codigo.length - 12)), isNull, reason: 'cortado');
    expect(CodigoProgresso.ler(codigo.substring(0, codigo.length - 1)), isNull, reason: 'faltou 1 caractere');
    expect(CodigoProgresso.ler(codigo.replaceFirst('ENCAIXA1-', 'OUTRO-')), isNull);
    expect(CodigoProgresso.ler('ENCAIXA1-${'A' * 30000}'), isNull, reason: 'grande demais');
  });

  test('uma letra trocada no meio do código é pega pela soma de verificação', () {
    final dados = <String, Object?>{'gemas': 100, 'faseLiberada': 20, for (var n = 1; n < 20; n++) 'estrelas_$n': 3};
    final codigo = CodigoProgresso.gerar(dados, agora: 7);
    final meio = CodigoProgresso.prefixo.length + 30;
    for (final troca in ['A', 'B', 'z', '9']) {
      if (codigo[meio] == troca) continue;
      final errado = codigo.replaceRange(meio, meio + 1, troca);
      expect(CodigoProgresso.ler(errado), isNull, reason: 'trocou ${codigo[meio]} por $troca');
    }
  });

  test('código feito à mão: chave desconhecida é ignorada e tipo errado recusa tudo', () {
    final comIntruso = CodigoProgresso.ler(_codigoFalso({'gemas': 5, 'assinante': true, 'salvoEm': 9}));
    expect(comIntruso, {'gemas': 5, 'salvoEm': 9}, reason: '"assinante" não entra por código');
    expect(CodigoProgresso.ler(_codigoFalso({'gemas': 'muitas', 'salvoEm': 9})), isNull);
    expect(CodigoProgresso.ler(_codigoFalso({'gemas': -50, 'salvoEm': 9})), isNull);
    expect(CodigoProgresso.ler(_codigoFalso({'estrelas_3': 9, 'salvoEm': 9})), isNull);
    expect(CodigoProgresso.ler(_codigoFalso({'gemas': 5})), isNull, reason: 'sem data');
  });

  test('recuperar troca o progresso, mantém as compras do aparelho e mexe no tema', () async {
    final antigo = await _progresso({
      'gemas': 80,
      'faseLiberada': 31,
      'estrelas_30': 3,
      'temas': <String>['neon'],
    });
    final codigo = await antigo.gerarCodigo(2000);

    final novo = await _progresso({'gemas': 15, 'estrelas_2': 1, 'assinante': true, 'semAnuncios': true});
    final dados = CodigoProgresso.ler(codigo)!;
    expect(novo.codigoRecente(dados), isTrue);
    await novo.restaurarCodigo(dados);
    expect((novo.gemas, novo.faseLiberada, novo.estrelasDaFase(30)), (80, 31, 3));
    expect(novo.estrelasDaFase(2), 0, reason: 'o que não estava no código sai');
    expect((novo.assinante, novo.semAnuncios), (true, true), reason: 'compras do aparelho não mudam');
    expect(novo.temaAtivo.id, 'classico');
  });

  test('código velho não vale: não dá para gastar as gemas e colar o código antigo', () async {
    final p = await _progresso({'gemas': 100});
    final codigo = await p.gerarCodigo(5000);
    final dados = CodigoProgresso.ler(codigo)!;
    expect(p.codigoRecente(dados), isFalse, reason: 'é do progresso que já está aqui');
    await p.gerarCodigo(6000);
    expect(p.codigoRecente(dados), isFalse);
    // Em outro aparelho (nunca gerou nem recuperou nada) vale.
    final outro = await _progresso({});
    expect(outro.codigoRecente(dados), isTrue);
  });
}
