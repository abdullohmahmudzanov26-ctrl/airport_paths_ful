import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Фон меню: вид на аэродром, нарисованный кодом.
/// Никаких сетевых картинок - только Canvas, поэтому вес нулевой,
/// а картинка резкая на любом экране. Позже сюда легко подложить PNG.
class AirportBackdrop extends StatelessWidget {
  const AirportBackdrop({
    super.key,
    this.child,
    this.sceneHeightFactor = 0.52,
    this.animatePlane = true,
  });

  final Widget? child;
  final double sceneHeightFactor;
  final bool animatePlane;

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
              painter: _AirportScenePainter(
                sceneHeightFactor: sceneHeightFactor,
                fadeColor: p.bgBottom,
                fadeMid: p.bgMid,
              ),
              isComplex: true,
              willChange: false,
            ),
          ),
          if (animatePlane)
            const RepaintBoundary(child: _FlyingPlane()),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _AirportScenePainter extends CustomPainter {
  _AirportScenePainter({
    required this.sceneHeightFactor,
    required this.fadeColor,
    required this.fadeMid,
  });

  final double sceneHeightFactor;
  final Color fadeColor;
  final Color fadeMid;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    if (sceneHeightFactor <= 0.01) return; // чистый фон без сцены

    final double horizon = h * sceneHeightFactor * 0.62;
    final double sceneBottom = h * sceneHeightFactor;

    _paintSky(canvas, w, horizon);
    _paintClouds(canvas, w, horizon);
    _paintSkyline(canvas, w, horizon);
    _paintGround(canvas, w, h, horizon);
    _paintRunway(canvas, w, h, horizon);
    _paintFade(canvas, w, h, sceneBottom);
  }

  void _paintSky(Canvas canvas, double w, double horizon) {
    final Rect rect = Rect.fromLTWH(0, 0, w, horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF1E6FB0), Color(0xFF6FB6E4), Color(0xFFC4E4F5)],
          stops: <double>[0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // Солнечное свечение справа.
    final Offset sun = Offset(w * 0.76, horizon * 0.42);
    canvas.drawCircle(
      sun,
      horizon * 0.85,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFF6D2).withOpacity(0.55),
            const Color(0xFFFFF6D2).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: horizon * 0.85)),
    );
  }

  void _paintClouds(Canvas canvas, double w, double horizon) {
    final Paint paint = Paint()..color = Colors.white.withOpacity(0.55);
    _cloud(canvas, paint, Offset(w * 0.18, horizon * 0.28), w * 0.15);
    _cloud(canvas, paint..color = Colors.white.withOpacity(0.38),
        Offset(w * 0.62, horizon * 0.18), w * 0.11);
    _cloud(canvas, paint..color = Colors.white.withOpacity(0.30),
        Offset(w * 0.88, horizon * 0.34), w * 0.13);
  }

  void _cloud(Canvas canvas, Paint paint, Offset center, double width) {
    final double r = width * 0.34;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center.translate(-r * 0.9, r * 0.25), r * 0.72, paint);
    canvas.drawCircle(center.translate(r * 0.95, r * 0.3), r * 0.66, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - width * 0.5, center.dy + r * 0.1, width, r * 0.7),
        Radius.circular(r * 0.4),
      ),
      paint,
    );
  }

  /// Терминал, ангары и диспетчерская вышка на горизонте.
  void _paintSkyline(Canvas canvas, double w, double horizon) {
    final Paint far = Paint()..color = const Color(0xFF2C4E6C);
    final Paint building = Paint()..color = const Color(0xFF33526F);
    final Paint buildingLit = Paint()..color = const Color(0xFF456C8C);
    final Paint glass = Paint()..color = const Color(0xFF7FB6DA).withOpacity(0.75);

    // Терминал слева.
    final double baseY = horizon;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        w * 0.02, baseY - horizon * 0.20, w * 0.34, baseY,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      building,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * 0.04, baseY - horizon * 0.13, w * 0.32, baseY - horizon * 0.08),
      glass,
    );

    // Ангары в центре.
    for (int i = 0; i < 3; i++) {
      final double x = w * (0.36 + i * 0.09);
      final double hh = horizon * (0.11 + (i.isEven ? 0.03 : 0.0));
      final Path hangar = Path()
        ..moveTo(x, baseY)
        ..lineTo(x, baseY - hh * 0.55)
        ..quadraticBezierTo(x + w * 0.035, baseY - hh * 1.25, x + w * 0.07, baseY - hh * 0.55)
        ..lineTo(x + w * 0.07, baseY)
        ..close();
      canvas.drawPath(hangar, i.isEven ? buildingLit : building);
    }

    // Диспетчерская вышка справа.
    final double towerX = w * 0.80;
    final double towerTop = baseY - horizon * 0.52;
    canvas.drawRect(
      Rect.fromLTRB(towerX - w * 0.018, towerTop + horizon * 0.10, towerX + w * 0.018, baseY),
      building,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(towerX - w * 0.052, towerTop, towerX + w * 0.052, towerTop + horizon * 0.11),
        const Radius.circular(7),
      ),
      buildingLit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(towerX - w * 0.042, towerTop + horizon * 0.02,
            towerX + w * 0.042, towerTop + horizon * 0.075),
        const Radius.circular(4),
      ),
      glass,
    );
    // Мачта с огоньком.
    canvas.drawRect(
      Rect.fromLTRB(towerX - 1.5, towerTop - horizon * 0.10, towerX + 1.5, towerTop),
      far,
    );
    canvas.drawCircle(
      Offset(towerX, towerTop - horizon * 0.10),
      3,
      Paint()..color = const Color(0xFFFF5A4D),
    );
  }

  void _paintGround(Canvas canvas, double w, double h, double horizon) {
    final Rect rect = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF4E7A3E), Color(0xFF2F5528)],
        ).createShader(rect),
    );
  }

  /// Полоса в перспективе с осевой разметкой.
  void _paintRunway(Canvas canvas, double w, double h, double horizon) {
    final double bottom = h * 0.98;
    final Path runway = Path()
      ..moveTo(w * 0.40, horizon)
      ..lineTo(w * 0.60, horizon)
      ..lineTo(w * 1.18, bottom)
      ..lineTo(w * -0.18, bottom)
      ..close();

    canvas.drawPath(
      runway,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF4A5058), Color(0xFF32373E)],
        ).createShader(Rect.fromLTWH(0, horizon, w, bottom - horizon)),
    );

    // Боковые кромки.
    final Paint edge = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.40, horizon), Offset(w * -0.18, bottom), edge);
    canvas.drawLine(Offset(w * 0.60, horizon), Offset(w * 1.18, bottom), edge);

    // Осевые штрихи: шаг растёт по кубической кривой - читается как перспектива.
    final Paint dash = Paint()..color = Colors.white.withOpacity(0.82);
    const int steps = 9;
    for (int i = 0; i < steps; i++) {
      final double t = math.pow(i / steps, 1.9).toDouble();
      final double y = horizon + (bottom - horizon) * t;
      final double dashH = 6 + 40 * t;
      final double dashW = 2.5 + 12 * t;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.5, y), width: dashW, height: dashH),
          Radius.circular(dashW * 0.4),
        ),
        dash,
      );
    }
  }

  /// Плавный уход сцены в тёмный фон, чтобы кнопки читались.
  void _paintFade(Canvas canvas, double w, double h, double sceneBottom) {
    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            fadeColor.withOpacity(0.25),
            fadeColor.withOpacity(0.0),
            fadeMid.withOpacity(0.85),
            fadeColor,
          ],
          stops: <double>[
            0.0,
            (sceneBottom / h) * 0.45,
            (sceneBottom / h) * 0.95,
            math.min(1.0, sceneBottom / h + 0.12),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AirportScenePainter old) =>
      old.sceneHeightFactor != sceneHeightFactor ||
      old.fadeColor != fadeColor ||
      old.fadeMid != fadeMid;
}

/// Один самолётик, неспешно пересекающий небо. Дешёвая "живость" фона.
class _FlyingPlane extends StatefulWidget {
  const _FlyingPlane();

  @override
  State<_FlyingPlane> createState() => _FlyingPlaneState();
}

class _FlyingPlaneState extends State<_FlyingPlane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        return AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double t = _c.value;
            final double x = -60 + (c.maxWidth + 120) * t;
            final double y = c.maxHeight * 0.10 - math.sin(t * math.pi) * 18;
            final double opacity = (math.sin(t * math.pi) * 1.6).clamp(0.0, 0.85);
            return Align(
              alignment: Alignment.topLeft,
              child: Transform.translate(
                offset: Offset(x, y),
                child: Opacity(opacity: opacity, child: child),
              ),
            );
          },
          child: Transform.rotate(
            angle: math.pi / 2,
            child: const Icon(Icons.flight, size: 20, color: Colors.white),
          ),
        );
      },
    );
  }
}
