import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// Зелёная лента «УРОВЕНЬ ПРОЙДЕН!» с хвостами по бокам.
/// Рисуется кодом, чтобы одинаково выглядеть при любой длине надписи.
class RibbonBanner extends StatelessWidget {
  const RibbonBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ButtonPalette c = context.palette.success;
    return CustomPaint(
      painter: _RibbonPainter(
        top: c.top,
        bottom: c.bottom,
        shadow: c.shadow,
        border: c.border,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 11, 34, 13),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.button.copyWith(
            fontSize: 18,
            color: Colors.white,
            shadows: const <Shadow>[
              Shadow(color: Color(0x8C0A2A00), offset: Offset(0, 2), blurRadius: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter({
    required this.top,
    required this.bottom,
    required this.shadow,
    required this.border,
  });

  final Color top;
  final Color bottom;
  final Color shadow;
  final Color border;

  static const double tail = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Хвосты с треугольным вырезом.
    final Paint tailPaint = Paint()..color = shadow;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.08)
        ..lineTo(tail + 12, h * 0.02)
        ..lineTo(tail + 12, h * 0.98)
        ..lineTo(0, h * 0.92)
        ..lineTo(tail * 0.55, h * 0.5)
        ..close(),
      tailPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, h * 0.08)
        ..lineTo(w - tail - 12, h * 0.02)
        ..lineTo(w - tail - 12, h * 0.98)
        ..lineTo(w, h * 0.92)
        ..lineTo(w - tail * 0.55, h * 0.5)
        ..close(),
      tailPaint,
    );

    final RRect center = RRect.fromRectAndRadius(
      Rect.fromLTWH(tail, 0, w - tail * 2, h),
      const Radius.circular(10),
    );

    canvas.drawRRect(
      center.shift(const Offset(0, 4)),
      Paint()..color = shadow,
    );
    canvas.drawRRect(
      center,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[top, bottom],
        ).createShader(center.outerRect),
    );
    canvas.drawRRect(
      center.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = border.withOpacity(0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _RibbonPainter old) =>
      old.top != top || old.bottom != bottom || old.shadow != shadow;
}
