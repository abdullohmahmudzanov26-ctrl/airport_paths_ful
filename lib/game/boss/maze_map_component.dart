import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/maze_themes.dart';
import '../../models/level_data.dart' show GridPos;
import '../../models/maze_data.dart';
import '../board_layout.dart';
import 'boss_maze_game.dart';

/// Статичная часть лабиринта: стены, коридоры, закрытые зоны,
/// площадка старта и финиш.
///
/// Приём тот же, что и у AirportMapComponent: всё пишется один раз в
/// ui.Picture и дальше выводится одной командой. Разница в том, что
/// картинка строится в СОБСТВЕННЫХ координатах доски (левый верхний
/// угол в нуле), а смещение камеры добавляется трансформацией канвы.
/// Иначе поле, которое едет за самолётом, перестраивало бы картинку
/// каждый кадр.
///
/// Коридоры рисуются толстой линией по связям между клетками, а не
/// заливкой квадратов: повороты скругляются сами собой.
class MazeMapComponent extends Component {
  MazeMapComponent(this.game) : super(priority: 0);

  final BossMazeGame game;

  Picture? _picture;
  double _builtForCell = -1;

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

    if (_picture == null || _builtForCell != layout.cell) {
      _build(layout.cell);
    }
    final Picture? picture = _picture;
    if (picture == null) return;

    canvas.save();
    canvas.translate(layout.origin.dx, layout.origin.dy);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  void _build(double cell) {
    _picture?.dispose();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final MazeSpec maze = game.maze;
    final MazeTheme t = game.theme;

    final Rect board = Rect.fromLTWH(0, 0, cell * maze.cols, cell * maze.rows);
    // Зерно от размеров карты: узор стен не «дрожит» между кадрами.
    final math.Random rnd = math.Random(maze.cols * 811 + maze.rows * 37);

    _paintWalls(canvas, board, cell, t, rnd);
    _paintCorridors(canvas, cell, maze, t);
    _paintClosedZones(canvas, cell, maze, t);
    _paintStart(canvas, cell, maze, t);
    _paintFinish(canvas, cell, maze, t);

    _picture = recorder.endRecording();
    _builtForCell = cell;
  }

  Offset _center(double cell, GridPos p) =>
      Offset((p.col + 0.5) * cell, (p.row + 0.5) * cell);

