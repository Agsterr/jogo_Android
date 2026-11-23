import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'jogo/tabuleiro.dart';
import 'jogo/temas.dart';

/// Cores e desenho dos blocos. A arte do jogo é toda vetorial, feita aqui.
abstract final class Cores {
  static const fundoTopo = Color(0xFF4A1BC2);
  static const fundoBase = Color(0xFF16074A);
  static const painel = Color(0xFF14063F);
  static const casa = Color(0xFF2A1670);
  static const brilhoRosa = Color(0xFFFF2E97);
  static const brilhoCiano = Color(0xFF00D9FF);
  static const texto = Color(0xFFF5F1FF);
  static const textoFraco = Color(0xFFB4A8E0);
  static const gema = Color(0xFF3FE0D0);
  static const ouro = Color(0xFFFFCC33);
  static const destaque = Color(0xFFFF2E7E);
  static const pedra = Color(0xFF8E8AA6);

  /// Uma cor por tipo de bloco (o índice vem de `Peca.cor`).
  static const blocos = [
    Color(0xFFFF3D6E), // coral
    Color(0xFFFF8A00), // laranja
    Color(0xFFFFD000), // amarelo
    Color(0xFF00E08A), // verde
    Color(0xFF00B4FF), // azul
    Color(0xFFA64DFF), // roxo
  ];

  /// Cores das peças: mudam com o tema escolhido na loja (`Progresso.usarTema`).
  static List<Color> pecas = TemaDeBlocos.classico.cores;

  /// Cores da moldura do tabuleiro (3) e do mascote (`null` = a cor padrão): vêm dos itens equipados da coleção.
  static List<Color> moldura = const [brilhoRosa, Color(0xFF8B5CFF), brilhoCiano];
  static Color? mascote;

  /// Desenha um símbolo em cada cor de bloco (modo para daltônicos; `Progresso.alternarSimbolos`).
  static bool simbolos = false;

  static const fundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [fundoTopo, fundoBase],
  );
}

const fonteJogo = 'Fredoka';

ThemeData temaDoJogo() {
  final base = ThemeData(
    brightness: Brightness.dark,
    fontFamily: fonteJogo,
    colorScheme: ColorScheme.fromSeed(seedColor: Cores.blocos[5], brightness: Brightness.dark, surface: Cores.painel),
    scaffoldBackgroundColor: Cores.fundoBase,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: Cores.texto, displayColor: Cores.texto),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontFamily: fonteJogo, fontSize: 18, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

/// Desenha um bloco "bala de goma": base 3D, degradê vivo, borda de luz e brilho.
void pintarBloco(Canvas canvas, Rect r, Color cor, {double opacidade = 1, int? indice}) {
  final raio = Radius.circular(r.width * 0.22);
  final escura = Color.lerp(cor, Colors.black, 0.4)!;
  final clara = Color.lerp(cor, Colors.white, 0.45)!;
  Color o(Color c, [double a = 1]) => c.withValues(alpha: c.a * a * opacidade);

  // Lateral escura embaixo (dá volume).
  canvas.drawRRect(RRect.fromRectAndRadius(r, raio), Paint()..color = o(escura));
  // Corpo com degradê.
  final corpo = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - r.height * 0.13);
  final rr = RRect.fromRectAndRadius(corpo, raio);
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [o(clara), o(cor), o(Color.lerp(cor, escura, 0.25)!)],
        stops: const [0, 0.55, 1],
      ).createShader(corpo),
  );
  // Borda de luz por dentro.
  canvas.drawRRect(
    rr.deflate(r.width * 0.03),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r.width * 0.04
      ..color = o(Colors.white, 0.28),
  );
  // Brilho no alto e pontinho de reflexo.
  final brilho = Rect.fromLTWH(r.left + r.width * 0.14, r.top + r.height * 0.1, r.width * 0.48, r.height * 0.16);
  canvas.drawRRect(
    RRect.fromRectAndRadius(brilho, Radius.circular(brilho.height)),
    Paint()..color = o(Colors.white, 0.6),
  );
  canvas.drawCircle(
    Offset(r.left + r.width * 0.75, r.top + r.height * 0.18),
    r.width * 0.06,
    Paint()..color = o(Colors.white, 0.7),
  );
  if (Cores.simbolos && indice != null) _pintarSimbolo(canvas, corpo, indice, opacidade);
}

