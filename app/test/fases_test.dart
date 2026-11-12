import 'package:encaixa/jogo/fases.dart';
import 'package:encaixa/jogo/partida.dart';
import 'package:encaixa/jogo/robo.dart';
import 'package:flutter_test/flutter_test.dart';

/// Jogador automático simples: prefere limpar linhas, quebrar pedras e encostar peças.
/// Se ele vence, uma pessoa também vence.
({bool venceu, int estrelas, String motivo}) jogarSozinho(Fase fase) {
  final p = fase.novaPartida();
  while (!fase.concluida(p) && !fase.semPecas(p) && !p.fimDeJogo) {
    if (!jogada(p)) break;
  }
  return (
    venceu: fase.concluida(p),
    estrelas: fase.concluida(p) ? fase.estrelas(p) : 0,
    motivo: '${fase.progresso(p)}/${fase.alvo} ${p.fimDeJogo ? 'sem espaço' : 'sem peças'}',
  );
}

/// Faz a melhor jogada (do robô do jogo). Devolve `false` se nada coube.
bool jogada(Partida p) => Robo.jogar(p);

/// Melhor (peça, linha, coluna) do robô, ou `null` se nada cabe.
(int, int, int)? melhorJogada(Partida p) => Robo.melhorJogada(p);

void main() {
  test('fases são sempre iguais e as pedras não repetem casa', () {
    for (var n = 1; n <= Fase.total; n++) {
      final a = Fase.numero(n), b = Fase.numero(n);
      expect((a.objetivo, a.alvo, a.pecas, a.semente), (b.objetivo, b.alvo, b.pecas, b.semente));
      expect(a.inicial.map((c) => (c.$1, c.$2)).toSet(), hasLength(a.inicial.length), reason: 'casa repetida');
      expect(a.novaPartida().tabuleiro.linhasCompletas().linhas, isEmpty);
    }
  });

  test('todas as fases podem ser vencidas (jogador automático)', () {
    final relatorio = <String>[];
    for (var n = 1; n <= Fase.total; n++) {
      final f = Fase.numero(n);
      final r = jogarSozinho(f);
      relatorio.add(
        '$n ${f.objetivo.name} ${f.alvo}/${f.pecas}p: ${r.venceu ? '${r.estrelas}★' : 'PERDEU ${r.motivo}'}',
      );
    }
    printOnFailure(relatorio.join('\n'));
    expect(relatorio.where((l) => l.contains('PERDEU')), isEmpty);
  });

  test('estrelas pelas peças que sobram', () {
    final f = Fase.numero(1);
    final p = Partida(semente: 1);
    expect(f.estrelas(p), 3);
    p.jogadas = f.pecas - 1;
    expect(f.estrelas(p), 1);
  });
}
