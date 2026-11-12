import 'dart:ui' show Color;

/// Visual das peças (6 cores). Itens cosméticos: gemas, assinatura ou evento.
class TemaDeBlocos {
  const TemaDeBlocos(this.id, this.nome, this.cores, {this.preco = 0, this.assinante = false, this.evento});

  final String id;
  final String nome;
  final List<Color> cores;

  /// Preço em gemas (0 = grátis ou não se compra com gemas).
  final int preco;

  /// Só para assinantes Encaixa+.
  final bool assinante;

  /// Id do evento que libera o tema de graça enquanto durar.
  final String? evento;

  static const classico = TemaDeBlocos('classico', 'Clássico', [
    Color(0xFFFF5A6E),
    Color(0xFFFF9F1C),
    Color(0xFFFFD23F),
    Color(0xFF3DDC84),
    Color(0xFF2EC4F1),
    Color(0xFFA96BFF),
  ]);

  static const todos = [
    classico,
    TemaDeBlocos('doce', 'Doce', [
      Color(0xFFFF8FB1),
      Color(0xFFFFB37A),
      Color(0xFFFFE38A),
      Color(0xFF9BE8B4),
      Color(0xFF8FD3FF),
      Color(0xFFC9A7FF),
    ], preco: 150),
    TemaDeBlocos('oceano', 'Oceano', [
      Color(0xFF0FB5AE),
      Color(0xFF2E86DE),
      Color(0xFF48DBFB),
      Color(0xFF1DD1A1),
      Color(0xFF5F27CD),
      Color(0xFFC8D6E5),
    ], preco: 200),
    TemaDeBlocos('neon', 'Neon', [
      Color(0xFFFF2E88),
      Color(0xFFFF6B00),
      Color(0xFFE5FF00),
      Color(0xFF00FF9C),
      Color(0xFF00E5FF),
      Color(0xFFB026FF),
    ], preco: 300),
    TemaDeBlocos('galaxia', 'Galáxia', [
      Color(0xFFE056FD),
      Color(0xFF686DE0),
      Color(0xFFF9CA24),
      Color(0xFF7ED6DF),
      Color(0xFF4834D4),
      Color(0xFFFFFFFF),
    ], assinante: true),
    TemaDeBlocos('natal', 'Natal', [
      Color(0xFFE53935),
      Color(0xFF2E7D32),
      Color(0xFFFFD54F),
      Color(0xFFFFFFFF),
      Color(0xFF66BB6A),
      Color(0xFFC62828),
    ], evento: 'natal-2026'),
  ];

  static TemaDeBlocos porId(String? id) => todos.firstWhere((t) => t.id == id, orElse: () => classico);
}
