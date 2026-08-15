import 'dart:math';

import '../models/level_data.dart';

/// Параметры сложности одной группы уровней.
class _Difficulty {
  const _Difficulty({
    required this.cols,
    required this.rows,
    required this.planes,
    required this.obstacles,
    required this.minPath,
    required this.maxPath,
    required this.fill,
  });

  final int cols;
  final int rows;
  final int planes;
  final int obstacles;
  final int minPath;
  final int maxPath;

  /// Доля лишних свободных клеток, которая уходит под застройку
  /// после прокладки маршрутов. Это главный рычаг сложности:
  /// чем меньше остаётся пустого места, тем меньше альтернативных
  /// решений и тем точнее приходится думать.
  final double fill;
}

/// Детерминированный генератор карт.
///
/// Ключевая идея: сначала прокладываются сами маршруты (самонепересекающимся
/// блужданием), и только потом их концы становятся самолётом и стоянкой.
/// Значит, у каждого уровня заведомо есть решение - то самое, по которому
/// он и был построен. Оно же используется подсказкой.
///
/// Seed зависит только от номера уровня, поэтому карта одинаковая
/// на всех устройствах и между запусками.
class LevelGenerator {
  const LevelGenerator._();

  static LevelData generate(int levelId) {
    for (int attempt = 0; attempt < 14; attempt++) {
      final LevelData? level = _tryGenerate(levelId, attempt);
      if (level != null) return level;
    }
    return _fallback(levelId);
  }

  // --------------------------------------------------------------- сложность

  static _Difficulty _difficultyFor(int id) {
    // 1-5 - знакомство: просторно, много запасных клеток, ошибиться сложно.
    if (id <= 3) {
      return _Difficulty(
        cols: 5,
        rows: 7,
        planes: id <= 2 ? 1 : 2,
        obstacles: 2 + id,
        minPath: 4,
        maxPath: 8,
        fill: 0,
      );
    }
    if (id <= 5) {
      return const _Difficulty(
        cols: 6,
        rows: 8,
        planes: 2,
        obstacles: 4,
        minPath: 4,
        maxPath: 9,
        fill: 0.20,
      );
    }
    // С 6-го поле начинает поджиматься: свободного места всё меньше.
    if (id <= 10) {
      return _Difficulty(
        cols: 6,
        rows: 9,
        planes: 3,
        obstacles: 4 + (id - 6),
        minPath: 5,
        maxPath: 11,
        fill: 0.45,
      );
    }
    if (id <= 20) {
      return _Difficulty(
        cols: 7,
        rows: 10,
        planes: id <= 15 ? 3 : 4,
        obstacles: 6 + (id - 11) ~/ 2,
        minPath: 6,
        maxPath: 13,
        fill: 0.60,
      );
    }
    if (id <= 30) {
      return _Difficulty(
        cols: 7,
        rows: 11,
        planes: id <= 25 ? 4 : 5,
        obstacles: 6 + (id - 21) ~/ 2,
        minPath: 6,
        maxPath: 14,
        fill: 0.70,
      );
    }
    if (id <= 40) {
      return _Difficulty(
        cols: 8,
        rows: 12,
        planes: id <= 35 ? 5 : 6,
        obstacles: 7 + (id - 31) ~/ 2,
        minPath: 7,
        maxPath: 16,
        fill: 0.78,
      );
    }
    if (id <= 50) {
      return _Difficulty(
        cols: 8,
        rows: 13,
        planes: id <= 45 ? 6 : (id <= 48 ? 7 : 8),
        obstacles: 7 + (id - 41) ~/ 2,
        minPath: 7,
        maxPath: 17,
        fill: 0.85,
      );
    }
    // 51-60 - карта чуть шире, шестой-седьмой борт становится нормой.
    if (id <= 60) {
      return _Difficulty(
        cols: 9,
        rows: 13,
        planes: id <= 54 ? 7 : (id <= 57 ? 8 : 9),
        obstacles: 8 + (id - 51) ~/ 2,
        minPath: 7,
        maxPath: 18,
        fill: 0.85,
      );
    }
    // 61-80 - поле вытягивается по высоте, до 11 бортов разом.
    if (id <= 80) {
      return _Difficulty(
        cols: 9,
        rows: 14,
        planes: id <= 67 ? 9 : (id <= 74 ? 10 : 11),
        obstacles: 10 + (id - 61) ~/ 2,
        minPath: 8,
        maxPath: 19,
        fill: 0.88,
      );
    }
    // 81-100 - ещё один столбец, плотность застройки почти максимальная.
    if (id <= 100) {
      return _Difficulty(
        cols: 10,
        rows: 14,
        planes: id <= 90 ? 11 : 12,
        obstacles: 12 + (id - 81) ~/ 2,
        minPath: 8,
        maxPath: 20,
        fill: 0.90,
      );
    }
    // 101-125 - поле почти максимального размера, до 13 бортов.
    if (id <= 125) {
      return _Difficulty(
        cols: 10,
        rows: 15,
        planes: id <= 113 ? 12 : 13,
        obstacles: 14 + (id - 101) ~/ 3,
        minPath: 9,
        maxPath: 21,
        fill: 0.90,
      );
    }
    // 126-150 - финальный рубеж: самая большая карта, до 14 бортов.
    return _Difficulty(
      cols: 10,
      rows: 16,
      planes: id <= 140 ? 13 : 14,
      obstacles: 15 + (id - 126) ~/ 3,
      minPath: 9,
      maxPath: 22,
      fill: 0.92,
    );
  }

