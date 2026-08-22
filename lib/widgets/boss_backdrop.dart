import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/maze_themes.dart';

/// Фон экрана босса: градиент темы, сияние под доской и виньетка.
///
/// Тем же приёмом, что и GameBackdrop обычной игры: рисуется один раз,
/// лежит в RepaintBoundary и не перерисовывается при анимациях кнопок.
/// Отдельный виджет нужен потому, что у лабиринта своя палитра
/// (MazeTheme), а не BoardTheme игрового поля.
class BossBackdrop extends StatelessWidget {
  const BossBackdrop({super.key, required this.theme, this.child});

  final MazeTheme theme;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[theme.bgTop, theme.bgBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              painter: _BossBackdropPainter(theme),
              isComplex: true,
              willChange: false,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _BossBackdropPainter extends CustomPainter {
  const _BossBackdropPainter(this.theme);

  final MazeTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height * 0.52);

    // Сияние под доской - тем же цветом, что и акценты лабиринта.
    canvas.drawCircle(
      center,
      size.width * 0.95,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            theme.glow.withOpacity(0.20),
            theme.glow.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.95),
        ),
    );

    // Редкие диагональные штрихи: фон перестаёт быть пустым,
    // но не спорит с полем.
    final Paint stroke = Paint()
      ..color = theme.accent.withOpacity(0.045)
      ..strokeWidth = 2;
    final double step = size.width / 7;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.4, size.height),
        stroke,
      );
    }

    // Виньетка по краям.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0x00000000),
            theme.bgBottom.withOpacity(0.75),
          ],
          stops: const <double>[0.55, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: math.max(size.width, size.height) * 0.75,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _BossBackdropPainter oldDelegate) =>
      oldDelegate.theme.id != theme.id;
}