/// Um símbolo diferente para cada uma das 6 cores: círculo, triângulo, losango, estrela, cruz e quadrado.
void _pintarSimbolo(Canvas canvas, Rect corpo, int indice, double opacidade) {
  final c = corpo.center;
  final s = corpo.shortestSide * 0.24;
  final Path p;
  switch (indice % 6) {
    case 0:
      p = Path()..addOval(Rect.fromCircle(center: c, radius: s));
    case 1:
      p = Path()
        ..moveTo(c.dx, c.dy - s * 1.1)
        ..lineTo(c.dx + s * 1.1, c.dy + s * 0.9)
        ..lineTo(c.dx - s * 1.1, c.dy + s * 0.9)
        ..close();
    case 2:
      p = Path()
        ..moveTo(c.dx, c.dy - s * 1.2)
        ..lineTo(c.dx + s * 1.2, c.dy)
        ..lineTo(c.dx, c.dy + s * 1.2)
        ..lineTo(c.dx - s * 1.2, c.dy)
        ..close();
    case 3:
      p = Path()
        ..moveTo(c.dx, c.dy - s * 1.4)
        ..lineTo(c.dx + s * 0.4, c.dy - s * 0.4)
        ..lineTo(c.dx + s * 1.4, c.dy)
        ..lineTo(c.dx + s * 0.4, c.dy + s * 0.4)
        ..lineTo(c.dx, c.dy + s * 1.4)
        ..lineTo(c.dx - s * 0.4, c.dy + s * 0.4)
        ..lineTo(c.dx - s * 1.4, c.dy)
        ..lineTo(c.dx - s * 0.4, c.dy - s * 0.4)
        ..close();
    case 4:
      final e = s * 0.42;
      p = Path()
        ..moveTo(c.dx - e, c.dy - s * 1.2)
        ..lineTo(c.dx + e, c.dy - s * 1.2)
        ..lineTo(c.dx + e, c.dy - e)
        ..lineTo(c.dx + s * 1.2, c.dy - e)
        ..lineTo(c.dx + s * 1.2, c.dy + e)
        ..lineTo(c.dx + e, c.dy + e)
        ..lineTo(c.dx + e, c.dy + s * 1.2)
        ..lineTo(c.dx - e, c.dy + s * 1.2)
        ..lineTo(c.dx - e, c.dy + e)
        ..lineTo(c.dx - s * 1.2, c.dy + e)
        ..lineTo(c.dx - s * 1.2, c.dy - e)
        ..lineTo(c.dx - e, c.dy - e)
        ..close();
    default:
      p = Path()..addRect(Rect.fromCenter(center: c, width: s * 1.8, height: s * 1.8));
  }
  canvas
    ..drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = corpo.width * 0.07
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withValues(alpha: 0.45 * opacidade),
    )
    ..drawPath(p, Paint()..color = Colors.white.withValues(alpha: 0.95 * opacidade));
}

