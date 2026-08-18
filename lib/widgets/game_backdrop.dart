import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/board_theme.dart';
import '../theme/app_palette.dart';

/// Фон игрового экрана. Раньше здесь был голый градиент, и пространство
/// вокруг доски выглядело пустым провалом.
///
/// Теперь фон подхватывает тему поля: сияние под доской, лёгкий узор
/// в её стиле и виньетка по краям. Рисуется один раз и лежит в
/// RepaintBoundary — анимации кнопок его не трогают.
class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.theme, this.child});

  final BoardTheme theme;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: p.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: CustomPaint(
              painter: _BackdropPainter(
                theme: theme,
                base: p.bgBottom,
                glow: _accentFor(theme),
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }

  /// Цвет свечения берём из темы, чтобы фон и доска были одним целым.
  static Color _accentFor(BoardTheme t) {
    switch (t.style) {
      case BoardStyle.day:
        return t.groundTop;
      case BoardStyle.night:
        return const Color(0xFF5FC8FF);
      case BoardStyle.blueprint:
        return const Color(0xFF38B6FF);
      case BoardStyle.orbital:
        return const Color(0xFF7A3CDC);
    }
  }
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.theme,
    required this.base,
    required this.glow,
  });

  final BoardTheme theme;
  final Color base;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Rect all = Offset.zero & size;
    final math.Random rnd = math.Random(20260815);

    switch (theme.style) {
      case BoardStyle.orbital:
        _stars(canvas, w, h, rnd);
        break;
      case BoardStyle.blueprint:
        _radar(canvas, w, h);
        break;
      case BoardStyle.night:
        _stars(canvas, w, h, rnd, count: 26, maxAlpha: 0.35);
        break;
      case BoardStyle.day:
        _clouds(canvas, w, h);
        break;
    }

    // Мягкое сияние под доской: она перестаёт «висеть» в пустоте.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[glow.withOpacity(0.20), glow.withOpacity(0)],
        ).createShader(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.46), radius: h * 0.55),
        ),
    );

    // Виньетка: края уходят в тень, взгляд собирается к центру.
    canvas.drawRect(
      all,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[base.withOpacity(0), base.withOpacity(0.55)],
          stops: const <double>[0.55, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: h * 0.75),
        ),
    );
  }

  void _stars(
    Canvas canvas,
    double w,
    double h,
    math.Random rnd, {
    int count = 120,
    double maxAlpha = 0.85,
  }) {
    for (int i = 0; i < count; i++) {
      final double s = rnd.nextDouble();
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
        s * 1.6 + 0.35,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, (0.12 + s * maxAlpha) * 0.9),
      );
    }
  }

  /// Концентрические круги и лучи — экран радара за доской.
  void _radar(Canvas canvas, double w, double h) {
    final Offset c = Offset(w * 0.5, h * 0.46);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x1A38B6FF);

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(c, h * 0.12 * i, ring);
    }
    for (int i = 0; i < 8; i++) {
      final double a = math.pi * 2 / 8 * i;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a), math.sin(a)) * h * 0.62,
        ring,
      );
    }
  }

  /// Пара размытых облаков сверху — небо над аэродромом.
  void _clouds(Canvas canvas, double w, double h) {
    final Paint cloud = Paint()..color = const Color(0x14FFFFFF);
    void blob(double x, double y, double r) {
      canvas.drawCircle(Offset(x, y), r, cloud);
      canvas.drawCircle(Offset(x - r * 0.8, y + r * 0.25), r * 0.7, cloud);
      canvas.drawCircle(Offset(x + r * 0.85, y + r * 0.3), r * 0.62, cloud);
    }

    blob(w * 0.22, h * 0.07, w * 0.11);
    blob(w * 0.78, h * 0.12, w * 0.09);
    blob(w * 0.5, h * 0.95, w * 0.13);
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) =>
      old.theme.id != theme.id || old.glow != glow || old.base != base;
}
