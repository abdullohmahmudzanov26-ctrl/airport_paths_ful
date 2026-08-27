/// Одна из больших вех кампании.
class SuperMilestone {
  const SuperMilestone({
    required this.level,
    required this.coins,
    required this.phraseKey,
    required this.achievementId,
    this.skinId,
  });

  final int level;
  final int coins;
  final String phraseKey;
  final String achievementId;

  /// Борт, который выдаётся в собственность вместе с вехой (если есть).
  /// Пока используется только у самой первой вехи (уровень 3) - награда
  /// сразу после первого по-настоящему сложного уровня, чтобы усилие
  /// окупилось не «просто открылся уровень 4», а чем-то заметным.
  final String? skinId;
}

/// Награда привязана к достижению: как только оно первый раз
/// разблокируется в ProgressService, монеты (и борт, если он есть у
/// вехи) выдаются тут же. Второй раз разблокироваться достижению уже
/// не даст сама система достижений - отдельный флаг «награда выдана»
/// тут не нужен.
class SuperMilestones {
  const SuperMilestones._();

  static const List<SuperMilestone> all = <SuperMilestone>[
    SuperMilestone(
      level: 3,
      coins: 300,
      phraseKey: 'super_3',
      achievementId: 'super_3',
      skinId: 'underdog',
    ),
    SuperMilestone(
      level: 50,
      coins: 500,
      phraseKey: 'super_50',
      achievementId: 'super_50',
    ),
    SuperMilestone(
      level: 100,
      coins: 1000,
      phraseKey: 'super_100',
      achievementId: 'super_100',
    ),
    SuperMilestone(
      level: 150,
      coins: 1500,
      phraseKey: 'super_150',
      achievementId: 'super_150',
    ),
    SuperMilestone(
      level: 200,
      coins: 2000,
      phraseKey: 'super_200',
      achievementId: 'super_200',
    ),
  ];

  static SuperMilestone? byAchievementId(String id) {
    for (final SuperMilestone m in all) {
      if (m.achievementId == id) return m;
    }
    return null;
  }
}
