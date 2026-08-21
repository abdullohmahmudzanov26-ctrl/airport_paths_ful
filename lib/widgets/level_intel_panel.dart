import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/level_features.dart';
import '../game/airport_game.dart';
import '../game/dynamic_events.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'app_panel.dart';

/// Главное событие, активный динамический ивент и задание уровня -
/// одной компактной панелью, в существующем визуальном языке игры.
///
/// Слушает только game.events (ChangeNotifier), который уведомляет
/// редко - при появлении/исчезновении ивента и раз в ~200мс на
/// обратный отсчёт, а не 60 раз в секунду. Событие и задание сами по
/// себе статичны для уровня, лишних перестроений это не создаёт.
class LevelIntelPanel extends StatelessWidget {
  const LevelIntelPanel({super.key, required this.game});

  final AirportGame game;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool questDone = Services.progress.isQuestDone(game.level.id);

    return AnimatedBuilder(
      animation: game.events,
      builder: (BuildContext context, _) {
        final DynamicEvent? active = game.events.active;
        return AppPanel(
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(_featureIcon(game.feature.kind), size: 16, color: p.primary.top),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr(game.feature.titleKey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: p.textSecondary),
                    ),
                  ),
                  Icon(
                    questDone
                        ? Icons.check_circle_rounded
                        : Icons.flag_circle_rounded,
                    size: 16,
                    color: questDone ? p.success.top : p.coin,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      '${tr(game.quest.titleKey)}  +${game.quest.reward}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: questDone ? p.success.top : p.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              if (active != null) ...<Widget>[
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Icon(_eventIcon(active.kind), size: 15, color: p.danger.top),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tr(_eventKey(active.kind)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: p.danger.top,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static IconData _featureIcon(LevelFeatureKind kind) {
    switch (kind) {
      case LevelFeatureKind.calmSkies:
        return Icons.wb_sunny_rounded;
      case LevelFeatureKind.crosswind:
        return Icons.air_rounded;
      case LevelFeatureKind.nightOps:
        return Icons.nightlight_round;
      case LevelFeatureKind.fogAlert:
        return Icons.foggy;
      case LevelFeatureKind.noHintZone:
        return Icons.lightbulb_outline_rounded;
      case LevelFeatureKind.timeTrial:
        return Icons.timer_rounded;
      case LevelFeatureKind.vipTransfer:
        return Icons.star_rounded;
      case LevelFeatureKind.precisionRun:
        return Icons.gps_fixed_rounded;
      case LevelFeatureKind.rushHour:
        return Icons.traffic_rounded;
      case LevelFeatureKind.stormFront:
        return Icons.thunderstorm_rounded;
    }
  }

  static IconData _eventIcon(DynamicEventKind kind) {
    switch (kind) {
      case DynamicEventKind.storm:
        return Icons.thunderstorm_rounded;
      case DynamicEventKind.fog:
        return Icons.foggy;
      case DynamicEventKind.emergency:
        return Icons.emergency_rounded;
      case DynamicEventKind.closure:
        return Icons.block_rounded;
    }
  }

  static String _eventKey(DynamicEventKind kind) {
    switch (kind) {
      case DynamicEventKind.storm:
        return 'event_storm';
      case DynamicEventKind.fog:
        return 'event_fog';
      case DynamicEventKind.emergency:
        return 'event_emergency';
      case DynamicEventKind.closure:
        return 'event_closure';
    }
  }
}
