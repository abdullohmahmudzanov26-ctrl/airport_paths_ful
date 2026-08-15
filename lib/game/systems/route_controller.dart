import '../../models/level_data.dart';

/// Все нарисованные маршруты и правила их прокладки.
///
/// Главное правило игры: две трассы не могут занимать одну клетку.
/// Это и есть защита от столкновений - если маршруты нигде не пересекаются,
/// самолёты физически не могут встретиться.
class RouteController {
  RouteController(this.level)
      : _owner = List<int>.filled(level.cols * level.rows, -1);

  final LevelData level;

  /// planeId -> цепочка клеток от самолёта к стоянке.
  final Map<int, List<GridPos>> routes = <int, List<GridPos>>{};

  /// Кто занимает клетку: индекс клетки -> planeId (или -1).
  final List<int> _owner;

  final List<Map<int, List<GridPos>>> _undoStack =
      <Map<int, List<GridPos>>>[];

  static const int _maxUndo = 40;

  int moves = 0;
  int? activePlane;

  /// Растёт при любом изменении трасс. Слой отрисовки по этому счётчику
  /// понимает, что путь пора пересобрать, и не строит Path каждый кадр.
  int revision = 0;

  int _idx(GridPos p) => p.row * level.cols + p.col;

  int? ownerAt(GridPos p) {
    if (!level.inside(p)) return null;
    final int id = _owner[_idx(p)];
    return id < 0 ? null : id;
  }

  List<GridPos> routeOf(int planeId) => routes[planeId] ?? const <GridPos>[];

  bool isComplete(int planeId) {
    final List<GridPos> route = routeOf(planeId);
    if (route.length < 2) return false;
    final PlaneSpec spec = level.planeById(planeId);
    return route.first == spec.start && route.last == spec.gate;
  }

  bool get allComplete {
    for (final PlaneSpec spec in level.planes) {
      if (!isComplete(spec.id)) return false;
    }
    return true;
  }

  int get completedCount {
    int n = 0;
    for (final PlaneSpec spec in level.planes) {
      if (isComplete(spec.id)) n++;
    }
    return n;
  }

  // ------------------------------------------------------------------ ввод

  /// Палец опустился на клетку.
  bool beginAt(GridPos p) {
    if (!level.inside(p)) return false;

    final PlaneSpec? plane = level.planeStartingAt(p);
    if (plane != null) {
      _pushUndo();
      _clearRoute(plane.id);
      routes[plane.id] = <GridPos>[p];
      _owner[_idx(p)] = plane.id;
      activePlane = plane.id;
      revision++;
      return true;
    }

    // Продолжаем существующий маршрут с той клетки, где нажали.
    final int? owner = ownerAt(p);
    if (owner != null) {
      _pushUndo();
      _truncateTo(owner, p);
      activePlane = owner;
      return true;
    }
    return false;
  }

  /// Палец переехал на клетку. Между быстрыми движениями клетки могут
  /// пропускаться, поэтому идём к цели по одной, шаг за шагом.
  bool dragTo(GridPos target) {
    final int? planeId = activePlane;
    if (planeId == null) return false;
    if (!level.inside(target)) return false;

    bool changed = false;
    for (int guard = 0; guard < 64; guard++) {
      final List<GridPos> route = routes[planeId]!;
      final GridPos last = route.last;
      if (last == target) return changed;

      final int dc = target.col - last.col;
      final int dr = target.row - last.row;
      GridPos next;
      if (dc.abs() >= dr.abs()) {
        next = last.step(dc > 0 ? 1 : -1, 0);
      } else {
        next = last.step(0, dr > 0 ? 1 : -1);
      }

      if (_extend(planeId, next)) {
        changed = true;
      } else {
        // Прямой путь упёрся - пробуем обойти по второй оси.
        final GridPos alt = dc.abs() >= dr.abs()
            ? last.step(0, dr > 0 ? 1 : (dr < 0 ? -1 : 0))
            : last.step(dc > 0 ? 1 : (dc < 0 ? -1 : 0), 0);
        if (alt == last || !_extend(planeId, alt)) return changed;
        changed = true;
      }
    }
    return changed;
  }

