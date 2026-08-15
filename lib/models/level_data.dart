import 'dart:math' as math;

/// Типы клеток карты. Проходима только рулёжная дорожка.
enum TileType { taxiway, grass, building, hangar, tower, terminal }

extension TileTypeX on TileType {
  bool get isWalkable => this == TileType.taxiway;

  bool get isObstacle => this != TileType.taxiway;
}

/// Координата клетки поля.
class GridPos {
  const GridPos(this.col, this.row);

  final int col;
  final int row;

  bool isAdjacentTo(GridPos other) =>
      (col - other.col).abs() + (row - other.row).abs() == 1;

  GridPos step(int dc, int dr) => GridPos(col + dc, row + dr);

  @override
  bool operator ==(Object other) =>
      other is GridPos && other.col == col && other.row == row;

  @override
  int get hashCode => col * 997 + row;

  @override
  String toString() => '$col:$row';

  static GridPos parse(String raw) {
    final List<String> parts = raw.split(':');
    return GridPos(int.parse(parts[0]), int.parse(parts[1]));
  }
}

/// Описание одного самолёта: где стоит, куда летит и эталонный маршрут.
/// Эталон используется подсказкой и гарантирует, что уровень решаем.
class PlaneSpec {
  const PlaneSpec({
    required this.id,
    required this.colorIndex,
    required this.solution,
  });

  final int id;
  final int colorIndex;
  final List<GridPos> solution;

  GridPos get start => solution.first;

  GridPos get gate => solution.last;

  /// Угол носа на старте: 0 - вверх, дальше по часовой стрелке.
  double get startAngle {
    if (solution.length < 2) return 0;
    final int dx = solution[1].col - solution[0].col;
    final int dy = solution[1].row - solution[0].row;
    return math.atan2(dx.toDouble(), -dy.toDouble());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'color': colorIndex,
        'path': solution.map((GridPos p) => p.toString()).toList(),
      };

  factory PlaneSpec.fromJson(Map<String, dynamic> json) => PlaneSpec(
        id: json['id'] as int,
        colorIndex: json['color'] as int,
        solution: (json['path'] as List<dynamic>)
            .map((dynamic e) => GridPos.parse(e as String))
            .toList(),
      );
}

/// Готовая карта уровня.
class LevelData {
  const LevelData({
    required this.id,
    required this.cols,
    required this.rows,
    required this.tiles,
    required this.planes,
    required this.parMoves,
    required this.parSeconds,
  });

  final int id;
  final int cols;
  final int rows;

  /// Плоский массив длиной cols * rows.
  final List<TileType> tiles;
  final List<PlaneSpec> planes;

  /// Эталон для трёх звёзд.
  final int parMoves;
  final int parSeconds;

  int get planeCount => planes.length;

  int indexOf(int col, int row) => row * cols + col;

  bool inside(GridPos p) =>
      p.col >= 0 && p.col < cols && p.row >= 0 && p.row < rows;

  TileType tileAt(int col, int row) => tiles[indexOf(col, row)];

  bool isWalkable(GridPos p) => inside(p) && tiles[indexOf(p.col, p.row)].isWalkable;

  PlaneSpec? planeStartingAt(GridPos p) {
    for (final PlaneSpec spec in planes) {
      if (spec.start == p) return spec;
    }
    return null;
  }

  PlaneSpec? planeGateAt(GridPos p) {
    for (final PlaneSpec spec in planes) {
      if (spec.gate == p) return spec;
    }
    return null;
  }

  PlaneSpec planeById(int id) =>
      planes.firstWhere((PlaneSpec spec) => spec.id == id);

  /// Чужая стоянка или чужой старт - в такую клетку маршрут не заходит.
  bool isEndpointOfOther(GridPos p, int planeId) {
    for (final PlaneSpec spec in planes) {
      if (spec.id == planeId) continue;
      if (spec.start == p || spec.gate == p) return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'cols': cols,
        'rows': rows,
        'tiles': tiles.map((TileType t) => t.index).toList(),
        'planes': planes.map((PlaneSpec p) => p.toJson()).toList(),
        'parMoves': parMoves,
        'parSeconds': parSeconds,
      };

  factory LevelData.fromJson(Map<String, dynamic> json) => LevelData(
        id: json['id'] as int,
        cols: json['cols'] as int,
        rows: json['rows'] as int,
        tiles: (json['tiles'] as List<dynamic>)
            .map((dynamic e) => TileType.values[e as int])
            .toList(),
        planes: (json['planes'] as List<dynamic>)
            .map((dynamic e) => PlaneSpec.fromJson(e as Map<String, dynamic>))
            .toList(),
        parMoves: json['parMoves'] as int,
        parSeconds: json['parSeconds'] as int,
      );
}
