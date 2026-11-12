import 'package:material_ui/material_ui.dart';

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
void pintarBloco(Canvas canvas, Rect r, Color cor, {double opacidade = 1}) {
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
}

/// Desenha a casa do tabuleiro: bloco colorido ou pedra (índice `Tabuleiro.pedra`).
void pintarCasa(Canvas canvas, Rect r, int cor, {double opacidade = 1}) {
  if (cor < Cores.pecas.length) return pintarBloco(canvas, r, Cores.pecas[cor], opacidade: opacidade);
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
