import 'package:encaixa/servicos/compras.dart';
import 'package:flutter_test/flutter_test.dart';

/// Preços cadastrados no Play Console (docs/MONETIZACAO.md). O app mostra o que o Play devolve; aqui só conferimos que a
/// conta das gemas faz sentido: pacote maior custa mais, e quanto maior, mais gemas por real.
void main() {
  const preco = {'gemas_100': 4.89, 'gemas_300': 12.99, 'gemas_1000': 34.99, Produtos.gemasEvento: 9.99};
  final gemas = {...Produtos.gemas, Produtos.gemasEvento: Produtos.qtdGemasEvento};

  test('mais gemas custam mais (nenhum pacote menor é mais caro que um maior)', () {
    final ordem = gemas.keys.toList()..sort((a, b) => gemas[a]!.compareTo(gemas[b]!));
    for (var i = 1; i < ordem.length; i++) {
      expect(
        preco[ordem[i]]!,
        greaterThan(preco[ordem[i - 1]]!),
        reason: '${ordem[i]} deveria custar mais que ${ordem[i - 1]}',
      );
    }
  });

  test('gemas por real: cresce com o tamanho do pacote e a oferta do evento não bate o melhor pacote', () {
    double taxa(String id) => gemas[id]! / preco[id]!;
    expect(taxa('gemas_300'), greaterThan(taxa('gemas_100')));
    expect(taxa('gemas_1000'), greaterThan(taxa('gemas_300')));
    expect(taxa(Produtos.gemasEvento), greaterThan(taxa('gemas_300')), reason: 'oferta tem que ser vantajosa');
    expect(taxa(Produtos.gemasEvento), lessThan(taxa('gemas_1000')), reason: 'mas não melhor que o pacote de 1000');
  });
}