  // ------------------------------------------------------------- генерация

  static LevelData? _tryGenerate(int levelId, int attempt) {
    final _Difficulty d = _difficultyFor(levelId);
    final Random rnd = Random(levelId * 7919 + attempt * 131 + 17);

    // С каждой неудачей чуть упрощаем карту, чтобы гарантированно сойтись.
    final int obstacles = (d.obstacles - attempt * 2).clamp(0, d.cols * d.rows);
    final int planeCount = attempt >= 8 ? (d.planes - 1).clamp(1, 14) : d.planes;

    final List<TileType> tiles =
        List<TileType>.filled(d.cols * d.rows, TileType.taxiway);
    _placeObstacles(rnd, tiles, d.cols, d.rows, obstacles);

    final int freeCells = tiles.where((TileType t) => t.isWalkable).length;
    if (freeCells < planeCount * d.minPath + 4) return null;

    final List<List<GridPos>>? paths = _carvePaths(
      rnd,
      tiles,
      d.cols,
      d.rows,
      planeCount,
      d.minPath,
      d.maxPath,
    );
    if (paths == null) return null;

    _fillSpareCells(rnd, tiles, d, paths);

    final List<PlaneSpec> planes = <PlaneSpec>[
      for (int i = 0; i < paths.length; i++)
        PlaneSpec(id: i, colorIndex: i % 8, solution: paths[i]),
    ];

    // Эталон считается от реальной длины маршрутов, а не от числа бортов:
    // на плотной карте те же три самолёта требуют вдвое больше работы.
    int routeCells = 0;
    for (final List<GridPos> path in paths) {
      routeCells += path.length;
    }

    return LevelData(
      id: levelId,
      cols: d.cols,
      rows: d.rows,
      tiles: tiles,
      planes: planes,
      parMoves: planes.length + 1 + levelId ~/ 20,
      parSeconds: 10 + routeCells,
    );
  }

