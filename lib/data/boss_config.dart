/// Правила босс-лабиринта в одном месте: где он появляется, сколько
/// даётся попыток, как долго длится блокировка и сколько платит победа.
///
/// Обычные уровни этот файл не трогает - он только описывает надстройку.
class BossConfig {
  const BossConfig._();

  /// Босс встаёт на место каждого десятого уровня: 10, 20, 30, 40, 50...
  static const int every = 10;

  /// Попыток на заход. Ровно три, всегда.
  static const int attempts = 3;

  /// Блокировка после трёх поражений - ровно минута.
  static const int lockSeconds = 60;

  static bool isBoss(int levelId) => levelId > 0 && levelId % every == 0;

  /// Порядковый номер босса: 1 для уровня 10, 2 для 20 и так далее.
  static int indexOf(int levelId) => levelId ~/ every;

  /// Базовая награда за первое прохождение. Обычный уровень платит
  /// около сотни монет - босс сознательно даёт кратно больше.
  static int baseReward(int index) => 450 + 120 * (index - 1);

  /// Бонус за оставшееся время: секунда запаса стоит четыре монеты.
  static int timeBonus(int secondsLeft) => secondsLeft * 4;

  /// Бонус за неизрасходованные попытки.
  static int attemptsBonus(int attemptsLeft) => attemptsLeft * 60;

  /// Повторное прохождение уже пройденного босса. Заметно скромнее
  /// первой награды: босс остаётся событием, а не фермой монет.
  static int replayReward(int index) => 60 + 10 * index;

  /// Полная награда за победу.
  static int totalReward({
    required int index,
    required int secondsLeft,
    required int attemptsLeft,
    required bool firstClear,
  }) {
    if (!firstClear) return replayReward(index);
    return baseReward(index) +
        timeBonus(secondsLeft) +
        attemptsBonus(attemptsLeft);
  }
}
