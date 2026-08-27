import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';
import 'app_panel.dart';
import 'game_button.dart';

/// Три сердца - жизни на обычных уровнях. Тот же приём, что и
/// BossAttemptDots для боссов, но своя, более скромная сущность:
/// эти две системы жизней не связаны и не делят состояние.
class LevelLivesRow extends StatelessWidget {
  const LevelLivesRow({super.key, required this.livesLeft, this.size = 22});

  final int livesLeft;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(3, (int i) {
        final bool alive = i < livesLeft;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.14),
          child: Icon(
            alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size,
            color: alive ? p.danger.top : p.textMuted.withOpacity(0.45),
          ),
        );
      }),
    );
  }
}

/// Не уложился в отведённое на уровень время - показывается вместо
/// WinOverlay. Если жизни ещё остались - «Заново» доступно сразу.
/// Если нет - вместо кнопки живой отсчёт до следующей восстановленной
/// жизни (30 секунд на одну, тем же приёмом, что и банк дохода в
/// «Моём аэропорте»: считается по факту, не только пока экран открыт).
class LevelTimeUpOverlay extends StatelessWidget {
  const LevelTimeUpOverlay({
    super.key,
    required this.livesLeft,
    required this.lockSecondsLeft,
    required this.onRetry,
    required this.onHome,
  });

  final int livesLeft;

  /// 0, если ждать нечего - тогда livesLeft обязательно больше нуля.
  final int lockSecondsLeft;

  /// null, если жизней не осталось - кнопка «Заново» тогда не рисуется.
  final VoidCallback? onRetry;
  final VoidCallback onHome;

  String get _formattedLock {
    final int m = lockSecondsLeft ~/ 60;
    final int s = lockSecondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final bool locked = livesLeft <= 0;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: AnimatedEntrance(
            duration: const Duration(milliseconds: 300),
            offset: const Offset(0, 0.12),
            child: AppPanel(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.timer_off_rounded, size: 44, color: p.danger.top),
                  const SizedBox(height: 10),
                  Text(
                    tr('time_up_title'),
                    style: AppText.screenTitle.copyWith(color: p.danger.top),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('time_up_hint'),
                    textAlign: TextAlign.center,
                    style: AppText.label.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  LevelLivesRow(livesLeft: livesLeft),
                  const SizedBox(height: 20),
                  if (locked) ...<Widget>[
                    Text(
                      tr('lives_locked_note'),
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        color: p.textMuted,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formattedLock,
                      style: AppText.logo.copyWith(
                        fontSize: 40,
                        color: p.star,
                        shadows: AppText.pressedShadow,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else
                    GameButton(
                      label: tr('boss_retry'),
                      icon: Icons.replay_rounded,
                      kind: GameButtonKind.success,
                      width: 220,
                      onPressed: onRetry,
                    ),
                  const SizedBox(height: 10),
                  GameButton(
                    label: tr('home'),
                    icon: Icons.home_rounded,
                    kind: GameButtonKind.neutral,
                    width: 220,
                    onPressed: onHome,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
