/// Итог пройденного уровня - то, что показывает экран победы
/// и что уходит в сохранение.
class LevelResult {
  const LevelResult({
    required this.levelId,
    required this.stars,
    required this.moves,
    required this.seconds,
    required this.coins,
    required this.isNewBest,
    required this.usedHint,
    required this.perfect,
  });

  final int levelId;
  final int stars;
  final int moves;
  final int seconds;
  final int coins;
  final bool isNewBest;
  final bool usedHint;

  /// Perfect Run: ни одной ошибки при рисовании, ни одной отмены,
  /// подсказка не использовалась.
  final bool perfect;

  String get formattedTime {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
