import '../../models/level_data.dart';

/// Звёзды и награда за уровень.
class ScoringSystem {
  const ScoringSystem._();

  /// Три звезды - уложиться и в ходы, и во время.
  /// Две - выполнить хотя бы одно условие с запасом.
  static int stars({
    required LevelData level,
    required int moves,
    required int seconds,
  }) {
    if (moves <= level.parMoves && seconds <= level.parSeconds) return 3;
    if (moves <= level.parMoves + level.planeCount ||
        seconds <= level.parSeconds * 2) {
      return 2;
    }
    return 1;
  }

  static int coins({required int stars, required int levelId}) =>
      40 + stars * 20 + (levelId ~/ 10) * 5;
}
