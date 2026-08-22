/// Итог пройденного босс-лабиринта - то, что показывает экран победы.
///
/// Модель по образцу LevelResult: чистые данные без зависимостей от UI.
class BossResult {
  const BossResult({
    required this.levelId,
    required this.seconds,
    required this.secondsLeft,
    required this.attemptsLeft,
    required this.coins,
    required this.baseReward,
    required this.timeBonus,
    required this.attemptsBonus,
    required this.firstClear,
    required this.isNewBest,
  });

  final int levelId;

  /// Сколько заняло прохождение.
  final int seconds;

  /// Сколько секунд осталось на таймере - из них считается бонус.
  final int secondsLeft;

  final int attemptsLeft;

  /// Итого зачислено монет.
  final int coins;

  final int baseReward;
  final int timeBonus;
  final int attemptsBonus;

  /// Первое прохождение этого босса: только за него платится
  /// полная награда.
  final bool firstClear;

  final bool isNewBest;

  bool get hasBonus => timeBonus > 0 || attemptsBonus > 0;

  String get formattedTime {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
