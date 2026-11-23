import 'sorteio.dart';

/// Baús de itens: só **aparência** (temas de blocos, molduras do tabuleiro e cores do mascote). Nada aqui muda a
/// pontuação, então não existe vantagem em nenhum modo. Os baús se **ganham jogando** (Desafio, Passe, álbum, sequência);
/// não há compra com dinheiro. As chances e a garantia aparecem na tela do baú.
enum Raridade {
  comum('Comum', 60, 5, 0xFF9AA5B8),
  raro('Raro', 28, 15, 0xFF3DA5FF),
  epico('Épico', 10, 40, 0xFFB65CFF),
  lendario('Lendário', 2, 100, 0xFFFFC62E);

  const Raridade(this.nome, this.chance, this.gemasDeRepetido, this.cor);

  final String nome;

  /// Chance de sair, em %. A soma é 100.
  final int chance;

  /// Gemas que o item vale quando já está no nível máximo e sai de novo.
  final int gemasDeRepetido;

  /// Cor em ARGB (a tela usa na moldura da carta).
  final int cor;
}

enum Categoria {
  tema('Tema de blocos'),
  moldura('Moldura do tabuleiro'),
  mascote('Cor do Quadrinho');

  const Categoria(this.nome);

  final String nome;
}

class ItemDeBau {
  const ItemDeBau(this.id, this.nome, this.categoria, this.raridade, this.cores);

  final String id;
  final String nome;
  final Categoria categoria;
  final Raridade raridade;

  /// Cores do item em ARGB: 6 para o tema, 3 para a moldura, 1 para o mascote.
  final List<int> cores;
}

/// Repetir um item o sobe de nível, até aqui. No máximo, vira gemas.
const nivelMaximoDoItem = 5;

/// Garantias: a cada [garantiaRaro] baús, pelo menos um raro ou melhor; a cada [garantiaLendario], um lendário.
const garantiaRaro = 10;
const garantiaLendario = 60;

abstract final class ItensDeBau {
  static const todos = <ItemDeBau>[
    // ---- comuns ----
    ItemDeBau('tema-menta', 'Menta', Categoria.tema, Raridade.comum, [
      0xFF2BD9A4, 0xFF7BE0FF, 0xFFFFE27A, 0xFFFF9EB5, 0xFF9BFF8F, 0xFFB69CFF, //
    ]),
    ItemDeBau('tema-morango', 'Morango', Categoria.tema, Raridade.comum, [
      0xFFFF4D6D, 0xFFFF8FA3, 0xFFFFC2D1, 0xFF9BE564, 0xFFFFB84D, 0xFFC9184A, //
    ]),
    ItemDeBau('moldura-gelo', 'Azul gelo', Categoria.moldura, Raridade.comum, [0xFF7BE0FF, 0xFF3DA5FF, 0xFFBFEFFF]),
    ItemDeBau('moldura-folha', 'Verde folha', Categoria.moldura, Raridade.comum, [0xFF9BFF8F, 0xFF2BD96B, 0xFF1F9D55]),
    ItemDeBau('mascote-rosa', 'Rosa', Categoria.mascote, Raridade.comum, [0xFFFF6FB1]),
    ItemDeBau('mascote-azul', 'Azul', Categoria.mascote, Raridade.comum, [0xFF3DA5FF]),
    // ---- raros ----
    ItemDeBau('tema-por-do-sol', 'Pôr do sol', Categoria.tema, Raridade.raro, [
      0xFFFF5E5B, 0xFFFF9B54, 0xFFFFD166, 0xFFEF476F, 0xFF9B5DE5, 0xFF2D1E8F, //
    ]),
    ItemDeBau('tema-lavanda', 'Lavanda', Categoria.tema, Raridade.raro, [
      0xFFB69CFF, 0xFF8E7DFF, 0xFFE0AAFF, 0xFF7BE0FF, 0xFFFFC6FF, 0xFF5E548E, //
    ]),
    ItemDeBau('moldura-fogo', 'Fogo', Categoria.moldura, Raridade.raro, [0xFFFFE066, 0xFFFF6A00, 0xFFFF2D2D]),
    ItemDeBau('moldura-neon', 'Neon', Categoria.moldura, Raridade.raro, [0xFF39FF14, 0xFF00F0FF, 0xFFFF00E5]),
    ItemDeBau('mascote-laranja', 'Laranja', Categoria.mascote, Raridade.raro, [0xFFFF8A00]),
    ItemDeBau('mascote-roxo', 'Roxo', Categoria.mascote, Raridade.raro, [0xFF9B5DE5]),
    // ---- épicos ----
    ItemDeBau('tema-esmeralda', 'Esmeralda', Categoria.tema, Raridade.epico, [
      0xFF00C48C, 0xFF00F5A0, 0xFF7CFFCB, 0xFF0A9396, 0xFFE9FF70, 0xFF005F73, //
    ]),
    ItemDeBau('moldura-arco-iris', 'Arco-íris', Categoria.moldura, Raridade.epico, [
      0xFFFF3D6E, 0xFFFFD000, 0xFF00E08A, //
    ]),
    ItemDeBau('mascote-dourado', 'Dourado', Categoria.mascote, Raridade.epico, [0xFFFFC62E]),
    // ---- lendários ----
    ItemDeBau('tema-ouro-real', 'Ouro real', Categoria.tema, Raridade.lendario, [
      0xFFFFD700, 0xFFFFA500, 0xFFFFF1A8, 0xFFB8860B, 0xFFFFE9A3, 0xFFDAA520, //
    ]),
    ItemDeBau('moldura-ouro', 'Ouro', Categoria.moldura, Raridade.lendario, [0xFFFFF1A8, 0xFFFFD700, 0xFFB8860B]),
    ItemDeBau('mascote-cosmico', 'Cósmico', Categoria.mascote, Raridade.lendario, [0xFF6C4DFF]),
  ];

