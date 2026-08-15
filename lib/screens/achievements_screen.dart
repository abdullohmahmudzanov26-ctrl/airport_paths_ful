import 'package:flutter/material.dart';

import '../data/achievements_data.dart';
import '../data/app_strings.dart';
import '../models/achievement.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_panel.dart';
import '../widgets/screen_header.dart';
import '../widgets/stat_chip.dart';

/// Достижения. Закрытые не прячутся - видно, к чему стремиться.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Services.progress,
            builder: (BuildContext context, _) {
              final int unlocked =
                  Services.progress.unlockedAchievements.length;
              return Column(
                children: <Widget>[
                  ScreenHeader(title: tr('achievements')),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      StatChip(
                        icon: Icons.emoji_events_rounded,
                        value: '$unlocked / ${AchievementsCatalog.all.length}',
                      ),
                      const SizedBox(width: 12),
                      StatChip(
                        icon: Icons.monetization_on_rounded,
                        value: '${Services.progress.coins}',
                        iconColor: context.palette.coin,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: AchievementsCatalog.all.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Achievement a = AchievementsCatalog.all[i];
                        return AnimatedEntrance(
                          delay: Duration(milliseconds: 40 * i),
                          duration: const Duration(milliseconds: 320),
                          offset: const Offset(0, 0.18),
                          curve: Curves.easeOutCubic,
                          child: _AchievementCard(
                            achievement: a,
                            unlocked: Services.progress.hasAchievement(a.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: unlocked ? 1 : 0.62,
        child: AppPanel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: 16,
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: unlocked ? p.primary.gradient : null,
                  color: unlocked ? null : Colors.black.withOpacity(0.28),
                  border: Border.all(
                    color: unlocked
                        ? p.primary.border.withOpacity(0.6)
                        : p.panelBorder.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  unlocked ? achievement.icon : Icons.lock_rounded,
                  size: 22,
                  color: unlocked ? Colors.white : p.textMuted,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tr(achievement.titleKey),
                      style: AppText.label.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tr(achievement.descriptionKey),
                      style: AppText.caption.copyWith(
                        color: p.textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                Icon(Icons.check_circle_rounded, size: 22, color: p.success.top),
            ],
          ),
        ),
      ),
    );
  }
}
