import 'dart:math' as math;

import '../models/level_data.dart' show GridPos;
import '../models/maze_data.dart';

/// Настройки сложности одного босса. Считаются от номера босса
/// (10-й уровень - первый, 20-й - второй и так далее), поэтому
/// таблицу не нужно вести руками до бесконечности.
class MazeDifficulty {
  const MazeDifficulty({
    required this.index,
    required this.cols,
    required this.rows,
    required this.extraOpenings,
    required this.traps,
    required this.closedZones,
    required this.movers,
    required this.moverSpeed,
  });

  /// Порядковый номер босса: 1 для уровня 10, 2 для 20 и так далее.
  final int index;

  final int cols;
  final int rows;

  /// Сколько лишних стен сносится после генерации: из идеального
  /// дерева получаются развилки, петли и обходные пути.
  final int extraOpenings;

  final int traps;
  final int closedZones;
  final int movers;
  final double moverSpeed;

  static MazeDifficulty forIndex(int index) {
    final int i = index < 1 ? 1 : index;
    return MazeDifficulty(
      index: i,
      cols: _odd(math.min(19, 9 + 2 * i)),
      rows: _odd(math.min(25, 13 + 2 * i)),
      extraOpenings: 2 + 2 * i,
      traps: math.min(18, 2 * i),
      closedZones: math.min(6, i),
      movers: math.min(7, i),
      moverSpeed: math.min(2.6, 1.0 + 0.16 * i),
    );
  }

  /// Сетка обязана быть нечётной: иначе у лабиринта пропадает
  /// внешняя стена с одной из сторон.
  static int _odd(int value) => value.isEven ? value + 1 : value;
}

/// Генератор босс-лабиринтов.
///
/// Карта строится случайной, но не «как повезёт»: сначала прокапывается
/// связный лабиринт, затем из него берётся гарантированный путь
/// старт-финиш, и уже вокруг этого пути расставляются ловушки, закрытые
/// зоны и движущиеся препятствия. Ни один из них не встаёт на
/// сохранённый путь, поэтому карта всегда проходима.
///
/// Дополнительно результат проверяется поиском в ширину: если проверка
/// вдруг не прошла, карта строится заново с другим зерном.
class MazeGenerator {
  const MazeGenerator._();

  /// Скорость самолёта в клетках в секунду - из неё считается
  /// честный лимит времени. Должна совпадать с MazePlaneComponent.
  static const double planeSpeed = 3.2;

  static const int _maxRebuilds = 12;

  static MazeSpec generate({required int bossIndex, int? seed}) {
    final MazeDifficulty d = MazeDifficulty.forIndex(bossIndex);
    final int baseSeed = seed ?? DateTime.now().microsecondsSinceEpoch;

    MazeSpec? fallback;
    for (int attempt = 0; attempt < _maxRebuilds; attempt++) {
      final MazeSpec spec = _build(d, baseSeed + attempt * 7919);
      if (_isSolvable(spec)) return spec;
      fallback ??= spec;
    }

    // Досюда дойти не должно: путь резервируется до расстановки ловушек.
    // Но если это случилось - отдаём карту без ловушек, а не тупик.
    final MazeSpec safe = fallback!;
    return MazeSpec(
      cols: safe.cols,
      rows: safe.rows,
      tiles: safe.tiles,
      start: safe.start,
      finish: safe.finish,
      traps: const <GridPos>[],
      movers: safe.movers,
      timeLimit: safe.timeLimit,
      solutionLength: safe.solutionLength,
    );
  }

  // ------------------------------------------------------------ построение