  /// Застройка пустот после прокладки. Решение уже зафиксировано,
  /// поэтому уровень остаётся проходимым - исчезают только обходные пути.
  static void _fillSpareCells(
    Random rnd,
    List<TileType> tiles,
    _Difficulty d,
    List<List<GridPos>> paths,
  ) {
    if (d.fill <= 0) return;

    final Set<int> claimed = <int>{};
    for (final List<GridPos> path in paths) {
      for (final GridPos p in path) {
        claimed.add(p.row * d.cols + p.col);
      }
    }

    final List<int> spare = <int>[];
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].isWalkable && !claimed.contains(i)) spare.add(i);
    }

    // Перемешиваем тем же генератором - карта остаётся детерминированной.
    for (int i = spare.length - 1; i > 0; i--) {
      final int j = rnd.nextInt(i + 1);
      final int tmp = spare[i];
      spare[i] = spare[j];
      spare[j] = tmp;
    }

    final int count = (spare.length * d.fill).round();
    for (int i = 0; i < count; i++) {
      tiles[spare[i]] = _fillerType(rnd);
    }
  }

  /// Для застройки берём спокойные типы: газон и невысокие постройки.
  /// Вышка одна на карту, её ставит только основной проход.
  static TileType _fillerType(Random rnd) {
    final double r = rnd.nextDouble();
    if (r < 0.52) return TileType.grass;
    if (r < 0.78) return TileType.building;
    if (r < 0.92) return TileType.hangar;
    return TileType.terminal;
  }

  /// Препятствия ставятся по одной клетке с проверкой связности:
  /// если блок разрезает аэродром на части - откатываем.
  static void _placeObstacles(
    Random rnd,
    List<TileType> tiles,
    int cols,
    int rows,
    int count,
  ) {
    int placed = 0;
    int guard = 0;
    bool towerPlaced = false;

    while (placed < count && guard++ < count * 25 + 60) {
      final int idx = rnd.nextInt(tiles.length);
      if (!tiles[idx].isWalkable) continue;

      TileType type = _obstacleType(rnd);
      if (type == TileType.tower) {
        if (towerPlaced) type = TileType.building;
      }

      tiles[idx] = type;
      if (!_isConnected(tiles, cols, rows)) {
        tiles[idx] = TileType.taxiway;
        continue;
      }
      if (type == TileType.tower) towerPlaced = true;
      placed++;

      // Иногда достраиваем соседнюю клетку - получаются здания 1x2.
      if (placed < count && rnd.nextDouble() < 0.35) {
        final int col = idx % cols;
        final int row = idx ~/ cols;
        final List<int> options = <int>[];
        if (col + 1 < cols) options.add(idx + 1);
        if (row + 1 < rows) options.add(idx + cols);
        if (options.isNotEmpty) {
          final int next = options[rnd.nextInt(options.length)];
          if (tiles[next].isWalkable) {
            tiles[next] = type == TileType.tower ? TileType.building : type;
            if (!_isConnected(tiles, cols, rows)) {
              tiles[next] = TileType.taxiway;
            } else {
              placed++;
            }
          }
        }
      }
    }
  }

  static TileType _obstacleType(Random rnd) {
    final double r = rnd.nextDouble();
    if (r < 0.34) return TileType.building;
    if (r < 0.58) return TileType.grass;
    if (r < 0.80) return TileType.hangar;
    if (r < 0.94) return TileType.terminal;
    return TileType.tower;
  }

  /// Все проходимые клетки должны оставаться одной связной областью.
  static bool _isConnected(List<TileType> tiles, int cols, int rows) {
    int start = -1;
    int total = 0;
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].isWalkable) {
        total++;
        if (start < 0) start = i;
      }
    }
    if (total == 0) return false;

    final List<bool> seen = List<bool>.filled(tiles.length, false);
    final List<int> stack = <int>[start];
    seen[start] = true;
    int reached = 0;

    while (stack.isNotEmpty) {
      final int cur = stack.removeLast();
      reached++;
      final int col = cur % cols;
      final int row = cur ~/ cols;
      if (col > 0) _visit(cur - 1, tiles, seen, stack);
      if (col + 1 < cols) _visit(cur + 1, tiles, seen, stack);
      if (row > 0) _visit(cur - cols, tiles, seen, stack);
      if (row + 1 < rows) _visit(cur + cols, tiles, seen, stack);
    }
    return reached == total;
  }

  static void _visit(
    int idx,
    List<TileType> tiles,
    List<bool> seen,
    List<int> stack,
  ) {
    if (seen[idx] || !tiles[idx].isWalkable) return;
    seen[idx] = true;
    stack.add(idx);
  }

  static List<List<GridPos>>? _carvePaths(
    Random rnd,
    List<TileType> tiles,
    int cols,
    int rows,
    int planeCount,
    int minLen,
    int maxLen,
  ) {
    final Set<int> claimed = <int>{};
    final List<List<GridPos>> result = <List<GridPos>>[];

    for (int p = 0; p < planeCount; p++) {
      List<GridPos>? best;
      for (int attempt = 0; attempt < 90 && best == null; attempt++) {
        best = _walk(rnd, tiles, cols, rows, claimed, minLen, maxLen);
      }
      if (best == null) return null;
      for (final GridPos pos in best) {
        claimed.add(pos.row * cols + pos.col);
      }
      result.add(best);
    }
    return result;
  }

  /// Самонепересекающееся блуждание. Дополнительно запрещаем вставать
  /// рядом с собственным хвостом - иначе у маршрута появляются «срезы»
  /// и подсказка выглядит нелогично.
  static List<GridPos>? _walk(
    Random rnd,
    List<TileType> tiles,
    int cols,
    int rows,
    Set<int> claimed,
    int minLen,
    int maxLen,
  ) {
    final List<int> starts = <int>[];
    for (int i = 0; i < tiles.length; i++) {
      if (tiles[i].isWalkable && !claimed.contains(i)) starts.add(i);
    }
    if (starts.isEmpty) return null;

    final int target = minLen + rnd.nextInt(maxLen - minLen + 1);
    final int first = starts[rnd.nextInt(starts.length)];
    final List<int> path = <int>[first];
    final Set<int> inPath = <int>{first};

    while (path.length < target) {
      final int cur = path.last;
      final List<int> candidates = <int>[];

      for (final int nb in _neighbors(cur, cols, rows)) {
        if (!tiles[nb].isWalkable) continue;
        if (claimed.contains(nb) || inPath.contains(nb)) continue;
        int touching = 0;
        for (final int nn in _neighbors(nb, cols, rows)) {
          if (inPath.contains(nn)) touching++;
        }
        if (touching > 1) continue;
        candidates.add(nb);
      }

      if (candidates.isEmpty) break;
      final int next = candidates[rnd.nextInt(candidates.length)];
      path.add(next);
      inPath.add(next);
    }

    if (path.length < minLen) return null;
    return path
        .map((int i) => GridPos(i % cols, i ~/ cols))
        .toList(growable: false);
  }

  static List<int> _neighbors(int idx, int cols, int rows) {
    final int col = idx % cols;
    final int row = idx ~/ cols;
    final List<int> out = <int>[];
    if (col > 0) out.add(idx - 1);
    if (col + 1 < cols) out.add(idx + 1);
    if (row > 0) out.add(idx - cols);
    if (row + 1 < rows) out.add(idx + cols);
    return out;
  }

  /// Аварийный уровень: прямые горизонтальные маршруты без препятствий.
  /// Нужен только чтобы игра никогда не осталась без карты.
  static LevelData _fallback(int levelId) {
    const int cols = 6;
    const int rows = 8;
    final List<TileType> tiles =
        List<TileType>.filled(cols * rows, TileType.taxiway);
    final int planeCount = levelId <= 5 ? 2 : (levelId <= 100 ? 3 : 4);

    final List<PlaneSpec> planes = <PlaneSpec>[
      for (int i = 0; i < planeCount; i++)
        PlaneSpec(
          id: i,
          colorIndex: i % 8,
          solution: <GridPos>[
            for (int c = 0; c < cols; c++) GridPos(c, 1 + i * 2),
          ],
        ),
    ];

    return LevelData(
      id: levelId,
      cols: cols,
      rows: rows,
      tiles: tiles,
      planes: planes,
      parMoves: planeCount + 1,
      parSeconds: 12 + planeCount * 9,
    );
  }
}