  static ItemDeBau? porId(String id) {
    for (final i in todos) {
      if (i.id == id) return i;
    }
    return null;
  }

  static List<ItemDeBau> da(Raridade r) => todos.where((i) => i.raridade == r).toList();
}

/// Contadores da garantia (guardados no aparelho).
class EstadoDoBau {
  const EstadoDoBau({this.semRaro = 0, this.semLendario = 0});

  /// Baús seguidos sem raro nem melhor / sem lendário.
  final int semRaro, semLendario;
}

class ResultadoDoSorteio {
  const ResultadoDoSorteio(this.item, this.estado, {required this.garantido});

  final ItemDeBau item;
  final EstadoDoBau estado;

  /// Este baú estava na garantia (raro ou melhor, ou lendário, de qualquer forma).
  final bool garantido;
}

/// Sorteia um item. Chances: [Raridade.chance]; a garantia vale no baú de número [garantiaRaro] e [garantiaLendario].
/// Com a mesma [sorteio] e o mesmo [estado] o resultado é sempre o mesmo.
ResultadoDoSorteio sortearBau(Sorteio sorteio, EstadoDoBau estado) {
  final lendarioGarantido = estado.semLendario + 1 >= garantiaLendario;
  final raroGarantido = estado.semRaro + 1 >= garantiaRaro;
  late Raridade raridade;
  if (lendarioGarantido) {
    raridade = Raridade.lendario;
  } else {
    // Se o raro é garantido, o sorteio só considera raro, épico e lendário (na proporção das chances).
    final candidatas = [
      for (final r in Raridade.values)
        if (!raroGarantido || r != Raridade.comum) r,
    ];
    var alvo = sorteio.proximo(candidatas.fold(0, (soma, r) => soma + r.chance));
    raridade = candidatas.last;
    for (final r in candidatas) {
      if (alvo < r.chance) {
        raridade = r;
        break;
      }
      alvo -= r.chance;
    }
  }
  final grupo = ItensDeBau.da(raridade);
  final item = grupo[sorteio.proximo(grupo.length)];
  final novo = EstadoDoBau(
    semRaro: raridade == Raridade.comum ? estado.semRaro + 1 : 0,
    semLendario: raridade == Raridade.lendario ? 0 : estado.semLendario + 1,
  );
  return ResultadoDoSorteio(item, novo, garantido: lendarioGarantido || raroGarantido);
}