  bool get hasActiveRoute => activePlane != null;

  bool _extend(int planeId, GridPos next) {
    final List<GridPos> route = routes[planeId]!;
    final GridPos last = route.last;
    if (!last.isAdjacentTo(next)) return false;
    if (!level.inside(next)) return false;

    // Шаг назад по своему же следу - стираем хвост.
    if (route.length >= 2 && route[route.length - 2] == next) {
      final GridPos removed = route.removeLast();
      _owner[_idx(removed)] = -1;
      revision++;
      return true;
    }

    if (isComplete(planeId)) return false;
    if (!level.isWalkable(next)) return false;
    if (level.isEndpointOfOther(next, planeId)) return false;

    final int? owner = ownerAt(next);
    if (owner != null) return false; // клетка занята - пересечений не бывает

    route.add(next);
    _owner[_idx(next)] = planeId;
    revision++;
    return true;
  }

  /// Ход засчитывается здесь: просто ткнуть в самолёт и отпустить -
  /// это не ход, иначе счётчик рос бы от случайных касаний.
  void endDrawing() {
    final int? planeId = activePlane;
    if (planeId != null && routeOf(planeId).length > 1) moves++;
    activePlane = null;
  }

  // ------------------------------------------------------------ управление

  /// Подсказка: кладём эталонный маршрут, снося всё, что ему мешает.
  void applySolution(PlaneSpec spec) {
    _pushUndo();
    for (final GridPos p in spec.solution) {
      final int? owner = ownerAt(p);
      if (owner != null && owner != spec.id) _clearRoute(owner);
    }
    _clearRoute(spec.id);
    routes[spec.id] = List<GridPos>.from(spec.solution);
    for (final GridPos p in spec.solution) {
      _owner[_idx(p)] = spec.id;
    }
    moves++;
    revision++;
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final Map<int, List<GridPos>> snapshot = _undoStack.removeLast();
    routes
      ..clear()
      ..addAll(snapshot);
    _rebuildOwners();
    activePlane = null;
    revision++;
    if (moves > 0) moves--;
  }

  bool get canUndo => _undoStack.isNotEmpty;

  void clearAll() {
    routes.clear();
    _undoStack.clear();
    for (int i = 0; i < _owner.length; i++) {
      _owner[i] = -1;
    }
    activePlane = null;
    moves = 0;
    revision++;
  }

  // --------------------------------------------------------------- утилиты

  void _clearRoute(int planeId) {
    final List<GridPos>? route = routes.remove(planeId);
    if (route == null) return;
    for (final GridPos p in route) {
      if (_owner[_idx(p)] == planeId) _owner[_idx(p)] = -1;
    }
    revision++;
  }

  void _truncateTo(int planeId, GridPos p) {
    final List<GridPos>? route = routes[planeId];
    if (route == null) return;
    final int at = route.indexOf(p);
    if (at < 0) return;
    for (int i = at + 1; i < route.length; i++) {
      _owner[_idx(route[i])] = -1;
    }
    routes[planeId] = route.sublist(0, at + 1);
    revision++;
  }

  void _pushUndo() {
    _undoStack.add(<int, List<GridPos>>{
      for (final MapEntry<int, List<GridPos>> e in routes.entries)
        e.key: List<GridPos>.from(e.value),
    });
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
  }

  void _rebuildOwners() {
    for (int i = 0; i < _owner.length; i++) {
      _owner[i] = -1;
    }
    for (final MapEntry<int, List<GridPos>> e in routes.entries) {
      for (final GridPos p in e.value) {
        _owner[_idx(p)] = e.key;
      }
    }
  }
}
