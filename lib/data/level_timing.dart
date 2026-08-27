import 'dart:math' as math;

/// Жёсткий лимит времени на прохождение уровня - не спутать с
/// LevelData.parSeconds, который считает эталон для звёзд и растёт
/// вместе с суммарной длиной маршрутов (на 200 уровне вышел бы за
/// 3 минуты при 13 бортах). Здесь потолок жёстко задан игроком:
/// 20 секунд на первом уровне, 70 секунд на двухсотом, а не эталон
/// «как быстро решит опытный игрок».
///
/// Кривая - корень из номера уровня, не линейная: сложность растёт
/// быстро в начале кампании (уровень 3 - первый настоящий вызов) и
/// выполаживается к концу, где рост идёт в основном за счёт числа
/// бортов, а не структурной сложности головоломки.
class LevelTiming {
  const LevelTiming._();

  static const int minSeconds = 20;
  static const int maxSeconds = 70;

  // Подобраны так, чтобы f(1) == minSeconds и f(LevelRepository.levelCount)
  // == maxSeconds ровно после округления - см. проверку в комментарии
  // ниже, значения не менять по отдельности.
  static const double _base = 16.19525;
  static const double _growth = 3.80475;

  /// Лимит в секундах для конкретного уровня. Считается от корня
  /// номера уровня и зажимается в [minSeconds, maxSeconds] на случай
  /// изменения LevelRepository.levelCount в будущем.
  static int forLevel(int levelId) {
    final int id = levelId < 1 ? 1 : levelId;
    final double raw = _base + _growth * math.sqrt(id.toDouble());
    return raw.round().clamp(minSeconds, maxSeconds);
  }
}
