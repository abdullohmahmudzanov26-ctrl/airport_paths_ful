import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/level_data.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Слой нарисованных маршрутов: между картой и самолётами.
///
/// Path строится не каждый кадр, а только когда трасса действительно
/// изменилась (по счётчику revision) или сменилась геометрия поля.
/// Кисти создаются один раз и переиспользуются - в render()
/// не остаётся ни одной аллокации.
class RouteLayerComponent extends Component {
  RouteLayerComponent(this.game) : super(priority: 3);

  final AirportGame game;

  final Map<int, _CachedRoute> _cache = <int, _CachedRoute>{};

  final Paint _shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0x45000000);

  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = const Color(0x59001528);

  final Paint _bodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint _glossPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint _dotPaint = Paint();
  final Paint _pulsePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _lockPaint = Paint();
  final Paint _lockRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xCCFFFFFF);

  double _time = 0;

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final double cell = layout.cell;
    _shadowPaint.strokeWidth = cell * 0.46;
    _outlinePaint.strokeWidth = cell * 0.46;
    _bodyPaint.strokeWidth = cell * 0.40;
    _glossPaint.strokeWidth = cell * 0.12;
    _pulsePaint.strokeWidth = cell * 0.05;
    _lockRingPaint.strokeWidth = cell * 0.045;

    for (final PlaneSpec spec in game.level.planes) {
      final List<GridPos> route = game.routes.routeOf(spec.id);
      final Color color =
          PlaneColors.all[spec.colorIndex % PlaneColors.all.length];

      if (route.length >= 2) {
        _paintRoute(
          canvas,
          layout,
          spec.id,
          route,
          color,
          active: game.routes.activePlane == spec.id,
        );
      }

      // Пока стоянка не подключена - она мягко пульсирует.
      if (game.routes.isComplete(spec.id)) {
        _paintGateLocked(canvas, layout.center(spec.gate), color, cell);
      } else {
        _paintGatePulse(canvas, layout.center(spec.gate), color, cell);
      }
    }
  }

  void _paintRoute(
    Canvas canvas,
    BoardLayout layout,
    int planeId,
    List<GridPos> route,
    Color color, {
    required bool active,
  }) {
    final double cell = layout.cell;
    final Path path = _pathFor(planeId, layout, route);

    canvas.save();
    canvas.translate(0, cell * 0.07);
    canvas.drawPath(path, _shadowPaint);
    canvas.restore();

    // Тёмная окантовка - линия читается на любом фоне.
    canvas.drawPath(path, _outlinePaint);

    _bodyPaint.color = color;
    canvas.drawPath(path, _bodyPaint);

    // Внутренний блик придаёт трассе объём.
    _glossPaint.color = Color.fromARGB(active ? 90 : 55, 255, 255, 255);
    canvas.drawPath(path, _glossPaint);

    _dotPaint.color = _shade(color, 0.75);
    canvas.drawCircle(layout.center(route.first), cell * 0.17, _dotPaint);
  }

  Path _pathFor(int planeId, BoardLayout layout, List<GridPos> route) {
    final _CachedRoute? cached = _cache[planeId];
    if (cached != null &&
        cached.revision == game.routes.revision &&
        cached.cell == layout.cell &&
        cached.origin == layout.origin) {
      return cached.path;
    }

    final List<Offset> points =
        route.map((GridPos p) => layout.center(p)).toList(growable: false);
    final Path path = roundedPolyline(points, layout.cell * 0.42);

    _cache[planeId] = _CachedRoute(
      revision: game.routes.revision,
      cell: layout.cell,
      origin: layout.origin,
      path: path,
    );
    return path;
  }

  void _paintGatePulse(Canvas canvas, Offset center, Color color, double cell) {
    final double wave = (math.sin(_time * 3.0) + 1) / 2;
    _pulsePaint.color = color.withOpacity(0.30 + 0.35 * (1 - wave));
    canvas.drawCircle(center, cell * (0.30 + 0.06 * wave), _pulsePaint);
  }

  void _paintGateLocked(Canvas canvas, Offset center, Color color, double cell) {
    _lockPaint.color = color;
    canvas.drawCircle(center, cell * 0.15, _lockPaint);
    canvas.drawCircle(center, cell * 0.15, _lockRingPaint);
  }

  static Color _shade(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );
}

class _CachedRoute {
  const _CachedRoute({
    required this.revision,
    required this.cell,
    required this.origin,
    required this.path,
  });

  final int revision;
  final double cell;
  final Offset origin;
  final Path path;
}
