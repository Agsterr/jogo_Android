import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/peca.dart';
import 'package:encaixa/jogo/tabuleiro.dart';
import 'package:flutter_test/flutter_test.dart';

Partida _partidaComBlocos() {
  final p = Partida(semente: 4);
  for (var l = 2; l <= 5; l++) {
    for (var k = 2; k <= 5; k++) {
      p.tabuleiro.definir(l, k, (l + k) % 6);
    }
  }
  p.tabuleiro.definir(3, 3, Tabuleiro.pedra);
  return p;
}

void main() {
  group('Martelo', () {
    test('tira um bloco e só ele; não conta linha nem ponto', () {
      final p = _partidaComBlocos();
      final antes = (p.pontos, p.linhas, p.combo);
      final r = p.martelar(2, 2);
      expect(r.map((b) => (b.linha, b.coluna)), [(2, 2)]);
      expect(p.tabuleiro.cor(2, 2), isNull);
      expect(p.tabuleiro.cor(2, 3), isNotNull);
      expect((p.pontos, p.linhas, p.combo), antes);
    });

    test('não tira pedra, casa vazia nem casa fora do tabuleiro', () {
      final p = _partidaComBlocos();
      expect(p.martelar(3, 3), isEmpty, reason: 'pedra');
      expect(p.tabuleiro.cor(3, 3), Tabuleiro.pedra);
      expect(p.martelar(0, 0), isEmpty, reason: 'vazia');
      expect(p.martelar(-1, 4), isEmpty);
      expect(p.martelar(4, 8), isEmpty);
      expect(p.podeMartelar(3, 3), isFalse);
      expect(p.podeMartelar(2, 3), isTrue);
    });
  });

  group('Bomba', () {
    test('limpa o quadrado 3x3 e deixa as pedras', () {
      final p = _partidaComBlocos();
      final r = p.explodir(3, 3); // centro na pedra: tira os 8 vizinhos
      expect(r, hasLength(8));
      expect(p.tabuleiro.cor(3, 3), Tabuleiro.pedra, reason: 'a pedra do centro fica');
      for (final (l, k) in [(2, 2), (2, 3), (2, 4), (3, 2), (3, 4), (4, 2), (4, 3), (4, 4)]) {
        expect(p.tabuleiro.cor(l, k), isNull);
      }
      expect(p.tabuleiro.cor(5, 5), isNotNull, reason: 'fora do quadrado');
      expect(p.tabuleiro.pedras, 1);
    });

    test('na borda só leva o que existe; sem nada para tirar devolve vazio', () {
      final p = _partidaComBlocos();
      expect(p.explodir(2, 2), hasLength(3), reason: '(2,2), (2,3) e (3,2); a pedra (3,3) fica');
      // O quadrado 3x3 em volta de (0,0) não tem nada.
      expect(p.explodir(0, 0), isEmpty);
      expect(p.blocosDaBomba(0, 0), isEmpty);
    });

    test('quebrar pedra não acontece com a bomba (o objetivo de pedras não avança)', () {
      final p = _partidaComBlocos();
      final pedrasAntes = p.tabuleiro.pedras;
      p.explodir(3, 3);
      p.explodir(3, 4);
      p.martelar(3, 3);
      expect(p.tabuleiro.pedras, pedrasAntes);
    });
  });

  test('usar um reforço desliga o "Desfazer" (não volta por cima do reforço)', () {
    final p = _partidaComBlocos()
      ..mao = [
        Peca(Formato.desenho(['#']), 0),
        null,
        null,
      ];
    p.colocar(0, 0, 0);
    expect(p.podeDesfazer, isTrue);
    p.martelar(2, 2);
    expect(p.podeDesfazer, isFalse);
  });
}
