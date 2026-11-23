/// Álbum de figurinhas: uma nova a cada Desafio do dia concluído e a cada baú de missões aberto.
/// Regras em Dart puro; o desenho (ícone e cor) fica na tela.
class Figurinha {
  const Figurinha(this.id, this.nome, this.icone, this.cor);

  final String id;
  final String nome;

  /// Nome do ícone (a tela traduz para o ícone do Material).
  final String icone;

  /// Cor em ARGB.
  final int cor;
}

class Album {
  const Album(this.id, this.nome, this.figurinhas, {this.premioGemas = 100});

  final String id;
  final String nome;
  final List<Figurinha> figurinhas;

  /// Gemas ao completar o álbum.
  final int premioGemas;

  int quantas(Set<String> tenho) => figurinhas.where((f) => tenho.contains(f.id)).length;

  bool completo(Set<String> tenho) => quantas(tenho) == figurinhas.length;

  static const tesouros = Album('tesouros', 'Tesouros', [
    Figurinha('estrela', 'Estrela', 'star', 0xFFFFC62E),
    Figurinha('lua', 'Lua', 'moon', 0xFF8B5CFF),
    Figurinha('sol', 'Sol', 'sun', 0xFFFF8A00),
    Figurinha('raio', 'Raio', 'bolt', 0xFFFFE066),
    Figurinha('coracao', 'Coração', 'heart', 0xFFFF3D6E),
    Figurinha('coroa', 'Coroa', 'crown', 0xFFFFB800),
    Figurinha('foguete', 'Foguete', 'rocket', 0xFF00B4FF),
    Figurinha('chave', 'Chave', 'key', 0xFFB7C0D8),
    Figurinha('diamante', 'Diamante', 'diamond', 0xFF22E3C0),
    Figurinha('trofeu', 'Troféu', 'trophy', 0xFFFFC62E),
    Figurinha('flor', 'Flor', 'flower', 0xFFFF5FA2),
    Figurinha('nuvem', 'Nuvem', 'cloud', 0xFF7FD3FF),
  ]);

  static const natureza = Album('natureza', 'Natureza', [
    Figurinha('folha', 'Folha', 'leaf', 0xFF3DDC84),
    Figurinha('gota', 'Gota', 'drop', 0xFF2DA8FF),
    Figurinha('fogo', 'Fogo', 'fire', 0xFFFF5A1F),
    Figurinha('gelo', 'Gelo', 'snow', 0xFF9BE7FF),
    Figurinha('montanha', 'Montanha', 'mountain', 0xFF9C7A5B),
    Figurinha('arvore', 'Árvore', 'tree', 0xFF1FAF5A),
    Figurinha('patinha', 'Patinha', 'paw', 0xFFFF8FB1),
    Figurinha('abelha', 'Abelha', 'bee', 0xFFFFD000),
    Figurinha('vento', 'Vento', 'wind', 0xFFB3E5FC),
    Figurinha('praia', 'Praia', 'beach', 0xFFFF9F43),
    Figurinha('grama', 'Grama', 'grass', 0xFF7ED957),
    Figurinha('trovao', 'Trovão', 'storm', 0xFF6C63FF),
  ]);

  /// Em ordem: o seguinte só aparece quando o anterior está completo.
  static const todos = [tesouros, natureza];

  /// Álbuns que o jogador já pode ver (o primeiro e os seguintes a um álbum completo).
  static List<Album> liberados(Set<String> tenho) {
    final lista = <Album>[];
    for (final a in todos) {
      lista.add(a);
      if (!a.completo(tenho)) break;
    }
    return lista;
  }

  /// Sorteia uma figurinha que o jogador ainda não tem, do primeiro álbum incompleto (nunca repete).
  /// `null` quando todos os álbuns estão completos. A mesma [semente] dá a mesma figurinha.
  static ({Album album, Figurinha figurinha})? sortear(Set<String> tenho, int semente) {
    for (final a in todos) {
      final faltam = a.figurinhas.where((f) => !tenho.contains(f.id)).toList();
      if (faltam.isEmpty) continue;
      return (album: a, figurinha: faltam[semente.abs() % faltam.length]);
    }
    return null;
  }

  static Album? doAlbum(String figurinhaId) {
    for (final a in todos) {
      if (a.figurinhas.any((f) => f.id == figurinhaId)) return a;
    }
    return null;
  }
}
