import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../data/maze_themes.dart';
import '../../models/level_data.dart' show GridPos;
import '../../models/maze_data.dart';
import '../board_layout.dart';
import 'boss_maze_game.dart';

/// Опасности лабиринта: статичные ловушки, движущиеся препятствия
/// и пульсация финиша.
///
/// Слой только рисует. Попадания считает сама игра в update - иначе
/// картинка и правила разъехались бы на просадке кадров.
///
/// Все кисти создаются один раз: render() вызывается каждый кадр.
class MazeHazardsComponent extends Component {
  MazeHazardsComponent(this.game) : super(priority: 4);

  final BossMazeGame game;

  double _time = 0;

  final Paint _trapGlow = Paint();
  final Paint _trapBody = Paint();
  final Paint _trapSpike = Paint();
  final Paint _moverGlow = Paint();
  final Paint _moverBody = Paint();
  final Paint _moverBlade = Paint();
  final Paint _finishPulse = Paint()..style = PaintingStyle.stroke;

  @override
  Future<void> onLoad() async {
    final MazeTheme t = game.theme;
    _trapGlow.color = t.trap.withOpacity(0.22);
    _trapBody.color = t.trap;
    _trapSpike.color = const Color(0xE6FFFFFF);
    _moverGlow.color = t.hazard.withOpacity(0.24);
    _moverBody.color = t.hazard;
    _moverBlade.color = const Color(0xCC101820);
    _finishPulse.color = t.finish;
  }

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    _renderFinish(canvas, layout);
    _renderTraps(canvas, layout);
    _renderMovers(canvas, layout);
  }

  /// Финиш дышит кольцом - его видно издалека даже на большой карте.
  void _renderFinish(Canvas canvas, BoardLayout layout) {
    final double cell = layout.cell;
    final Offset c = game.pixelOfCell(game.maze.finish);
    final double t = (math.sin(_time * 2.4) + 1) / 2;

    _finishPulse
      ..strokeWidth = math.max(1.2, cell * 0.06)
      ..color = game.theme.finish.withOpacity(0.55 - t * 0.35);
    canvas.drawCircle(c, cell * (0.45 + t * 0.30), _finishPulse);
  }

  /// Ловушка: тревожный круг с бегающими по нему зубьями.
  void _renderTraps(Canvas canvas, BoardLayout layout) {
    final double cell = layout.cell;
    final double pulse = 0.85 + 0.15 * math.sin(_time * 5.0);
    final double spin = _time * 1.6;

    for (final GridPos trap in game.maze.traps) {
      final Offset c = game.pixelOfCell(trap);
      if (!_isVisible(c, cell)) continue;

      canvas.drawCircle(c, cell * 0.42 * pulse, _trapGlow);
      canvas.drawCircle(c, cell * 0.24, _trapBody);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(spin);
      for (int i = 0; i < 6; i++) {
        canvas.rotate(math.pi / 3);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -cell * 0.31),
              width: cell * 0.09,
              height: cell * 0.16,
            ),
            Radius.circular(cell * 0.03),
          ),
          _trapBody,
        );
      }
      canvas.restore();

      canvas.drawCircle(c, cell * 0.09, _trapSpike);
    }
  }

  /// Движущееся препятствие: буксировщик с мигалкой, идущий по коридору.
  void _renderMovers(Canvas canvas, BoardLayout layout) {
    final double cell = layout.cell;
    final double time = game.attemptTime;
    final double blink = 0.7 + 0.3 * math.sin(_time * 7.0);

    for (final MazeMover mover in game.maze.movers) {
      final ({double col, double row}) p = mover.positionAt(time);
      final Offset c = game.pixelOf(p.col, p.row);
      if (!_isVisible(c, cell)) continue;

      canvas.drawCircle(c, cell * 0.46 * blink, _moverGlow);

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(_time * 2.2);
      for (int i = 0; i < 4; i++) {
        canvas.rotate(math.pi / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -cell * 0.24),
              width: cell * 0.14,
              height: cell * 0.30,
            ),
            Radius.circular(cell * 0.05),
          ),
          _moverBody,
        );
      }
      canvas.restore();

      canvas.drawCircle(c, cell * 0.15, _moverBlade);
      canvas.drawCircle(c, cell * 0.07, _moverBody);
    }
  }

  /// За экран не рисуем: на больших картах препятствий много,
  /// а видна всегда только часть поля.
  bool _isVisible(Offset point, double cell) {
    final Vector2 view = game.size;
    return point.dx > -cell &&
        point.dy > -cell &&
        point.dx < view.x + cell &&
        point.dy < view.y + cell;
  }
}