  static MazeSpec _build(MazeDifficulty d, int seed) {
    final math.Random rnd = math.Random(seed);
    final int cols = d.cols;
    final int rows = d.rows;
    final List<MazeTile> tiles =
        List<MazeTile>.filled(cols * rows, MazeTile.wall);

    int at(int c, int r) => r * cols + c;
    bool isFloor(int c, int r) =>
        c >= 0 && c < cols && r >= 0 && r < rows && tiles[at(c, r)] == MazeTile.floor;

    // 1. Прокапываем идеальный лабиринт поиском в глубину по нечётным
    //    клеткам. Тупики и повороты получаются сами собой.
    tiles[at(1, 1)] = MazeTile.floor;
    final List<int> stack = <int>[at(1, 1)];
    final List<List<int>> steps = <List<int>>[
      <int>[2, 0],
      <int>[-2, 0],
      <int>[0, 2],
      <int>[0, -2],
    ];

    while (stack.isNotEmpty) {
      final int cur = stack.last;
      final int c = cur % cols;
      final int r = cur ~/ cols;
      steps.shuffle(rnd);

      bool moved = false;
      for (final List<int> s in steps) {
        final int nc = c + s[0];
        final int nr = r + s[1];
        if (nc < 1 || nc >= cols - 1 || nr < 1 || nr >= rows - 1) continue;
        if (tiles[at(nc, nr)] != MazeTile.wall) continue;
        tiles[at(nc, nr)] = MazeTile.floor;
        tiles[at(c + s[0] ~/ 2, r + s[1] ~/ 2)] = MazeTile.floor;
        stack.add(at(nc, nr));
        moved = true;
        break;
      }
      if (!moved) stack.removeLast();
    }

    // 2. Сносим часть внутренних стен: появляются развилки и петли,
    //    иначе лабиринт был бы деревом с единственным решением.
    final List<int> openable = <int>[];
    for (int r = 1; r < rows - 1; r++) {
      for (int c = 1; c < cols - 1; c++) {
        if (tiles[at(c, r)] != MazeTile.wall) continue;
        final bool horizontal = isFloor(c - 1, r) && isFloor(c + 1, r);
        final bool vertical = isFloor(c, r - 1) && isFloor(c, r + 1);
        if (horizontal != vertical) openable.add(at(c, r));
      }
    }
    openable.shuffle(rnd);
    final int openings = math.min(d.extraOpenings, openable.length);
    for (int i = 0; i < openings; i++) {
      tiles[openable[i]] = MazeTile.floor;
    }

    // 3. Старт в углу, финиш - самая дальняя клетка от него.
    const int startIndexCol = 1;
    const int startIndexRow = 1;
    final int startIdx = at(startIndexCol, startIndexRow);
    final _Search search = _bfs(tiles, cols, rows, startIdx, const <int>{});

    int finishIdx = startIdx;
    int bestDist = -1;
    for (int i = 0; i < search.dist.length; i++) {
      if (search.dist[i] > bestDist) {
        bestDist = search.dist[i];
        finishIdx = i;
      }
    }

    // 4. Кратчайший путь до финиша резервируется целиком: ни ловушка,
    //    ни закрытая зона на него не встанут.
    final List<int> path = <int>[];
    int walk = finishIdx;
    while (walk != startIdx) {
      path.add(walk);
      walk = search.prev[walk];
      if (walk < 0) break;
    }
    path.add(startIdx);
    final Set<int> reserved = path.toSet();

    // 5. Кандидаты под ловушки и закрытые зоны: свободные клетки вне
    //    резерва и не в двух шагах от старта - игрок должен успеть
    //    осмотреться, а не влететь в ловушку на первом кадре.
    final List<int> candidates = <int>[];
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i] != MazeTile.floor) continue;
      if (reserved.contains(i)) continue;
      final int c = i % cols;
      final int r = i ~/ cols;
      if ((c - startIndexCol).abs() + (r - startIndexRow).abs() <= 2) continue;
      candidates.add(i);
    }
    candidates.shuffle(rnd);

    int openNeighbours(int c, int r) {
      int n = 0;
      if (isFloor(c + 1, r)) n++;
      if (isFloor(c - 1, r)) n++;
      if (isFloor(c, r + 1)) n++;
      if (isFloor(c, r - 1)) n++;
      return n;
    }

    // 6. Закрытые зоны занимают тупики - так они читаются как
    //    «сюда нельзя», а не как обычный кусок стены посреди коридора.
    int closedLeft = d.closedZones;
    for (int i = 0; i < candidates.length && closedLeft > 0; i++) {
      final int idx = candidates[i];
      final int c = idx % cols;
      final int r = idx ~/ cols;
      if (openNeighbours(c, r) != 1) continue;
      tiles[idx] = MazeTile.closed;
      closedLeft--;
    }

    // 7. Ловушки - на оставшихся свободных кандидатах.
    final List<GridPos> traps = <GridPos>[];
    for (int i = 0; i < candidates.length && traps.length < d.traps; i++) {
      final int idx = candidates[i];
      if (tiles[idx] != MazeTile.floor) continue;
      traps.add(GridPos(idx % cols, idx ~/ cols));
    }
    final Set<int> trapIdx =
        traps.map((GridPos p) => at(p.col, p.row)).toSet();

    // 8. Движущиеся препятствия ходят по прямым коридорам длиной от трёх
    //    клеток, и только по тем, где есть развилка: в глухом коридоре
    //    встречный патруль был бы нечестной стеной.
    final List<MazeMover> movers =
        _placeMovers(tiles, cols, rows, d, rnd, trapIdx, startIdx, finishIdx);

    final int pathLength = path.length;
    return MazeSpec(
      cols: cols,
      rows: rows,
      tiles: tiles,
      start: GridPos(startIndexCol, startIndexRow),
      finish: GridPos(finishIdx % cols, finishIdx ~/ cols),
      traps: traps,
      movers: movers,
      timeLimit: _timeLimit(d, pathLength, cols, rows),
      solutionLength: pathLength,
    );
  }

  static List<MazeMover> _placeMovers(
    List<MazeTile> tiles,
    int cols,
    int rows,
    MazeDifficulty d,
    math.Random rnd,
    Set<int> trapIdx,
    int startIdx,
    int finishIdx,
  ) {
    int at(int c, int r) => r * cols + c;
    bool isFloor(int c, int r) =>
        c >= 0 && c < cols && r >= 0 && r < rows && tiles[at(c, r)] == MazeTile.floor;

    int openNeighbours(int c, int r) {
      int n = 0;
      if (isFloor(c + 1, r)) n++;
      if (isFloor(c - 1, r)) n++;
      if (isFloor(c, r + 1)) n++;
      if (isFloor(c, r - 1)) n++;
      return n;
    }

    final List<List<int>> runs = <List<int>>[];

    for (int r = 0; r < rows; r++) {
      int c = 0;
      while (c < cols) {
        if (isFloor(c, r)) {
          int c2 = c;
          while (c2 + 1 < cols && isFloor(c2 + 1, r)) {
            c2++;
          }
          if (c2 - c + 1 >= 3) runs.add(<int>[c, r, c2, r]);
          c = c2 + 1;
        } else {
          c++;
        }
      }
    }
    for (int c = 0; c < cols; c++) {
      int r = 0;
      while (r < rows) {
        if (isFloor(c, r)) {
          int r2 = r;
          while (r2 + 1 < rows && isFloor(c, r2 + 1)) {
            r2++;
          }
          if (r2 - r + 1 >= 3) runs.add(<int>[c, r, c, r2]);
          r = r2 + 1;
        } else {
          r++;
        }
      }
    }
    runs.shuffle(rnd);

    final Set<int> used = <int>{};
    final List<MazeMover> movers = <MazeMover>[];

    for (final List<int> run in runs) {
      if (movers.length >= d.movers) break;

      final List<int> cells = <int>[];
      if (run[1] == run[3]) {
        for (int c = run[0]; c <= run[2]; c++) {
          cells.add(at(c, run[1]));
        }
      } else {
        for (int r = run[1]; r <= run[3]; r++) {
          cells.add(at(run[0], r));
        }
      }

      bool free = true;
      bool hasJunction = false;
      for (final int idx in cells) {
        if (used.contains(idx) ||
            trapIdx.contains(idx) ||
            idx == startIdx ||
            idx == finishIdx) {
          free = false;
          break;
        }
        if (openNeighbours(idx % cols, idx ~/ cols) >= 3) hasJunction = true;
      }
      if (!free || !hasJunction) continue;

      used.addAll(cells);
      movers.add(
        MazeMover(
          a: GridPos(run[0], run[1]),
          b: GridPos(run[2], run[3]),
          speed: d.moverSpeed * (0.85 + rnd.nextDouble() * 0.3),
          phase: rnd.nextDouble() * 6.0,
        ),
      );
    }

    return movers;
  }

  /// Лимит времени: длина честного пути плюс запас на осмотр карты.
  /// Чем дальше босс, тем меньше множитель - маршрут тот же, а времени
  /// на блуждание всё меньше.
  static int _timeLimit(MazeDifficulty d, int pathLength, int cols, int rows) {
    final double factor = math.max(2.1, 3.2 - 0.1 * d.index);
    final double raw =
        10 + (cols * rows) / 45.0 + pathLength / planeSpeed * factor;
    return raw.round().clamp(40, 150);
  }

  // -------------------------------------------------------------- проверка

  /// Есть ли путь от старта до финиша по свободным клеткам,
  /// не наступая на ловушки.
  static bool _isSolvable(MazeSpec spec) {
    final Set<int> blocked = spec.traps
        .map((GridPos p) => p.row * spec.cols + p.col)
        .toSet();
    final _Search search = _bfs(
      spec.tiles,
      spec.cols,
      spec.rows,
      spec.start.row * spec.cols + spec.start.col,
      blocked,
    );
    return search.dist[spec.finish.row * spec.cols + spec.finish.col] >= 0;
  }

  static _Search _bfs(
    List<MazeTile> tiles,
    int cols,
    int rows,
    int from,
    Set<int> blocked,
  ) {
    final List<int> dist = List<int>.filled(cols * rows, -1);
    final List<int> prev = List<int>.filled(cols * rows, -1);
    final List<int> queue = <int>[from];
    dist[from] = 0;

    int head = 0;
    while (head < queue.length) {
      final int cur = queue[head++];
      final int c = cur % cols;
      final int r = cur ~/ cols;

      for (int dir = 0; dir < 4; dir++) {
        final int nc = c + (dir == 0 ? 1 : dir == 1 ? -1 : 0);
        final int nr = r + (dir == 2 ? 1 : dir == 3 ? -1 : 0);
        if (nc < 0 || nc >= cols || nr < 0 || nr >= rows) continue;

        final int idx = nr * cols + nc;
        if (dist[idx] >= 0) continue;
        if (tiles[idx] != MazeTile.floor) continue;
        if (blocked.contains(idx)) continue;

        dist[idx] = dist[cur] + 1;
        prev[idx] = cur;
        queue.add(idx);
      }
    }

    return _Search(dist, prev);
  }
}

class _Search {
  const _Search(this.dist, this.prev);

  final List<int> dist;
  final List<int> prev;
}