/// Marcador dos blocos especiais: bomba (bola escura com pavio) e joia (losango brilhante).
void pintarMarcador(Canvas canvas, Rect r, int tipo, {double opacidade = 1}) {
  final c = Offset(r.center.dx, r.center.dy - r.height * 0.05);
  final s = r.shortestSide;
  double a(double v) => v * opacidade;
  if (tipo == Tabuleiro.bomba) {
    canvas
      ..drawCircle(c.translate(0, s * 0.03), s * 0.27, Paint()..color = const Color(0xFF14102B).withValues(alpha: a(1)))
      ..drawCircle(c.translate(-s * 0.09, -s * 0.07), s * 0.07, Paint()..color = Colors.white.withValues(alpha: a(0.7)))
      ..drawLine(
        c.translate(s * 0.14, -s * 0.22),
        c.translate(s * 0.24, -s * 0.34),
        Paint()
          ..color = Colors.white.withValues(alpha: a(0.9))
          ..strokeWidth = s * 0.05
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        c.translate(s * 0.26, -s * 0.36),
        s * 0.07,
        Paint()..color = const Color(0xFFFFD000).withValues(alpha: a(1)),
      );
  } else if (tipo == Tabuleiro.gelo || tipo == Tabuleiro.rachado) {
    // Gelo: véu azul-claro com flocos; rachado: o mesmo, mais fino, com rachaduras.
    final veu = RRect.fromRectAndRadius(r.deflate(s * 0.02), Radius.circular(s * 0.2));
    canvas.drawRRect(
      veu,
      Paint()..color = const Color(0xFFBFEFFF).withValues(alpha: a(tipo == Tabuleiro.gelo ? 0.62 : 0.3)),
    );
    final traco = Paint()
      ..color = (tipo == Tabuleiro.gelo ? Colors.white : const Color(0xFF123B66)).withValues(alpha: a(0.9))
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round;
    if (tipo == Tabuleiro.gelo) {
      canvas
        ..drawLine(c.translate(-s * 0.2, 0), c.translate(s * 0.2, 0), traco)
        ..drawLine(c.translate(0, -s * 0.2), c.translate(0, s * 0.2), traco)
        ..drawLine(c.translate(-s * 0.14, -s * 0.14), c.translate(s * 0.14, s * 0.14), traco)
        ..drawLine(c.translate(-s * 0.14, s * 0.14), c.translate(s * 0.14, -s * 0.14), traco);
    } else {
      canvas
        ..drawLine(c.translate(-s * 0.05, -s * 0.28), c.translate(s * 0.05, -s * 0.06), traco)
        ..drawLine(c.translate(s * 0.05, -s * 0.06), c.translate(-s * 0.08, s * 0.1), traco)
        ..drawLine(c.translate(-s * 0.08, s * 0.1), c.translate(s * 0.06, s * 0.3), traco);
    }
  } else if (tipo == Tabuleiro.curinga) {
    // Curinga: anel de arco-íris.
    const cores = [Color(0xFFFF3D6E), Color(0xFFFFD000), Color(0xFF00E08A), Color(0xFF00B4FF), Color(0xFFA64DFF)];
    for (var i = 0; i < cores.length; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: s * 0.26),
        -math.pi / 2 + i * 2 * math.pi / cores.length,
        2 * math.pi / cores.length + 0.02,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.12
          ..color = cores[i].withValues(alpha: a(1)),
      );
    }
    canvas.drawCircle(c, s * 0.1, Paint()..color = Colors.white.withValues(alpha: a(0.95)));
  } else {
    final p = Path()
      ..moveTo(c.dx, c.dy - s * 0.3)
      ..lineTo(c.dx + s * 0.27, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.3)
      ..lineTo(c.dx - s * 0.27, c.dy)
      ..close();
    canvas
      ..drawPath(p, Paint()..color = const Color(0xFFBFFFF7).withValues(alpha: a(1)))
      ..drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.05
          ..color = const Color(0xFF0A8F86).withValues(alpha: a(1)),
      )
      ..drawLine(
        c.translate(-s * 0.15, -s * 0.02),
        c.translate(s * 0.15, -s * 0.02),
        Paint()
          ..color = Colors.white.withValues(alpha: a(0.9))
          ..strokeWidth = s * 0.04,
      );
  }
}

/// Desenha a casa do tabuleiro: bloco colorido ou pedra (índice `Tabuleiro.pedra`).
void pintarCasa(Canvas canvas, Rect r, int cor, {double opacidade = 1}) {
  if (cor >= 10 && cor < 60) {
    // Bloco especial (bomba ou joia): bloco da cor dele com o marcador por cima.
    final base = Tabuleiro.base(cor) % Cores.pecas.length;
    pintarBloco(canvas, r, Cores.pecas[base], opacidade: opacidade, indice: base);
    return pintarMarcador(canvas, r, cor ~/ 10, opacidade: opacidade);
  }
  if (cor < Cores.pecas.length) return pintarBloco(canvas, r, Cores.pecas[cor], opacidade: opacidade, indice: cor);
  pintarBloco(canvas, r, Cores.pedra, opacidade: opacidade);
  final risco = Paint()
    ..color = Colors.black.withValues(alpha: 0.35 * opacidade)
    ..strokeWidth = r.width * 0.06
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  canvas.drawPath(
    Path()
      ..moveTo(r.left + r.width * 0.3, r.top + r.height * 0.35)
      ..lineTo(r.left + r.width * 0.5, r.top + r.height * 0.55)
      ..lineTo(r.left + r.width * 0.45, r.top + r.height * 0.75)
      ..moveTo(r.left + r.width * 0.5, r.top + r.height * 0.55)
      ..lineTo(r.left + r.width * 0.72, r.top + r.height * 0.5),
    risco,
  );
}
