import 'dart:ui';

/// Силуэт самолёта в единичных координатах: центр в нуле,
/// нос смотрит вверх (-Y), габарит примерно 1x1.
/// Строится один раз и переиспользуется всеми бортами.
class PlaneShape {
  const PlaneShape._();

  static final Path body = _buildBody();
  static final Path wings = _buildWings();
  static final Path tail = _buildTail();
  static final Path cockpit = _buildCockpit();

  static Path _buildBody() {
    final Path p = Path();
    p.moveTo(0, -0.50);
    p.cubicTo(0.09, -0.44, 0.12, -0.24, 0.12, 0.02);
    p.cubicTo(0.12, 0.24, 0.10, 0.40, 0.07, 0.50);
    p.lineTo(-0.07, 0.50);
    p.cubicTo(-0.10, 0.40, -0.12, 0.24, -0.12, 0.02);
    p.cubicTo(-0.12, -0.24, -0.09, -0.44, 0, -0.50);
    p.close();
    return p;
  }

  static Path _buildWings() {
    final Path p = Path();
    p.moveTo(0.10, -0.10);
    p.lineTo(0.50, 0.16);
    p.lineTo(0.50, 0.25);
    p.lineTo(0.10, 0.16);
    p.lineTo(-0.10, 0.16);
    p.lineTo(-0.50, 0.25);
    p.lineTo(-0.50, 0.16);
    p.lineTo(-0.10, -0.10);
    p.close();
    return p;
  }

  static Path _buildTail() {
    final Path p = Path();
    p.moveTo(0.06, 0.34);
    p.lineTo(0.24, 0.48);
    p.lineTo(0.24, 0.53);
    p.lineTo(-0.24, 0.53);
    p.lineTo(-0.24, 0.48);
    p.lineTo(-0.06, 0.34);
    p.close();
    return p;
  }

  static Path _buildCockpit() {
    final Path p = Path();
    p.addOval(Rect.fromLTWH(-0.055, -0.42, 0.11, 0.14));
    return p;
  }
}
