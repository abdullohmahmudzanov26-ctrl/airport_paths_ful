import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/level_data.dart';
import '../../theme/app_palette.dart';
import '../airport_game.dart';
import '../board_layout.dart';

/// Обучение на первом уровне: по эталонному маршруту бежит «палец»,
/// за ним тянется след из точек, а стартовая площадка пульсирует.
///
/// Показывать нечего, если игрок уже начал вести линию, — подсказка
/// исчезает сама и возвращается, если он всё стёр.
class TutorialLayerComponent extends Component {
  TutorialLayerComponent(this.game) : super(priority: 4);

  final AirportGame game;

  /// Клеток в секунду — заметно медленнее самолёта, чтобы успеть прочитать.
  static const double handSpeed = 1.9;
  static const double pauseSeconds = 1.0;

  double _time = 0;

  @override
  void update(double dt) {
    if (game.showTutorial) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!game.showTutorial) return;
    final BoardLayout layout = game.layout;
    if (!layout.isReady) return;

    final PlaneSpec spec = game.level.planes.first;
    final List<GridPos> path = spec.solution;
    if (path.length < 2) return;

    final double cell = layout.cell;
    final Color color =
        PlaneColors.all[spec.colorIndex % PlaneColors.all.length];

    final double total = (path.length - 1).toDouble();
    final double cycle = total / handSpeed + pauseSeconds;
    final double head =
        math.min((_time % cycle) * handSpeed, total);

    // След: точки загораются по мере приближения «пальца».
    final Paint dot = Paint();
    for (int i = 0; i < path.length; i++) {
      final double d = head - i;
      if (d < -0.6) continue;
      final double alpha = (1.0 - (d / 3.2)).clamp(0.0, 1.0);
      if (alpha <= 0.02) continue;
      dot.color = color.withOpacity(0.55 * alpha);
      canvas.drawCircle(layout.center(path[i]), cell * 0.11, dot);
    }

    // Пульсирующее кольцо на стоянке — куда именно вести.
    final double wave = (math.sin(_time * 3.0) + 1) / 2;
    canvas.drawCircle(
      layout.center(path.last),
      cell * (0.34 + 0.07 * wave),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.06
        ..color = color.withOpacity(0.35 + 0.4 * wave),
    );

    // «Палец».
    final int i = head.floor().clamp(0, path.length - 1);
    final int next = math.min(i + 1, path.length - 1);
    final double f = (head - i).clamp(0.0, 1.0);
    final Offset a = layout.center(path[i]);
    final Offset b = layout.center(path[next]);
    final Offset hand =
        Offset(a.dx + (b.dx - a.dx) * f, a.dy + (b.dy - a.dy) * f);

    canvas.drawCircle(
      hand.translate(0, cell * 0.05),
      cell * 0.21,
      Paint()..color = const Color(0x59000000),
    );
    canvas.drawCircle(
      hand,
      cell * 0.20,
      Paint()..color = const Color(0xE6FFFFFF),
    );
    canvas.drawCircle(
      hand,
      cell * 0.20,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.05
        ..color = color,
    );
  }
}
