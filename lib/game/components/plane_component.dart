import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/level_data.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';
import 'plane_shape.dart';

/// Один самолёт: отрисовка, поворот и движение по маршруту.
///
/// Положение считается в «клетках пути», а не в пикселях, поэтому смена
/// размера поля или поворот экрана не сбивают анимацию на полпути.
class PlaneComponent extends Component {
  PlaneComponent({required this.game, required this.spec}) : super(priority: 6);

  final AirportGame game;
  final PlaneSpec spec;

  static const double speedCellsPerSecond = 2.3;
  static const double turnRate = 7.0;

  List<GridPos> _route = const <GridPos>[];
  double _traveled = 0;
  double _angle = 0;
  double _idle = 0;
  bool arrived = false;
  bool _launched = false;

  // Кисти создаются один раз: цвет борта не меняется, а render()
  // вызывается 60 раз в секунду для каждого самолёта.
  final Paint _shadowPaint = Paint()..color = const Color(0x4D000000);
  final Paint _bodyPaint = Paint();
  final Paint _wingPaint = Paint();
  final Paint _tailPaint = Paint();
  final Paint _glossPaint = Paint();
  final Paint _cockpitPaint = Paint()..color = const Color(0xCC0E2439);
  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..color = const Color(0x66001528);

  bool get isFlying => _launched && !arrived;

  Color get color => PlaneColors.all[spec.colorIndex % PlaneColors.all.length];

  @override
  Future<void> onLoad() async {
    _angle = spec.startAngle;

    final Color base = color;
    _bodyPaint.color = base;
    _wingPaint.color = _shade(base, 0.82);
    _tailPaint.color = _shade(base, 0.72);
    _glossPaint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0x59FFFFFF),
        Color(0x00FFFFFF),
        Color(0x33000000),
      ],
    ).createShader(const Rect.fromLTWH(-0.15, -0.5, 0.3, 1.0));
  }

  void resetToStart() {
    _route = const <GridPos>[];
    _traveled = 0;
    _angle = spec.startAngle;
    arrived = false;
    _launched = false;
  }

  void launch(List<GridPos> route) {
    if (route.length < 2) return;
    _route = route;
    _traveled = 0;
    arrived = false;
    _launched = true;
  }

  /// Продвижение по маршруту. dt приходит из цикла Flame, поэтому
  /// скорость одинакова и на 60, и на 120 Гц.
  void advance(double dt) {
    if (!_launched || arrived) return;
    final double maxTraveled = (_route.length - 1).toDouble();
    _traveled += speedCellsPerSecond * dt;
    if (_traveled >= maxTraveled) {
      _traveled = maxTraveled;
      arrived = true;
    }
  }

  Offset get position {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return Offset.zero;
    if (_route.length < 2) return layout.center(spec.start);

    final int i = _traveled.floor().clamp(0, _route.length - 1);
    final int next = math.min(i + 1, _route.length - 1);
    final double f = (_traveled - i).clamp(0.0, 1.0);
    final Offset a = layout.center(_route[i]);
    final Offset b = layout.center(_route[next]);
    return Offset(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f);
  }

  double get _targetAngle {
    if (_route.length < 2) return spec.startAngle;
    final int i = _traveled.floor().clamp(0, _route.length - 2);
    final GridPos a = _route[i];
    final GridPos b = _route[i + 1];
    return math.atan2((b.col - a.col).toDouble(), -(b.row - a.row).toDouble());
  }

  @override
  void update(double dt) {
    _idle += dt;
    if (_launched && !arrived) {
      // Доворот по кратчайшей дуге, без рывка на -180 -> +180.
      double diff = _targetAngle - _angle;
      while (diff > math.pi) {
        diff -= math.pi * 2;
      }
      while (diff < -math.pi) {
        diff += math.pi * 2;
      }
      _angle += diff * math.min(1.0, turnRate * dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final double cell = layout.cell;
    final double size = cell * 0.82;
    final Offset pos = position;

    // Лёгкое покачивание, пока борт ждёт маршрут.
    final double bob =
        _launched ? 0 : math.sin(_idle * 2.0 + spec.id) * cell * 0.02;

    canvas.save();
    canvas.translate(pos.dx, pos.dy + bob);

    // Тень.
    canvas.save();
    canvas.translate(size * 0.10, size * 0.14);
    canvas.rotate(_angle);
    canvas.scale(size);
    canvas.drawPath(PlaneShape.wings, _shadowPaint);
    canvas.drawPath(PlaneShape.body, _shadowPaint);
    canvas.restore();

    canvas.rotate(_angle);
    canvas.scale(size);

    canvas.drawPath(PlaneShape.tail, _tailPaint);
    canvas.drawPath(PlaneShape.wings, _wingPaint);
    canvas.drawPath(PlaneShape.wings, _outlinePaint);
    canvas.drawPath(PlaneShape.body, _bodyPaint);
    canvas.drawPath(PlaneShape.body, _outlinePaint);

    // Блик по фюзеляжу и остекление кабины.
    canvas.drawPath(PlaneShape.body, _glossPaint);
    canvas.drawPath(PlaneShape.cockpit, _cockpitPaint);

    canvas.restore();
  }

  static Color _shade(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );
}
