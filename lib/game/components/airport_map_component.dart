import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/level_data.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Статичная часть поля: трава, рулёжки, разметка, здания, ангары,
/// вышка, стоянки и площадки самолётов.
///
/// Ничего из этого не меняется в течение уровня, поэтому вся карта
/// пишется один раз в ui.Picture и потом выводится одной командой.
/// На кадр приходится drawPicture вместо сотен drawRect - именно это
/// держит 60 FPS на слабых телефонах.
class AirportMapComponent extends Component {
  AirportMapComponent(this.game) : super(priority: 0);

  final AirportGame game;

  Picture? _picture;
  double _builtForCell = -1;
  Offset _builtForOrigin = Offset.zero;

  void invalidate() {
    _picture?.dispose();
    _picture = null;
    _builtForCell = -1;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    if (_picture == null ||
        _builtForCell != layout.cell ||
        _builtForOrigin != layout.origin) {
      _build(layout);
    }
    final Picture? picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }

  void _build(BoardLayout layout) {
    _picture?.dispose();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final LevelData level = game.level;
    final double cell = layout.cell;

    // Один и тот же seed - одна и та же карта при каждом рендере.
    final math.Random rnd = math.Random(level.id * 7717 + 13);

    _paintGround(canvas, layout, rnd);
    _paintTaxiways(canvas, layout, level);
    _paintMarkings(canvas, layout, level);

    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final TileType tile = level.tileAt(col, row);
        if (!tile.isObstacle) continue;
        final Rect r = layout.rectOf(GridPos(col, row));
        switch (tile) {
          case TileType.grass:
            _paintGrassPatch(canvas, r, rnd);
            break;
          case TileType.building:
            _paintBuilding(canvas, r, rnd);
            break;
          case TileType.terminal:
            _paintTerminal(canvas, r);
            break;
          case TileType.hangar:
            _paintHangar(canvas, r);
            break;
          case TileType.tower:
            _paintTower(canvas, r);
            break;
          case TileType.taxiway:
            break;
        }
      }
    }

    for (final PlaneSpec spec in level.planes) {
      final Color color =
          PlaneColors.all[spec.colorIndex % PlaneColors.all.length];
      _paintStartPad(canvas, layout.rectOf(spec.start), color, cell);
      _paintGate(canvas, layout.rectOf(spec.gate), color, cell);
    }

    _picture = recorder.endRecording();
    _builtForCell = cell;
    _builtForOrigin = layout.origin;
  }

  // -------------------------------------------------------------- подложка

  void _paintGround(Canvas canvas, BoardLayout layout, math.Random rnd) {
    final Rect board = layout.board;
    final RRect outer = RRect.fromRectAndRadius(
      board.inflate(layout.cell * 0.18),
      Radius.circular(layout.cell * 0.5),
    );

    canvas.drawRRect(
      outer.shift(Offset(0, layout.cell * 0.10)),
      Paint()..color = const Color(0x66000814),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF4F7C3F), Color(0xFF34602B)],
        ).createShader(board),
    );

    // Пятна травы: карта перестаёт выглядеть плоской заливкой.
    final Paint patch = Paint()..color = const Color(0x1A0D2A0B);
    for (int i = 0; i < 14; i++) {
      final double x = board.left + rnd.nextDouble() * board.width;
      final double y = board.top + rnd.nextDouble() * board.height;
      final double r = layout.cell * (0.3 + rnd.nextDouble() * 0.6);
      canvas.drawCircle(Offset(x, y), r, patch);
    }
  }

  void _paintTaxiways(Canvas canvas, BoardLayout layout, LevelData level) {
    final Paint asphalt = Paint()..color = const Color(0xFF4A5058);
    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        if (!level.tileAt(col, row).isWalkable) continue;
        // Небольшой нахлёст убирает швы между соседними клетками.
        canvas.drawRect(layout.rectOf(GridPos(col, row)).inflate(0.6), asphalt);
      }
    }
  }

  /// Жёлтая осевая линия: рисуется от центра клетки к центрам проходимых
  /// соседей и сама складывается в сеть рулёжных дорожек.
  void _paintMarkings(Canvas canvas, BoardLayout layout, LevelData level) {
    final double cell = layout.cell;
    final Paint line = Paint()
      ..color = const Color(0x8CF2C230)
      ..strokeWidth = math.max(1.2, cell * 0.05)
      ..strokeCap = StrokeCap.round;

    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final GridPos pos = GridPos(col, row);
        if (!level.isWalkable(pos)) continue;
        final Offset c = layout.center(pos);
        for (final GridPos nb in <GridPos>[pos.step(1, 0), pos.step(0, 1)]) {
          if (!level.isWalkable(nb)) continue;
          canvas.drawLine(c, layout.center(nb), line);
        }
      }
    }
  }

  // --------------------------------------------------------------- объекты

  void _paintGrassPatch(Canvas canvas, Rect r, math.Random rnd) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        r.deflate(r.width * 0.06),
        Radius.circular(r.width * 0.28),
      ),
      Paint()..color = const Color(0xFF3E6B32),
    );
    final Paint dot = Paint()..color = const Color(0xFF57893F);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          r.left + r.width * (0.25 + rnd.nextDouble() * 0.5),
          r.top + r.height * (0.25 + rnd.nextDouble() * 0.5),
        ),
        r.width * 0.11,
        dot,
      );
    }
  }

  void _paintBuilding(Canvas canvas, Rect r, math.Random rnd) {
    final Rect base = r.deflate(r.width * 0.08);
    final double radius = r.width * 0.12;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        base.shift(Offset(0, r.height * 0.07)),
        Radius.circular(radius),
      ),
      Paint()..color = const Color(0x59000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(radius)),
      Paint()..color = const Color(0xFF5A6472),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        base.deflate(r.width * 0.09).shift(Offset(0, -r.height * 0.04)),
        Radius.circular(radius * 0.8),
      ),
      Paint()..color = const Color(0xFF7C8896),
    );

    final Paint vent = Paint()..color = const Color(0xFF48525F);
    for (int i = 0; i < 2; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          base.left + base.width * (0.22 + i * 0.34),
          base.top + base.height * (0.18 + rnd.nextDouble() * 0.1),
          base.width * 0.18,
          base.height * 0.14,
        ),
        vent,
      );
    }
  }

  void _paintTerminal(Canvas canvas, Rect r) {
    final Rect base = r.deflate(r.width * 0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        base.shift(Offset(0, r.height * 0.06)),
        Radius.circular(r.width * 0.16),
      ),
      Paint()..color = const Color(0x59000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(base, Radius.circular(r.width * 0.16)),
      Paint()..color = const Color(0xFF66707E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.left + base.width * 0.1,
          base.top + base.height * 0.3,
          base.width * 0.8,
          base.height * 0.24,
        ),
        Radius.circular(r.width * 0.06),
      ),
      Paint()..color = const Color(0xFF9FD3F0),
    );
  }

  void _paintHangar(Canvas canvas, Rect r) {
    final Rect base = r.deflate(r.width * 0.07);
    final RRect shape = RRect.fromRectAndCorners(
      base,
      topLeft: Radius.circular(r.width * 0.42),
      topRight: Radius.circular(r.width * 0.42),
      bottomLeft: Radius.circular(r.width * 0.08),
      bottomRight: Radius.circular(r.width * 0.08),
    );

    canvas.drawRRect(
      shape.shift(Offset(0, r.height * 0.06)),
      Paint()..color = const Color(0x59000000),
    );
    canvas.drawRRect(shape, Paint()..color = const Color(0xFF7A8593));
    canvas.drawRect(
      Rect.fromLTWH(
        base.left + base.width * 0.18,
        base.top + base.height * 0.55,
        base.width * 0.64,
        base.height * 0.45,
      ),
      Paint()..color = const Color(0xFF4E5866),
    );
  }

  void _paintTower(Canvas canvas, Rect r) {
    final double cx = r.center.dx;
    canvas.drawRect(
      Rect.fromLTWH(
        cx - r.width * 0.12,
        r.top + r.height * 0.35,
        r.width * 0.24,
        r.height * 0.6,
      ),
      Paint()..color = const Color(0xFF6B7683),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - r.width * 0.28,
          r.top + r.height * 0.18,
          r.width * 0.56,
          r.height * 0.26,
        ),
        Radius.circular(r.width * 0.1),
      ),
      Paint()..color = const Color(0xFF8B98A6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - r.width * 0.22,
          r.top + r.height * 0.22,
          r.width * 0.44,
          r.height * 0.14,
        ),
        Radius.circular(r.width * 0.05),
      ),
      Paint()..color = const Color(0xFF9FD3F0),
    );
    canvas.drawCircle(
      Offset(cx, r.top + r.height * 0.12),
      r.width * 0.06,
      Paint()..color = const Color(0xFFFF5A4D),
    );
  }

  void _paintStartPad(Canvas canvas, Rect r, Color color, double cell) {
    canvas.drawCircle(
      r.center,
      cell * 0.44,
      Paint()..color = const Color(0x40000000),
    );
    canvas.drawCircle(
      r.center,
      cell * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06
        ..color = color.withOpacity(0.55),
    );
  }

  /// Стоянка: цветная рамка с шевронами - сразу видно, чей это выход.
  void _paintGate(Canvas canvas, Rect r, Color color, double cell) {
    final RRect pad = RRect.fromRectAndRadius(
      r.deflate(cell * 0.12),
      Radius.circular(cell * 0.18),
    );
    canvas.drawRRect(pad, Paint()..color = const Color(0xFF2A2F36));
    canvas.drawRRect(
      pad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.09
        ..color = color,
    );

    final Paint chevron = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell * 0.07
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.85);

    final Offset c = r.center;
    final double s = cell * 0.16;
    for (int i = 0; i < 2; i++) {
      final double dy = -s * 0.5 + i * s;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx - s, c.dy + dy)
          ..lineTo(c.dx, c.dy + dy + s * 0.7)
          ..lineTo(c.dx + s, c.dy + dy),
        chevron,
      );
    }
  }
}
