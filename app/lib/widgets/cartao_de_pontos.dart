import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../jogo/tabuleiro.dart';
import '../tema.dart';

/// Imagem para compartilhar: o tabuleiro do fim da partida, a pontuação e um convite. Desenhada direto no canvas
/// (não depende de nenhuma tela aberta).
class CartaoDePontos extends CustomPainter {
  CartaoDePontos({required this.tabuleiro, required this.destaque, required this.titulo, required this.detalhe});

  /// Tamanho padrão da imagem (4:5, bom para conversas e redes).
  static const largura = 1080.0, altura = 1350.0;

  final Tabuleiro tabuleiro;

  /// O número grande de baixo (pontos, ou linhas no Puzzle).
  final String destaque;

  /// Modo ("Desafio #12", "Arena da semana"...) e linha de detalhe ("Combo x4 · 12 linhas").
  final String titulo, detalhe;

  void _texto(
    Canvas canvas,
    String texto,
    Offset centro,
    double tamanho, {
    Color cor = Colors.white,
    double max = 960,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: texto,
        style: TextStyle(fontFamily: fonteJogo, fontSize: tamanho, fontWeight: FontWeight.w700, color: cor),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: max);
    tp.paint(canvas, centro - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / largura;
    canvas.save();
    canvas.scale(s);
    const tela = Rect.fromLTWH(0, 0, largura, altura);
    canvas.drawRect(
      tela,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Cores.fundoTopo, Cores.fundoBase],
        ).createShader(tela),
    );
    for (final (centro, cor) in [
      (const Offset(980, 140), Cores.brilhoRosa),
      (const Offset(60, 1100), Cores.brilhoCiano),
    ]) {
      canvas.drawCircle(
        centro,
        620,
        Paint()
          ..shader = RadialGradient(colors: [cor.withValues(alpha: 0.4), cor.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: centro, radius: 620)),
      );
    }

    _texto(canvas, 'ENCAIXA', const Offset(largura / 2, 110), 96, cor: Cores.ouro);
    _texto(canvas, titulo, const Offset(largura / 2, 200), 44, cor: Cores.textoFraco);

    // Tabuleiro.
    const lado = 840.0, x0 = (largura - lado) / 2, y0 = 270.0;
    final moldura = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x0 - 20, y0 - 20, lado + 40, lado + 40),
      const Radius.circular(40),
    );
    canvas.drawRRect(moldura, Paint()..shader = LinearGradient(colors: Cores.moldura).createShader(moldura.outerRect));
    canvas.drawRRect(moldura.deflate(8), Paint()..color = Cores.painel);
    const c = lado / Tabuleiro.tamanho;
    for (var l = 0; l < Tabuleiro.tamanho; l++) {
      for (var k = 0; k < Tabuleiro.tamanho; k++) {
        final r = Rect.fromLTWH(x0 + k * c + 3, y0 + l * c + 3, c - 6, c - 6);
        final cor = tabuleiro.cor(l, k);
        if (cor == null) {
          canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..color = Cores.casa);
        } else {
          pintarCasa(canvas, r, cor);
        }
      }
    }

    _texto(canvas, destaque, const Offset(largura / 2, 1210), 130);
    _texto(canvas, detalhe, const Offset(largura / 2, 1290), 38, cor: Cores.textoFraco);
    canvas.restore();
  }

  /// Gera o PNG da imagem (1080x1350).
  Future<Uint8List> png() async {
    final gravador = ui.PictureRecorder();
    paint(Canvas(gravador), const Size(largura, altura));
    final imagem = await gravador.endRecording().toImage(largura.toInt(), altura.toInt());
    final dados = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    return dados!.buffer.asUint8List();
  }

  @override
  bool shouldRepaint(CartaoDePontos old) => true;
}
