import 'package:material_ui/material_ui.dart';

/// Cores e desenho dos blocos. A arte do jogo é toda vetorial, feita aqui.
abstract final class Cores {
  static const fundoTopo = Color(0xFF2B1B72);
  static const fundoBase = Color(0xFF140B3A);
  static const painel = Color(0xFF0F0830);
  static const casa = Color(0xFF231858);
  static const texto = Color(0xFFF5F1FF);
  static const textoFraco = Color(0xFFB4A8E0);
  static const gema = Color(0xFF3FE0D0);
  static const ouro = Color(0xFFFFC94A);
  static const destaque = Color(0xFFFF5A8A);

  /// Uma cor por tipo de bloco (o índice vem de `Peca.cor`).
  static const blocos = [
    Color(0xFFFF5A6E), // coral
    Color(0xFFFF9F1C), // laranja
    Color(0xFFFFD23F), // amarelo
    Color(0xFF3DDC84), // verde
    Color(0xFF2EC4F1), // azul
    Color(0xFFA96BFF), // roxo
  ];

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

/// Desenha um bloco "bala de goma": degradê, borda clara em cima e sombra embaixo.
void pintarBloco(Canvas canvas, Rect r, Color cor, {double opacidade = 1}) {
  final raio = Radius.circular(r.width * 0.2);
  final escura = Color.lerp(cor, Colors.black, 0.35)!;
  final clara = Color.lerp(cor, Colors.white, 0.35)!;
  Color o(Color c) => c.withValues(alpha: c.a * opacidade);

  canvas.drawRRect(RRect.fromRectAndRadius(r, raio), Paint()..color = o(escura));
  final corpo = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - r.height * 0.1);
  canvas.drawRRect(
    RRect.fromRectAndRadius(corpo, raio),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [o(clara), o(cor)],
      ).createShader(corpo),
  );
  final brilho = Rect.fromLTWH(r.left + r.width * 0.16, r.top + r.height * 0.12, r.width * 0.36, r.height * 0.14);
  canvas.drawRRect(
    RRect.fromRectAndRadius(brilho, Radius.circular(brilho.height)),
    Paint()..color = Colors.white.withValues(alpha: 0.45 * opacidade),
  );
}
