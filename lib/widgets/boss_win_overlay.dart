import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/level_repository.dart';
import '../models/boss_result.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';
import 'app_panel.dart';
import 'boss_overlays.dart';
import 'game_button.dart';
import 'ribbon_banner.dart';
import 'stat_chip.dart';

/// Экран победы над боссом: «ЛАБИРИНТ ПРОЙДЕН!», монеты, время,
/// оставшиеся попытки и разбор бонуса.
///
/// Собран из тех же кирпичей, что и обычный WinOverlay - лента,
/// панель, StatChip и GameButton, - поэтому выглядит как часть игры,
/// а не как чужой экран.
class BossWinOverlay extends StatelessWidget {
  const BossWinOverlay({
    super.key,
    required this.result,
    required this.onNext,
    required this.onHome,
  });

  final BossResult result;
  final VoidCallback onNext;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool hasNext = LevelRepository.exists(result.levelId + 1);
    const double width = 268;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.70),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: AnimatedEntrance(
            duration: const Duration(milliseconds: 340),
            offset: const Offset(0, 0.14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RibbonBanner(text: tr('boss_maze_complete')),
                const SizedBox(height: 14),
                AppPanel(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      StatChip(
                        icon: Icons.military_tech_rounded,
                        value: '${tr('boss_title')} ${result.levelId}',
                        iconColor: p.star,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 22,
                        runSpacing: 6,
                        children: <Widget>[
                          _Metric(
                            label: tr('time'),
                            value: result.formattedTime,
                          ),
                          _Metric(
                            label: tr('boss_time_left'),
                            value: '${result.secondsLeft}${tr('boss_sec_short')}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        tr('boss_attempts_left'),
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: 6),
                      BossAttemptDots(left: result.attemptsLeft, size: 20),
                      if (result.isNewBest) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          tr('new_best'),
                          style: AppText.caption.copyWith(color: p.success.top),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            '${tr('reward')}:',
                            style: AppText.label.copyWith(color: p.textMuted),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${result.coins}',
                            style: AppText.value.copyWith(
                              color: p.textPrimary,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.monetization_on_rounded,
                              size: 22, color: p.coin),
                        ],
                      ),
                      // Разбор награды показываем только при первом
                      // прохождении: при повторном платится скромная
                      // фиксированная сумма и расписывать нечего.
                      if (result.firstClear && result.hasBonus) ...<Widget>[
                        const SizedBox(height: 10),
                        _BonusRow(
                          label: tr('boss_base'),
                          value: result.baseReward,
                        ),
                        _BonusRow(
                          label: tr('boss_bonus_time'),
                          value: result.timeBonus,
                        ),
                        _BonusRow(
                          label: tr('boss_bonus_attempts'),
                          value: result.attemptsBonus,
                        ),
                      ],
                      if (!result.firstClear) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          tr('boss_replay_note'),
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(color: p.textMuted),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GameButton(
                        label: hasNext ? tr('next_level') : tr('home'),
                        kind: GameButtonKind.success,
                        width: width,
                        height: 56,
                        onPressed: hasNext ? onNext : onHome,
                      ),
                      const SizedBox(height: 12),
                      GameButton(
                        label: tr('home'),
                        kind: GameButtonKind.neutral,
                        width: width,
                        onPressed: onHome,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: AppText.caption.copyWith(color: p.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppText.value.copyWith(color: p.textPrimary)),
      ],
    );
  }
}

class _BonusRow extends StatelessWidget {
  const _BonusRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(label, style: AppText.caption.copyWith(color: p.textMuted)),
          const SizedBox(width: 8),
          Text(
            '+$value',
            style: AppText.caption.copyWith(color: p.success.top),
          ),
        ],
      ),
    );
  }
}
