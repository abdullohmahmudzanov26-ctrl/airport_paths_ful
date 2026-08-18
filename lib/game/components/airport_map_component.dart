import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../models/board_theme.dart';
import '../../models/level_data.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Статичная часть поля: подложка, сеть рулёжных дорожек, разметка,
/// постройки, площадки и стоянки.
///
/// Два решения определяют вид карты.
///
/// Первое: сеть дорожек рисуется ТОЛСТОЙ ЛИНИЕЙ по связям между клетками,
/// а не заливкой квадратов. Скругления на поворотах и стыки получаются
/// сами собой — раньше дорожки выглядели лоскутным одеялом.
///
/// Второе: всё это пишется один раз в ui.Picture и дальше выводится
/// одной командой. На кадр приходится drawPicture вместо сотен заливок.
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
    final BoardTheme t = game.theme;
    final double cell = layout.cell;

    // Один и тот же seed - одна и та же карта при каждом рендере.
    final math.Random rnd = math.Random(level.id * 7717 + 13);

    _paintGround(canvas, layout, t, rnd);
    _paintNetwork(canvas, layout, level, t);
    _paintMarkings(canvas, layout, level, t);
    if (t.style == BoardStyle.night) _paintEdgeLights(canvas, layout, level, t);
    if (t.style == BoardStyle.orbital) _paintNodes(canvas, layout, level, t);
    _paintStructures(canvas, layout, level, t, rnd);

    for (final PlaneSpec spec in level.planes) {
      final Color color =
          PlaneColors.all[spec.colorIndex % PlaneColors.all.length];
      _paintStartPad(canvas, layout.rectOf(spec.start), color, cell);
      _paintGate(canvas, layout.rectOf(spec.gate), color, cell, t);
    }

    _picture = recorder.endRecording();
    _builtForCell = cell;
    _builtForOrigin = layout.origin;
  }

  // -------------------------------------------------------------- подложка

  void _paintGround(
    Canvas canvas,
    BoardLayout layout,
    BoardTheme t,
    math.Random rnd,
  ) {
    final Rect board = layout.board;
    final double cell = layout.cell;
    final RRect outer = RRect.fromRectAndRadius(
      board.inflate(cell * 0.18),
      Radius.circular(cell * 0.5),
    );

    canvas.drawRRect(
      outer.shift(Offset(0, cell * 0.10)),
      Paint()..color = const Color(0x66000814),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[t.groundTop, t.groundBottom],
        ).createShader(board),
    );

    canvas.save();
    canvas.clipRRect(outer);

    switch (t.style) {
      case BoardStyle.day:
      case BoardStyle.night:
        // Пятна на грунте: поле перестаёт быть плоской заливкой.
        final Paint patch = Paint()..color = t.groundPatch;
        for (int i = 0; i < 18; i++) {
          canvas.drawCircle(
            Offset(
              board.left + rnd.nextDouble() * board.width,
              board.top + rnd.nextDouble() * board.height,
            ),
            cell * (0.3 + rnd.nextDouble() * 0.7),
            patch,
          );
        }
        break;

      case BoardStyle.blueprint:
        // Координатная сетка радара.
        final Paint grid = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = t.groundPatch;
        for (int c = 0; c <= layout.cols; c++) {
          final double x = layout.origin.dx + c * cell;
          canvas.drawLine(Offset(x, board.top), Offset(x, board.bottom), grid);
        }
        for (int r = 0; r <= layout.rows; r++) {
          final double y = layout.origin.dy + r * cell;
          canvas.drawLine(Offset(board.left, y), Offset(board.right, y), grid);
        }
        break;

      case BoardStyle.orbital:
        // Звёздное поле и две туманности.
        for (int i = 0; i < 110; i++) {
          final double s = rnd.nextDouble();
          canvas.drawCircle(
            Offset(
              board.left + rnd.nextDouble() * board.width,
              board.top + rnd.nextDouble() * board.height,
            ),
            s * 1.7 + 0.4,
            Paint()..color = Color.fromRGBO(255, 255, 255, 0.15 + s * 0.6),
          );
        }
        _nebula(canvas, board, Offset(board.right - board.width * 0.25,
            board.top + board.height * 0.18), board.width * 0.75,
            const Color(0x4D7A3CDC));
        _nebula(canvas, board, Offset(board.left + board.width * 0.2,
            board.bottom - board.height * 0.2), board.width * 0.65,
            const Color(0x3300BEDC));
        break;
    }

    canvas.restore();
  }

  void _nebula(Canvas canvas, Rect board, Offset c, double r, Color color) {
    canvas.drawRect(
      board,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  // ---------------------------------------------------------- сеть дорожек

  /// Путь по всем связям между проходимыми клетками.
  /// Одиночные клетки добавляются точкой, чтобы не выпадать из сети.
  Path _networkPath(BoardLayout layout, LevelData level) {
    final Path path = Path();
    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final GridPos pos = GridPos(col, row);
        if (!level.isWalkable(pos)) continue;
        final Offset c = layout.center(pos);

        path.moveTo(c.dx, c.dy);
        path.lineTo(c.dx + 0.01, c.dy);

        for (final GridPos nb in <GridPos>[pos.step(1, 0), pos.step(0, 1)]) {
          if (!level.isWalkable(nb)) continue;
          final Offset n = layout.center(nb);
          path.moveTo(c.dx, c.dy);
          path.lineTo(n.dx, n.dy);
        }
      }
    }
    return path;
  }

  Paint _stroke(double width, Color color) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = color;

  void _paintNetwork(
    Canvas canvas,
    BoardLayout layout,
    LevelData level,
    BoardTheme t,
  ) {
    final double cell = layout.cell;
    final Path net = _networkPath(layout, level);

    switch (t.style) {
      case BoardStyle.day:
        canvas.drawPath(net, _stroke(cell * 0.96, t.asphaltEdge));
        canvas.drawPath(net, _stroke(cell * 0.86, t.asphalt));
        canvas.drawPath(net, _stroke(cell * 0.78, t.asphaltLight));
        break;

      case BoardStyle.night:
        canvas.drawPath(net, _stroke(cell * 0.94, t.asphaltEdge));
        canvas.drawPath(net, _stroke(cell * 0.84, t.asphalt));
        canvas.drawPath(net, _stroke(cell * 0.74, t.asphaltLight));
        break;

      case BoardStyle.blueprint:
      case BoardStyle.orbital:
        // Свечение кромки: три обводки с падающей прозрачностью
        // дают ореол без дорогого размытия.
        canvas.drawPath(net, _stroke(cell * 1.02, t.asphaltEdge.withOpacity(0.16)));
        canvas.drawPath(net, _stroke(cell * 0.94, t.asphaltEdge.withOpacity(0.30)));
        canvas.drawPath(net, _stroke(cell * 0.86, t.asphaltEdge));
        canvas.drawPath(net, _stroke(cell * 0.80, t.asphalt));
        canvas.drawPath(net, _stroke(cell * 0.70, t.asphaltLight));
        break;
    }
  }

  /// Пунктирная осевая. В Canvas нет штриховых линий,
  /// поэтому раскладываем штрихи руками.
  void _paintMarkings(
    Canvas canvas,
    BoardLayout layout,
    LevelData level,
    BoardTheme t,
  ) {
    final double cell = layout.cell;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, cell * 0.05)
      ..strokeCap = StrokeCap.butt
      ..color = t.marking;

    final double dash = cell * 0.17;
    final double gap = cell * 0.14;

    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final GridPos pos = GridPos(col, row);
        if (!level.isWalkable(pos)) continue;
        final Offset a = layout.center(pos);

        for (final GridPos nb in <GridPos>[pos.step(1, 0), pos.step(0, 1)]) {
          if (!level.isWalkable(nb)) continue;
          final Offset b = layout.center(nb);
          final double len = (b - a).distance;
          final Offset dir = (b - a) / len;

          double t0 = 0;
          while (t0 < len) {
            final double t1 = math.min(t0 + dash, len);
            canvas.drawLine(a + dir * t0, a + dir * t1, paint);
            t0 = t1 + gap;
          }
        }
      }
    }
  }

  /// Ночь: огни по кромке дорожек — тёмное поле читается только так.
  void _paintEdgeLights(
    Canvas canvas,
    BoardLayout layout,
    LevelData level,
    BoardTheme t,
  ) {
    final double cell = layout.cell;
    final Paint halo = Paint()..color = const Color(0x335FC8FF);
    final Paint dot = Paint()..color = const Color(0xFF8FD8FF);

    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final GridPos pos = GridPos(col, row);
        if (!level.isWalkable(pos)) continue;
        final Offset c = layout.center(pos);

        for (final GridPos nb in <GridPos>[
          pos.step(1, 0),
          pos.step(-1, 0),
          pos.step(0, 1),
          pos.step(0, -1),
        ]) {
          if (level.isWalkable(nb)) continue;
          final Offset d = Offset(
            (nb.col - pos.col).toDouble(),
            (nb.row - pos.row).toDouble(),
          );
          final Offset p = c + d * (cell * 0.42);
          canvas.drawCircle(p, cell * 0.13, halo);
          canvas.drawCircle(p, cell * 0.055, dot);
        }
      }
    }
  }

  /// Орбита: узлы платформ в центрах клеток.
  void _paintNodes(
    Canvas canvas,
    BoardLayout layout,
    LevelData level,
    BoardTheme t,
  ) {
    final Paint node = Paint()..color = t.glass.withOpacity(0.5);
    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final GridPos pos = GridPos(col, row);
        if (!level.isWalkable(pos)) continue;
        canvas.drawCircle(layout.center(pos), layout.cell * 0.05, node);
      }
    }
  }

  // --------------------------------------------------------------- объекты

  void _paintStructures(
    Canvas canvas,
    BoardLayout layout,
    LevelData level,
    BoardTheme t,
    math.Random rnd,
  ) {
    for (int row = 0; row < level.rows; row++) {
      for (int col = 0; col < level.cols; col++) {
        final TileType tile = level.tileAt(col, row);
        if (!tile.isObstacle) continue;
        final Rect r = layout.rectOf(GridPos(col, row));

        if (t.style == BoardStyle.blueprint) {
          _paintOutlined(canvas, r, t, tile);
          continue;
        }
        switch (tile) {
          case TileType.grass:
            _paintGrassPatch(canvas, r, rnd, t);
            break;
          case TileType.building:
            _paintBuilding(canvas, r, rnd, t);
            break;
          case TileType.terminal:
            _paintTerminal(canvas, r, t);
            break;
          case TileType.hangar:
            _paintHangar(canvas, r, t);
            break;
          case TileType.tower:
            _paintTower(canvas, r, t);
            break;
          case TileType.taxiway:
            break;
        }
      }
    }
  }

  /// Схема диспетчера: объекты контурами, без объёма.
  void _paintOutlined(Canvas canvas, Rect r, BoardTheme t, TileType tile) {
    final bool green = tile == TileType.grass;
    final RRect shape = RRect.fromRectAndRadius(
      r.deflate(r.width * 0.14),
      Radius.circular(r.width * 0.12),
    );
    canvas.drawRRect(shape, Paint()..color = green ? t.grass : t.structure);
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, r.width * 0.035)
        ..color = green ? t.grassDot : t.structureLight,
    );
    if (green) return;

    final Paint cross = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, r.width * 0.025)
      ..color = t.structureDark;
    canvas.drawLine(shape.outerRect.topLeft, shape.outerRect.bottomRight, cross);
    canvas.drawLine(shape.outerRect.topRight, shape.outerRect.bottomLeft, cross);
  }

  void _paintGrassPatch(Canvas canvas, Rect r, math.Random rnd, BoardTheme t) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        r.deflate(r.width * 0.06),
        Radius.circular(r.width * 0.28),
      ),
      Paint()..color = t.grass,
    );
    final Paint dot = Paint()..color = t.grassDot;
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

  void _paintBuilding(Canvas canvas, Rect r, math.Random rnd, BoardTheme t) {
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
      Paint()..color = t.structure,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        base.deflate(r.width * 0.09).shift(Offset(0, -r.height * 0.04)),
        Radius.circular(radius * 0.8),
      ),
      Paint()..color = t.structureLight,
    );

    final Paint vent = Paint()..color = t.structureDark;
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

  void _paintTerminal(Canvas canvas, Rect r, BoardTheme t) {
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
      Paint()..color = t.structure,
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
      Paint()..color = t.glass,
    );

    // Рёбра остекления и телетрап - деталь пишется в Picture один раз,
    // на кадр это не стоит ничего.
    final Paint rib = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r.width * 0.018)
      ..color = t.structureDark;
    for (int i = 1; i < 4; i++) {
      final double x = base.left + base.width * (0.1 + 0.2 * i);
      canvas.drawLine(
        Offset(x, base.top + base.height * 0.30),
        Offset(x, base.top + base.height * 0.54),
        rib,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          base.left + base.width * 0.36,
          base.top + base.height * 0.62,
          base.width * 0.28,
          base.height * 0.30,
        ),
        Radius.circular(r.width * 0.04),
      ),
      Paint()..color = t.structureLight,
    );
  }

  void _paintHangar(Canvas canvas, Rect r, BoardTheme t) {
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
    canvas.drawRRect(shape, Paint()..color = t.structureLight);
    canvas.drawRect(
      Rect.fromLTWH(
        base.left + base.width * 0.18,
        base.top + base.height * 0.55,
        base.width * 0.64,
        base.height * 0.45,
      ),
      Paint()..color = t.structureDark,
    );

    // Рёбра свода и створки ворот.
    final Paint seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r.width * 0.02)
      ..color = t.structure;
    for (int i = 1; i < 3; i++) {
      final double y = base.top + base.height * (0.16 + 0.16 * i);
      canvas.drawLine(
        Offset(base.left + base.width * 0.14, y),
        Offset(base.right - base.width * 0.14, y),
        seam,
      );
    }
    canvas.drawLine(
      Offset(base.center.dx, base.top + base.height * 0.55),
      Offset(base.center.dx, base.bottom),
      seam,
    );
  }

  void _paintTower(Canvas canvas, Rect r, BoardTheme t) {
    final double cx = r.center.dx;
    canvas.drawRect(
      Rect.fromLTWH(
        cx - r.width * 0.12,
        r.top + r.height * 0.35,
        r.width * 0.24,
        r.height * 0.6,
      ),
      Paint()..color = t.structure,
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
      Paint()..color = t.structureLight,
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
      Paint()..color = t.glass,
    );
    // Галерея по периметру кабины и антенна над маяком.
    final Paint rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, r.width * 0.022)
      ..color = t.structureDark;
    canvas.drawLine(
      Offset(cx - r.width * 0.32, r.top + r.height * 0.44),
      Offset(cx + r.width * 0.32, r.top + r.height * 0.44),
      rail,
    );
    canvas.drawLine(
      Offset(cx, r.top + r.height * 0.02),
      Offset(cx, r.top + r.height * 0.14),
      rail,
    );

    canvas.drawCircle(
      Offset(cx, r.top + r.height * 0.12),
      r.width * 0.06,
      Paint()..color = t.beacon,
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

  /// Стоянка: цветная рамка с шевронами — сразу видно, чей это выход.
  void _paintGate(
    Canvas canvas,
    Rect r,
    Color color,
    double cell,
    BoardTheme t,
  ) {
    final RRect pad = RRect.fromRectAndRadius(
      r.deflate(cell * 0.12),
      Radius.circular(cell * 0.18),
    );
    canvas.drawRRect(pad, Paint()..color = t.padDark);
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
