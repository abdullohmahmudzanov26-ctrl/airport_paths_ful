import '../../models/level_data.dart';

/// Звёзды и награда за уровень.
///
/// Раньше звёзды за время сравнивались с LevelData.parSeconds, который
/// растёт вместе с длиной маршрутов и на поздних уровнях доходил до
/// трёх с лишним минут - при жёстком лимите в те же полторы минуты
/// уложиться в такой эталон было невозможно НЕ уложиться. Звезда за
/// время выдавалась всегда, и вся система оценки держалась на одном
/// счётчике ходов.
///
/// Теперь время сравнивается с тем же лимитом, который игрок видит
/// в HUD (LevelTiming.forLevel): три звезды - решить меньше чем за
/// [threeStarFraction] лимита, две - меньше чем за [twoStarFraction].
/// Одна и та же шкала на всех двухстах уровнях, и обратная связь
/// честная: полоска таймера прямо показывает, на какую оценку идёшь.
class ScoringSystem {
  const ScoringSystem._();

  /// Доля лимита, в которую надо уложиться на три звезды.
  static const double threeStarFraction = 0.55;

  /// То же для двух звёзд.
  static const double twoStarFraction = 0.80;

  /// Прибавка к награде за Perfect Run: без ошибок, отмен и подсказок.
  static const int perfectRunBonus = 25;

  static int stars({
    required LevelData level,
    required int moves,
    required int seconds,
    required int timeLimitSeconds,
  }) {
    // Страховка: лимит всегда положительный, но если сюда когда-нибудь
    // придёт ноль, оценка не должна делиться на него.
    final int limit =
        timeLimitSeconds > 0 ? timeLimitSeconds : level.parSeconds;
    if (limit <= 0) return 1;

    final double used = seconds / limit;
    final bool movesClean = moves <= level.parMoves;
    final bool movesFair = moves <= level.parMoves + level.planeCount;

    if (used <= threeStarFraction && movesClean) return 3;
    if (used <= twoStarFraction && movesFair) return 2;
    return 1;
  }

  /// Монеты за первое прохождение. Perfect Run платит сверху -
  /// иначе идеальный забег ничем не отличался бы от обычного.
  static int coins({
    required int stars,
    required int levelId,
    bool perfect = false,
  }) {
    final int base = 40 + stars * 20 + (levelId ~/ 10) * 5;
    return perfect ? base + perfectRunBonus : base;
  }
}