  /// Массив стен: сплошная подложка плюс лёгкая фактура, чтобы поле
  /// не выглядело плоской заливкой.
  void _paintWalls(
    Canvas canvas,
    Rect board,
    double cell,
    MazeTheme t,
    math.Random rnd,
  ) {
    final RRect shape =
        RRect.fromRectAndRadius(board, Radius.circular(cell * 0.5));

    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[t.wallTop, t.wallFace],
        ).createShader(board),
    );

    canvas.save();
    canvas.clipRRect(shape);

    // Кладка: короткие светлые штрихи вразнобой.
    final Paint brick = Paint()
      ..color = t.wallEdge.withOpacity(0.55)
      ..strokeWidth = math.max(1.0, cell * 0.045)
      ..strokeCap = StrokeCap.round;
    final int strokes = (board.width * board.height / (cell * cell * 3)).round();
    for (int i = 0; i < strokes; i++) {
      final double x = rnd.nextDouble() * board.width;
      final double y = rnd.nextDouble() * board.height;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + cell * (0.3 + rnd.nextDouble() * 0.4), y),
        brick,
      );
    }

    canvas.restore();

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, cell * 0.10)
        ..color = t.wallEdge,
    );
  }

  /// Коридоры: сначала тёмная кромка, потом покрытие, потом разметка
  /// по центру. Три прохода одним и тем же путём.
  void _paintCorridors(
    Canvas canvas,
    double cell,
    MazeSpec maze,
    MazeTheme t,
  ) {
    final Path network = Path();
    bool empty = true;

    for (int r = 0; r < maze.rows; r++) {
      for (int c = 0; c < maze.cols; c++) {
        if (maze.isBlocked(c, r)) continue;
        final Offset from = _center(cell, GridPos(c, r));

        // Точка на случай одиночной клетки без соседей.
        network.moveTo(from.dx, from.dy);
        network.lineTo(from.dx + 0.01, from.dy);
        empty = false;

        if (!maze.isBlocked(c + 1, r)) {
          final Offset to = _center(cell, GridPos(c + 1, r));
          network.moveTo(from.dx, from.dy);
          network.lineTo(to.dx, to.dy);
        }
        if (!maze.isBlocked(c, r + 1)) {
          final Offset to = _center(cell, GridPos(c, r + 1));
          network.moveTo(from.dx, from.dy);
          network.lineTo(to.dx, to.dy);
        }
      }
    }
    if (empty) return;

    canvas.drawPath(
      network,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.98
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = t.wallEdge,
    );

    canvas.drawPath(
      network,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.86
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = t.floor,
    );

    canvas.drawPath(
      network,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.62
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = t.floorAlt.withOpacity(0.85),
    );

    // Осевая разметка - тонкая пунктирная нить по тем же связям.
    canvas.drawPath(
      network,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, cell * 0.055)
        ..strokeCap = StrokeCap.round
        ..color = t.floorLine.withOpacity(0.32),
    );
  }

  /// Закрытая зона: тупик, забранный решёткой. Ставится только вне
  /// гарантированного пути, поэтому лабиринт остаётся проходимым.
  void _paintClosedZones(
    Canvas canvas,
    double cell,
    MazeSpec maze,
    MazeTheme t,
  ) {
    final Paint fill = Paint()..color = t.closedZone;
    final Paint stripe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, cell * 0.09)
      ..color = t.closedStripe.withOpacity(0.75);

    for (int r = 0; r < maze.rows; r++) {
      for (int c = 0; c < maze.cols; c++) {
        if (maze.tileAt(c, r) != MazeTile.closed) continue;

        final Rect box = Rect.fromLTWH(
          c * cell + cell * 0.08,
          r * cell + cell * 0.08,
          cell * 0.84,
          cell * 0.84,
        );
        final RRect shape =
            RRect.fromRectAndRadius(box, Radius.circular(cell * 0.16));

        canvas.drawRRect(shape, fill);
        canvas.save();
        canvas.clipRRect(shape);
        for (double x = box.left - box.height; x < box.right; x += cell * 0.3) {
          canvas.drawLine(
            Offset(x, box.bottom),
            Offset(x + box.height, box.top),
            stripe,
          );
        }
        canvas.restore();

        canvas.drawRRect(
          shape,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.0, cell * 0.06)
            ..color = t.wallEdge,
        );
      }
    }
  }

  void _paintStart(Canvas canvas, double cell, MazeSpec maze, MazeTheme t) {
    final Offset c = _center(cell, maze.start);

    canvas.drawCircle(
      c,
      cell * 0.40,
      Paint()..color = t.start.withOpacity(0.20),
    );
    canvas.drawCircle(
      c,
      cell * 0.34,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, cell * 0.07)
        ..color = t.start.withOpacity(0.85),
    );
  }

  /// Финиш: площадка в шашечку с кольцом. Пульсацию поверх рисует
  /// слой опасностей - здесь только статика.
  void _paintFinish(Canvas canvas, double cell, MazeSpec maze, MazeTheme t) {
    final Offset c = _center(cell, maze.finish);
    final Rect box = Rect.fromCenter(
      center: c,
      width: cell * 0.86,
      height: cell * 0.86,
    );
    final RRect shape =
        RRect.fromRectAndRadius(box, Radius.circular(cell * 0.18));

    canvas.drawRRect(shape, Paint()..color = t.finish.withOpacity(0.22));

    canvas.save();
    canvas.clipRRect(shape);
    final Paint dark = Paint()..color = t.finish.withOpacity(0.55);
    final double q = box.width / 4;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if ((i + j).isEven) continue;
        canvas.drawRect(
          Rect.fromLTWH(box.left + i * q, box.top + j * q, q, q),
          dark,
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, cell * 0.07)
        ..color = t.finish,
    );
  }
}
