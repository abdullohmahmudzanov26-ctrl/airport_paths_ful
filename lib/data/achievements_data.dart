import 'package:flutter/material.dart';

import '../models/achievement.dart';

/// Каталог достижений. Порядок = порядок вывода на экране.
class AchievementsCatalog {
  const AchievementsCatalog._();

  static const List<Achievement> all = <Achievement>[
    Achievement(
      id: 'first_flight',
      titleKey: 'ach_first_title',
      descriptionKey: 'ach_first_desc',
      icon: Icons.flight_takeoff_rounded,
      test: _firstFlight,
    ),
    Achievement(
      id: 'rookie',
      titleKey: 'ach_rookie_title',
      descriptionKey: 'ach_rookie_desc',
      icon: Icons.explore_rounded,
      test: _rookie,
    ),
    Achievement(
      id: 'dispatcher',
      titleKey: 'ach_dispatcher_title',
      descriptionKey: 'ach_dispatcher_desc',
      icon: Icons.radar_rounded,
      test: _dispatcher,
    ),
    Achievement(
      id: 'captain',
      titleKey: 'ach_captain_title',
      descriptionKey: 'ach_captain_desc',
      icon: Icons.military_tech_rounded,
      test: _captain,
    ),
    Achievement(
      id: 'ace',
      titleKey: 'ach_ace_title',
      descriptionKey: 'ach_ace_desc',
      icon: Icons.workspace_premium_rounded,
      test: _ace,
    ),
    Achievement(
      id: 'perfectionist',
      titleKey: 'ach_perfect_title',
      descriptionKey: 'ach_perfect_desc',
      icon: Icons.auto_awesome_rounded,
      test: _perfectionist,
    ),
    Achievement(
      id: 'star_collector',
      titleKey: 'ach_stars_title',
      descriptionKey: 'ach_stars_desc',
      icon: Icons.star_rounded,
      test: _starCollector,
    ),
    Achievement(
      id: 'self_made',
      titleKey: 'ach_nohint_title',
      descriptionKey: 'ach_nohint_desc',
      icon: Icons.psychology_rounded,
      test: _selfMade,
    ),
    Achievement(
      id: 'rich',
      titleKey: 'ach_rich_title',
      descriptionKey: 'ach_rich_desc',
      icon: Icons.savings_rounded,
      test: _rich,
    ),
    Achievement(
      id: 'flawless',
      titleKey: 'ach_flawless_title',
      descriptionKey: 'ach_flawless_desc',
      icon: Icons.verified_rounded,
      test: _flawless,
    ),
    Achievement(
      id: 'super_3',
      titleKey: 'ach_super3_title',
      descriptionKey: 'ach_super3_desc',
      icon: Icons.military_tech_rounded,
      test: _super3,
    ),
    Achievement(
      id: 'super_50',
      titleKey: 'ach_super50_title',
      descriptionKey: 'ach_super50_desc',
      icon: Icons.rocket_launch_rounded,
      test: _super50,
    ),
    Achievement(
      id: 'super_100',
      titleKey: 'ach_super100_title',
      descriptionKey: 'ach_super100_desc',
      icon: Icons.bolt_rounded,
      test: _super100,
    ),
    Achievement(
      id: 'super_150',
      titleKey: 'ach_super150_title',
      descriptionKey: 'ach_super150_desc',
      icon: Icons.diamond_rounded,
      test: _super150,
    ),
    Achievement(
      id: 'super_200',
      titleKey: 'ach_super200_title',
      descriptionKey: 'ach_super200_desc',
      icon: Icons.emoji_events_rounded,
      test: _super200,
    ),
  ];

  static Achievement? byId(String id) {
    for (final Achievement a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static bool _firstFlight(AchievementStats s) => s.completedLevels >= 1;

  static bool _rookie(AchievementStats s) => s.completedLevels >= 5;

  static bool _dispatcher(AchievementStats s) => s.completedLevels >= 15;

  static bool _captain(AchievementStats s) => s.completedLevels >= 60;

  static bool _ace(AchievementStats s) => s.completedLevels >= 200;

  static bool _perfectionist(AchievementStats s) => s.perfectLevels >= 10;

  static bool _starCollector(AchievementStats s) => s.totalStars >= 300;

  static bool _selfMade(AchievementStats s) => s.hintFreePerfects >= 10;

  static bool _rich(AchievementStats s) => s.coins >= 1000;

  static bool _flawless(AchievementStats s) => s.perfectRuns >= 5;

  static bool _super3(AchievementStats s) => s.completedLevels >= 3;
  static bool _super50(AchievementStats s) => s.completedLevels >= 50;
  static bool _super100(AchievementStats s) => s.completedLevels >= 100;
  static bool _super150(AchievementStats s) => s.completedLevels >= 150;
  static bool _super200(AchievementStats s) => s.completedLevels >= 200;
}
