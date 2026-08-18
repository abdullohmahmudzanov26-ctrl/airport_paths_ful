import 'package:flutter/material.dart';

/// Достижение. Условие - чистая функция от статистики игрока,
/// поэтому проверка не зависит от того, где и когда её вызвали.
class Achievement {
  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.test,
  });

  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final bool Function(AchievementStats stats) test;
}

/// Срез прогресса, по которому считаются достижения.
class AchievementStats {
  const AchievementStats({
    required this.completedLevels,
    required this.totalStars,
    required this.perfectLevels,
    required this.coins,
    required this.hintFreePerfects,
    required this.perfectRuns,
  });

  final int completedLevels;
  final int totalStars;
  final int perfectLevels;
  final int coins;
  final int hintFreePerfects;

  /// Уровни, пройденные без единой ошибки, без отмены и без
  /// подсказки - Perfect Run. Отдельная метрика от perfectLevels
  /// (той нужны только 3 звезды, тут дисциплина прокладки маршрута).
  final int perfectRuns;
}
