import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/maze_data.dart';
import '../board_layout.dart';
import 'boss_maze_game.dart';

/// Мини-карта в углу экрана.
///
/// Появляется только тогда, когда лабиринт не влезает в экран целиком:
/// на маленьких боссах она не нужна и не отнимает место. Показывает
/// схему коридоров, финиш и текущее положение борта - без ловушек,
/// иначе исчезла бы вся разведка.
class MazeMinimapComponent extends Component {
  MazeMinimapComponent(this.game) : super(priority: 12);

  final BossMazeGame game;

  static const double _maxSide = 92;
  static const double _margin = 10;

  Picture? _picture;
  double _builtForScale = -1;
  double _scale = 0;
  Rect _frame = Rect.zero;

  final Paint _plane = Paint()..color = const Color(0xFFFFFFFF);
  final Paint _planeRing = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  bool get _needed =>
      game.maze.cols > BossMazeGame.maxVisibleCols ||
      game.maze.rows > BossMazeGame.maxVisibleRows;

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (!_needed) return;
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final Vector2 view = game.size;
    final MazeSpec maze = game.maze;

    final double scale = math.min(
      _maxSide / maze.cols,
      _maxSide / maze.rows,
    );
    if (scale <= 0) return;

    final double width = maze.cols * scale;
    final double height = maze.rows * scale;
    _frame = Rect.fromLTWH(view.x - width - _margin, _margin, width, height);

    if (_picture == null || _builtForScale != scale) {
      _buildPicture(scale);
      _scale = scale;
    }

    final RRect shape = RRect.fromRectAndRadius(
      _frame.inflate(5),
      const Radius.circular(9),
    );
    canvas.drawRRect(shape, Paint()..color = const Color(0x8C000000));
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = game.theme.accent.withOpacity(0.45),
    );

    final Picture? picture = _picture;
    if (picture != null) {
      canvas.save();
      canvas.translate(_frame.left, _frame.top);
      canvas.drawPicture(picture);
      canvas.restore();
    }

    // Борт: точка с кольцом, чтобы читалась на любой подложке.
    final Offset dot = Offset(
      _frame.left + game.planeCol * _scale,
      _frame.top + game.planeRow * _scale,
    );
    _planeRing.color = game.theme.accent;
    canvas.drawCircle(dot, 2.6, _plane);
    canvas.drawCircle(dot, 4.2, _planeRing);
  }

  void _buildPicture(double scale) {
    _picture?.dispose();

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final MazeSpec maze = game.maze;

    final Paint floor = Paint()..color = game.theme.floor.withOpacity(0.55);
    for (int r = 0; r < maze.rows; r++) {
      for (int c = 0; c < maze.cols; c++) {
        if (maze.isBlocked(c, r)) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * scale, r * scale, scale, scale),
          floor,
        );
      }
    }

    canvas.drawRect(
      Rect.fromLTWH(
        maze.finish.col * scale,
        maze.finish.row * scale,
        scale,
        scale,
      ),
      Paint()..color = game.theme.finish,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        maze.start.col * scale,
        maze.start.row * scale,
        scale,
        scale,
      ),
      Paint()..color = game.theme.start.withOpacity(0.8),
    );

    _picture = recorder.endRecording();
    _builtForScale = scale;
  }
}
