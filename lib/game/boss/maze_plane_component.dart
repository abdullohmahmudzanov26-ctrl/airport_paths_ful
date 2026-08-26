import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/plane_skin.dart';
import '../../theme/app_palette.dart';
import '../board_layout.dart';
import 'boss_maze_game.dart';

/// Единственный борт лабиринта.
///
/// В лабиринте всегда ровно один самолёт - это правило босса, а не
/// случайность генерации: компонент создаётся в единственном экземпляре
/// и рисует позицию, которую считает сама игра.
///
/// Силуэт берётся из купленного скина, поэтому магазин работает и здесь,
/// а кисти строятся один раз в onLoad - как и в обычном PlaneComponent.
class MazePlaneComponent extends Component {
  MazePlaneComponent(this.game) : super(priority: 6);

  final BossMazeGame game;

  static const Color _base = PlaneColors.yellow;

  double _idle = 0;

  // Плоская тень без MaskFilter.blur - см. plane_component.dart:
  // размытие стоило отдельного прохода растеризации каждый кадр,
  // здесь борт всего один, но эффект тот же на любом счётчике.
  final Paint _shadowPaint = Paint()..color = const Color(0x40000000);
  final Paint _bodyPaint = Paint();
  final Paint _wingPaint = Paint();
  final Paint _tailPaint = Paint();
  final Paint _glossPaint = Paint();
  final Paint _wingGlossPaint = Paint();
  final Paint _detailPaint = Paint();
  final Paint _cockpitPaint = Paint()..color = const Color(0xCC0E2439);
  final Paint _cockpitGlossPaint = Paint()..color = const Color(0x8CFFFFFF);
  Rect _cockpitHighlight = Rect.zero;
  final Paint _rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.022
    ..strokeCap = StrokeCap.round
    ..color = const Color(0x8CFFFFFF);
  final Paint _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..color = const Color(0x66001528);
  final Paint _haloPaint = Paint();
  final Paint _stickRing = Paint()..style = PaintingStyle.stroke;
  final Paint _stickDot = Paint();

  PlaneSkin get skin => game.skin;

  @override
  Future<void> onLoad() async {
    _bodyPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        _lighten(_base, 1.38),
        _base,
        _shade(_base, 0.64),
      ],
      stops: const <double>[0.0, 0.45, 1.0],
    ).createShader(const Rect.fromLTWH(-0.20, -0.55, 0.40, 1.10));

    _wingPaint.shader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        _lighten(_shade(_base, 0.86), 1.22),
        _shade(_base, 0.80),
        _shade(_base, 0.56),
      ],
      stops: const <double>[0.0, 0.5, 1.0],
    ).createShader(const Rect.fromLTWH(-0.58, -0.20, 1.16, 0.80));

    _wingGlossPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0x4DFFFFFF),
        Color(0x00FFFFFF),
      ],
    ).createShader(const Rect.fromLTWH(-0.58, -0.20, 1.16, 0.30));

    _tailPaint.color = _shade(_base, 0.72);
    _detailPaint.color = _shade(_base, 0.62).withOpacity(skin.detailOpacity);
    _glossPaint.shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0x59FFFFFF),
        Color(0x00FFFFFF),
        Color(0x33000000),
      ],
    ).createShader(const Rect.fromLTWH(-0.15, -0.5, 0.3, 1.0));

    final Rect cb = skin.cockpit.getBounds();
    _cockpitHighlight = Rect.fromLTWH(
      cb.left + cb.width * 0.16,
      cb.top + cb.height * 0.12,
      cb.width * 0.34,
      cb.height * 0.30,
    );

    _haloPaint.color = game.theme.accent.withOpacity(0.18);
    _stickRing.color = game.theme.accent.withOpacity(0.35);
    _stickDot.color = game.theme.accent.withOpacity(0.55);
  }

  @override
  void update(double dt) {
    _idle += dt;
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final double cell = layout.cell;
    final Offset pos = game.pixelOf(game.planeCol, game.planeRow);
    final double size = cell * 0.78;

    // Ореол под бортом: на пёстрой карте самолёт иначе теряется.
    canvas.drawCircle(pos, cell * 0.46, _haloPaint);

    final double bob =
        game.isPlaying ? 0 : math.sin(_idle * 2.0) * cell * 0.02;

    canvas.save();
    canvas.translate(pos.dx, pos.dy + bob);

    canvas.save();
    canvas.translate(size * 0.10, size * 0.14);
    canvas.rotate(game.planeAngle);
    canvas.scale(size);
    canvas.drawPath(skin.wings, _shadowPaint);
    canvas.drawPath(skin.body, _shadowPaint);
    canvas.restore();

    canvas.rotate(game.planeAngle);
    canvas.scale(size);

    canvas.drawPath(skin.tail, _tailPaint);
    canvas.drawPath(skin.wings, _wingPaint);
    canvas.drawPath(skin.wings, _outlinePaint);
    canvas.drawPath(skin.wings, _rimPaint);
    canvas.drawPath(skin.wings, _wingGlossPaint);
    canvas.drawPath(skin.tail, _rimPaint);

    final Path? details = skin.details;
    if (details != null) canvas.drawPath(details, _detailPaint);

    canvas.drawPath(skin.body, _bodyPaint);
    canvas.drawPath(skin.body, _outlinePaint);
    canvas.drawPath(skin.body, _glossPaint);
    canvas.drawPath(skin.body, _rimPaint);
    canvas.drawPath(skin.cockpit, _cockpitPaint);
    canvas.drawOval(_cockpitHighlight, _cockpitGlossPaint);

    canvas.restore();

    _renderStick(canvas);
  }

  /// Виртуальный джойстик: кольцо в точке касания и точка под пальцем.
  /// Управление относительное, поэтому подсказка нужна - иначе непонятно,
  /// откуда считается направление.
  void _renderStick(Canvas canvas) {
    final Offset? anchor = game.stickAnchor;
    if (anchor == null || !game.isPlaying) return;

    _stickRing.strokeWidth = 2.0;
    canvas.drawCircle(anchor, 34, _stickRing);

    final Offset v = game.stickVector;
    final double len = v.distance;
    final Offset knob =
        len <= 34 ? anchor + v : anchor + Offset(v.dx / len * 34, v.dy / len * 34);
    canvas.drawCircle(knob, 12, _stickDot);
  }

  static Color _lighten(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );

  static Color _shade(Color c, double factor) => Color.fromARGB(
        c.alpha,
        (c.red * factor).round().clamp(0, 255),
        (c.green * factor).round().clamp(0, 255),
        (c.blue * factor).round().clamp(0, 255),
      );
}
