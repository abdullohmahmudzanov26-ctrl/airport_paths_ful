import 'dart:math' as math;

import 'level_data.dart' show GridPos;

/// Клетка лабиринта.
///
/// [floor] - проходимый коридор, [wall] - стена, [closed] - закрытая
/// зона: тот же тупик, но опечатанный, в него нельзя войти. Отдельный
/// тип нужен только ради вида: закрытая зона рисуется иначе, чем стена.
enum MazeTile { wall, floor, closed }

extension MazeTileX on MazeTile {
  bool get isWalkable => this == MazeTile.floor;
}

/// Движущееся препятствие: ходит по прямому отрезку [a]-[b] туда-обратно.
///
/// Позиция считается функцией от времени, а не интегрируется по кадрам,
/// поэтому повтор попытки даёт ровно ту же траекторию, а разная частота
/// кадров не рассинхронизирует ловушки.
class MazeMover {
  const MazeMover({
    required this.a,
    required this.b,
    required this.speed,
    required this.phase,
  });

  final GridPos a;
  final GridPos b;

  /// Клеток в секунду.
  final double speed;

  /// Сдвиг по фазе, чтобы препятствия не ходили строем.
  final double phase;

  /// Длина отрезка в клетках.
  double get length =>
      ((b.col - a.col).abs() + (b.row - a.row).abs()).toDouble();

  /// Центр препятствия в координатах клеток (0..cols, 0..rows)
  /// на момент [time] секунд от старта попытки.
  ({double col, double row}) positionAt(double time) {
    final double len = length;
    if (len <= 0) return (col: a.col + 0.5, row: a.row + 0.5);

    final double period = len * 2;
    double p = (phase + time * speed) % period;
    if (p < 0) p += period;
    if (p > len) p = period - p;

    final double t = p / len;
    return (
      col: a.col + (b.col - a.col) * t + 0.5,
      row: a.row + (b.row - a.row) * t + 0.5,
    );
  }
}

/// Готовая карта босс-лабиринта.
///
/// Создаётся генератором и после этого не меняется: попытка сбрасывает
/// только позицию самолёта и таймер, но не саму карту.
class MazeSpec {
  const MazeSpec({
    required this.cols,
    required this.rows,
    required this.tiles,
    required this.start,
    required this.finish,
    required this.traps,
    required this.movers,
    required this.timeLimit,
    required this.solutionLength,
  });

  final int cols;
  final int rows;

  /// Плоский массив длиной cols * rows - тем же приёмом, что и LevelData.
  final List<MazeTile> tiles;

  final GridPos start;
  final GridPos finish;

  /// Статичные ловушки. Лежат только вне гарантированного пути,
  /// поэтому лабиринт остаётся проходимым.
  final List<GridPos> traps;

  final List<MazeMover> movers;

  /// Сколько секунд даётся на попытку.
  final int timeLimit;

  /// Длина кратчайшего пути в клетках - для награды и для отладки.
  final int solutionLength;

  int indexOf(int col, int row) => row * cols + col;

  bool inside(int col, int row) =>
      col >= 0 && col < cols && row >= 0 && row < rows;

  MazeTile tileAt(int col, int row) =>
      inside(col, row) ? tiles[row * cols + col] : MazeTile.wall;

  /// Клетка непроходима: за границей поля, стена или закрытая зона.
  bool isBlocked(int col, int row) => !tileAt(col, row).isWalkable;

  bool isTrap(int col, int row) {
    for (final GridPos t in traps) {
      if (t.col == col && t.row == row) return true;
    }
    return false;
  }

  /// Расстояние от точки до ближайшей ловушки в клетках -
  /// используется столкновениями.
  double trapDistance(double col, double row) {
    double best = double.infinity;
    for (final GridPos t in traps) {
      final double dx = col - (t.col + 0.5);
      final double dy = row - (t.row + 0.5);
      final double d = math.sqrt(dx * dx + dy * dy);
      if (d < best) best = d;
    }
    return best;
  }
}
