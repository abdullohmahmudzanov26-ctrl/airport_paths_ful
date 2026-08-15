import 'dart:math' as math;
import 'dart:ui';

import '../models/level_data.dart';

/// Геометрия поля: где начинается сетка и какого размера клетка.
/// Всё остальное считается отсюда, поэтому поворот или смена размера
/// экрана не требуют пересчёта игровой логики.
class BoardLayout {
  const BoardLayout({
    required this.cols,
    required this.rows,
    required this.cell,
    required this.origin,
  });

  final int cols;
  final int rows;
  final double cell;
  final Offset origin;

  static const BoardLayout empty =
      BoardLayout(cols: 1, rows: 1, cell: 0, origin: Offset.zero);

  bool get isReady => cell > 0;

  Rect get board =>
      Rect.fromLTWH(origin.dx, origin.dy, cell * cols, cell * rows);

  Offset center(GridPos p) => Offset(
        origin.dx + (p.col + 0.5) * cell,
        origin.dy + (p.row + 0.5) * cell,
      );

  Rect rectOf(GridPos p) => Rect.fromLTWH(
        origin.dx + p.col * cell,
        origin.dy + p.row * cell,
        cell,
        cell,
      );

  GridPos? hitTest(Offset point) {
    if (cell <= 0) return null;
    final int col = ((point.dx - origin.dx) / cell).floor();
    final int row = ((point.dy - origin.dy) / cell).floor();
    if (col < 0 || col >= cols || row < 0 || row >= rows) return null;
    return GridPos(col, row);
  }

  static BoardLayout fit(Size size, int cols, int rows, {double padding = 10}) {
    if (size.width <= 0 || size.height <= 0) return empty;
    final double cell = math.min(
      (size.width - padding * 2) / cols,
      (size.height - padding * 2) / rows,
    );
    if (cell <= 0) return empty;
    final double w = cell * cols;
    final double h = cell * rows;
    return BoardLayout(
      cols: cols,
      rows: rows,
      cell: cell,
      origin: Offset((size.width - w) / 2, (size.height - h) / 2),
    );
  }
}

/// Сглаженная ломаная по центрам клеток - и для маршрутов, и для подсказки.
Path roundedPolyline(List<Offset> points, double radius) {
  final Path path = Path();
  if (points.isEmpty) return path;
  if (points.length == 1) {
    path.moveTo(points.first.dx, points.first.dy);
    path.lineTo(points.first.dx + 0.01, points.first.dy);
    return path;
  }

  path.moveTo(points.first.dx, points.first.dy);
  for (int i = 1; i < points.length - 1; i++) {
    final Offset prev = points[i - 1];
    final Offset cur = points[i];
    final Offset next = points[i + 1];

    final Offset v1 = cur - prev;
    final Offset v2 = next - cur;
    final double d1 = v1.distance;
    final double d2 = v2.distance;
    if (d1 == 0 || d2 == 0) continue;

    final double r = math.min(radius, math.min(d1, d2) / 2);
    final Offset p1 = cur - v1 / d1 * r;
    final Offset p2 = cur + v2 / d2 * r;

    path.lineTo(p1.dx, p1.dy);
    path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
  }
  path.lineTo(points.last.dx, points.last.dy);
  return path;
}
