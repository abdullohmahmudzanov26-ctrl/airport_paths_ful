import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/level_repository.dart';
import '../models/achievement.dart';
import '../models/level_result.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';
import 'app_panel.dart';
import 'game_button.dart';
import 'icon_plate_button.dart';
import 'ribbon_banner.dart';
import 'stat_chip.dart';

/// Экран победы: лента, звёзды по одной, время, ходы и награда.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.result,
    required this.freshAchievements,
    required this.onNext,
    required this.onRetry,
    required this.onHome,
  });

  final LevelResult result;
  final List<Achievement> freshAchievements;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stars = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _stars.forward();
    _chimeStars();
  }

  /// Звук на каждую заработанную звезду, в такт с её появлением.
  /// Паузы между звёздами одинаковые: раньше задержка накапливалась
  /// и третий звук отставал от анимации почти на полсекунды.
  Future<void> _chimeStars() async {
    // Первая звезда всплывает на 0.15 от 1100 мс, дальше шаг 0.22.
    await Future<void>.delayed(const Duration(milliseconds: 165));
    for (int i = 0; i < widget.result.stars; i++) {
      if (!mounted) return;
      Services.audio.play(Sfx.star);
      Services.haptics.tap();
      await Future<void>.delayed(const Duration(milliseconds: 242));
    }
  }

  @override
  void dispose() {
    _stars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final LevelResult r = widget.result;
    final bool hasNext = LevelRepository.exists(r.levelId + 1);
    const double width = 268;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.66),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: AnimatedEntrance(
            duration: const Duration(milliseconds: 320),
            offset: const Offset(0, 0.14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RibbonBanner(text: tr('level_complete')),
                const SizedBox(height: 14),
                AppPanel(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _Stars(controller: _stars, earned: r.stars),
                      // Тот же StatChip, что уже используют монеты
                      // и подсказки в шапке - новый виджет не нужен.
                      if (r.perfect) ...<Widget>[
                        const SizedBox(height: 8),
                        StatChip(
                          icon: Icons.verified_rounded,
                          value: tr('perfect_run'),
                          iconColor: p.success.top,
                        ),
                      ],
                      const SizedBox(height: 18),
                      // Wrap, а не Row: на испанском MOVIMIENTOS длинное
                      // и пара метрик спокойно переносится на две строки.
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 22,
                        runSpacing: 6,
                        children: <Widget>[
                          _Metric(label: tr('time'), value: r.formattedTime),
                          _Metric(label: tr('moves'), value: '${r.moves}'),
                        ],
                      ),
                      if (r.isNewBest) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          tr('new_best'),
                          style: AppText.caption.copyWith(color: p.success.top),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Монеты платятся один раз за уровень. При повторном
                      // прохождении r.coins == 0 — показывать «награда: 0»
                      // выглядело бы как баг, поэтому вместо суммы короткая
                      // подпись без цифр и без иконки монеты.
                      if (r.coins > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              '${tr('reward')}:',
                              style:
                                  AppText.label.copyWith(color: p.textMuted),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${r.coins}',
                              style:
                                  AppText.value.copyWith(color: p.textPrimary),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.monetization_on_rounded,
                                size: 20, color: p.coin),
                          ],
                        )
                      else
                        Text(
                          tr('reward_claimed'),
                          style: AppText.caption.copyWith(color: p.textMuted),
                        ),
                      if (widget.freshAchievements.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        for (final Achievement a in widget.freshAchievements)
                          _AchievementRow(achievement: a),
                      ],
                      const SizedBox(height: 20),
                      GameButton(
                        label: hasNext ? tr('next_level') : tr('home'),
                        kind: GameButtonKind.success,
                        width: width,
                        height: 56,
                        onPressed: hasNext ? widget.onNext : widget.onHome,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          GameButton(
                            label: tr('restart'),
                            width: width - 66,
                            onPressed: widget.onRetry,
                          ),
                          const SizedBox(width: 10),
                          IconPlateButton(
                            icon: Icons.home_rounded,
                            size: 56,
                            radius: 18,
                            depth: 6,
                            kind: GameButtonKind.secondary,
                            tooltip: tr('home'),
                            onPressed: widget.onHome,
                          ),
                        ],
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

/// Звёзды всплывают по очереди - без этого победа выглядит статичной.
class _Stars extends StatelessWidget {
  const _Stars({required this.controller, required this.earned});

  final AnimationController controller;
  final int earned;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(3, (int i) {
          final bool filled = i < earned;

          // Границы обязаны укладываться в 0..1, иначе Interval падает
          // с assert. Считаем от начала и добавляем длительность,
          // а не задаём конец отдельной формулой.
          final double start = 0.15 + i * 0.22;
          final double end = start + 0.40;

          final Animation<double> pop = CurvedAnimation(
            parent: controller,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ScaleTransition(
              scale:
                  filled ? pop : const AlwaysStoppedAnimation<double>(0.82),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 54,
                color: filled ? p.star : p.starEmpty,
                shadows: filled
                    ? const <Shadow>[
                        Shadow(
                          color: Color(0x73000000),
                          offset: Offset(0, 3),
                          blurRadius: 5,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        }),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label:',
          style: AppText.label.copyWith(color: p.textMuted),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppText.value.copyWith(color: p.textPrimary, fontSize: 16),
        ),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(achievement.icon, size: 18, color: p.star),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              tr(achievement.titleKey),
              style: AppText.label.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
