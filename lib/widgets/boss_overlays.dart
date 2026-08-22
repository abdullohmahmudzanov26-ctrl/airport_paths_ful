import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/boss_config.dart';
import '../data/maze_themes.dart';
import '../game/boss/boss_maze_game.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';
import 'app_panel.dart';
import 'game_button.dart';

/// Полоска попыток: три огня, погасшие - потраченные.
class BossAttemptDots extends StatelessWidget {
  const BossAttemptDots({super.key, required this.left, this.size = 14});

  final int left;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(BossConfig.attempts, (int i) {
        final bool alive = i < left;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: size * 0.16),
          child: Icon(
            alive ? Icons.flight_rounded : Icons.flight_takeoff_rounded,
            size: size,
            color: alive ? p.success.top : p.textMuted.withOpacity(0.45),
          ),
        );
      }),
    );
  }
}

/// Заставка входа в босса.
///
/// Задача экрана - за две секунды дать понять, что это не обычный
/// уровень: тёмный экран, разгорающееся сияние, лента «БОСС» и
/// главная строка «ПРОЙДИ ЛАБИРИНТ!». Карта и самолёт появляются
/// уже под ней и проступают, когда заставка уходит.
class BossIntroOverlay extends StatefulWidget {
  const BossIntroOverlay({
    super.key,
    required this.levelId,
    required this.theme,
    required this.timeLimit,
    required this.attemptsLeft,
    required this.onStart,
  });

  final int levelId;
  final MazeTheme theme;
  final int timeLimit;
  final int attemptsLeft;
  final VoidCallback onStart;

  @override
  State<BossIntroOverlay> createState() => _BossIntroOverlayState();
}

class _BossIntroOverlayState extends State<BossIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final MazeTheme t = widget.theme;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.78),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedEntrance(
                duration: const Duration(milliseconds: 420),
                offset: const Offset(0, -0.25),
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (BuildContext context, Widget? child) {
                    final double glow =
                        0.5 + 0.5 * math.sin(_pulse.value * math.pi * 2);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: <Color>[t.glow, t.trap],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: t.glow.withOpacity(0.30 + glow * 0.35),
                            blurRadius: 24 + glow * 18,
                            spreadRadius: 1 + glow * 3,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Text(
                    tr('boss_title'),
                    style: AppText.logoSub.copyWith(
                      color: Colors.white,
                      letterSpacing: 10,
                      shadows: AppText.pressedShadow,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 420),
                offset: const Offset(0, 0.2),
                child: Text(
                  tr('boss_run_maze'),
                  textAlign: TextAlign.center,
                  style: AppText.screenTitle.copyWith(
                    fontSize: 30,
                    color: Colors.white,
                    letterSpacing: 2.2,
                    shadows: <Shadow>[
                      Shadow(
                        color: t.glow.withOpacity(0.8),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 240),
                duration: const Duration(milliseconds: 380),
                child: Text(
                  '${tr('level')} ${widget.levelId}  ·  ${tr(t.nameKey)}',
                  style: AppText.label.copyWith(color: p.textSecondary),
                ),
              ),
              const SizedBox(height: 22),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 320),
                duration: const Duration(milliseconds: 400),
                offset: const Offset(0, 0.16),
                child: AppPanel(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.timer_rounded,
                              size: 18, color: p.secondary.top),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.timeLimit} ${tr('boss_seconds')}',
                            style: AppText.value.copyWith(color: p.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('boss_attempts'),
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: 6),
                      BossAttemptDots(left: widget.attemptsLeft, size: 20),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 220,
                        child: Text(
                          tr('boss_hint'),
                          textAlign: TextAlign.center,
                          style: AppText.label.copyWith(
                            color: p.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 420),
                duration: const Duration(milliseconds: 380),
                child: GameButton(
                  label: tr('boss_start'),
                  icon: Icons.play_arrow_rounded,
                  kind: GameButtonKind.primary,
                  width: 230,
                  onPressed: widget.onStart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Провал попытки: короткая тревожная анимация и сколько попыток
/// осталось. Появляется и на таймере, и на ловушке, и на столкновении -
/// меняется только строка причины.
class BossFailOverlay extends StatefulWidget {
  const BossFailOverlay({
    super.key,
    required this.reason,
    required this.attemptsLeft,
    required this.onRetry,
    required this.onHome,
  });

  final BossFailReason reason;
  final int attemptsLeft;

  /// null, если попыток не осталось - тогда кнопка повтора не рисуется.
  final VoidCallback? onRetry;
  final VoidCallback onHome;

  @override
  State<BossFailOverlay> createState() => _BossFailOverlayState();
}

class _BossFailOverlayState extends State<BossFailOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.reason) {
      case BossFailReason.timeout:
        return Icons.timer_off_rounded;
      case BossFailReason.trap:
        return Icons.dangerous_rounded;
      case BossFailReason.hazard:
        return Icons.warning_amber_rounded;
    }
  }

  String get _text {
    switch (widget.reason) {
      case BossFailReason.timeout:
        return tr('boss_fail_time');
      case BossFailReason.trap:
        return tr('boss_fail_trap');
      case BossFailReason.hazard:
        return tr('boss_fail_hazard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Positioned.fill(
      child: Container(
        color: p.danger.shadow.withOpacity(0.55),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: _shake,
            builder: (BuildContext context, Widget? child) {
              // Затухающая тряска: сильный толчок в начале, полный
              // покой к концу - оверлей не дёргается всё время показа.
              final double damp = 1 - _shake.value;
              final double dx =
                  math.sin(_shake.value * math.pi * 8) * 10 * damp * damp;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.scale(
                  scale: 0.9 + 0.1 * Curves.easeOutBack.transform(
                    _shake.value.clamp(0.0, 1.0),
                  ),
                  child: child,
                ),
              );
            },
            child: AppPanel(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_icon, size: 46, color: p.danger.top),
                  const SizedBox(height: 10),
                  Text(
                    _text,
                    textAlign: TextAlign.center,
                    style: AppText.screenTitle.copyWith(color: p.danger.top),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('boss_attempt_lost'),
                    style: AppText.label.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tr('boss_attempts_left'),
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(height: 6),
                  BossAttemptDots(left: widget.attemptsLeft, size: 22),
                  const SizedBox(height: 20),
                  if (widget.onRetry != null)
                    GameButton(
                      label: tr('boss_retry'),
                      icon: Icons.replay_rounded,
                      kind: GameButtonKind.success,
                      width: 220,
                      onPressed: widget.onRetry,
                    ),
                  if (widget.onRetry != null) const SizedBox(height: 10),
                  GameButton(
                    label: tr('home'),
                    icon: Icons.home_rounded,
                    kind: GameButtonKind.neutral,
                    width: 220,
                    onPressed: widget.onHome,
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

/// Блокировка после трёх поражений: замок и обратный отсчёт до
/// новых трёх попыток. Ровно минута - и ни секундой меньше, время
/// считается по часам устройства, а не по кадрам.
class BossLockOverlay extends StatelessWidget {
  const BossLockOverlay({
    super.key,
    required this.secondsLeft,
    required this.onHome,
  });

  final int secondsLeft;
  final VoidCallback onHome;

  String get _formatted {
    final int m = secondsLeft ~/ 60;
    final int s = secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final double progress = secondsLeft <= 0
        ? 1
        : 1 - (secondsLeft / BossConfig.lockSeconds).clamp(0.0, 1.0);

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
                  Icon(Icons.lock_clock_rounded, size: 46, color: p.star),
                  const SizedBox(height: 12),
                  Text(
                    tr('boss_locked'),
                    style: AppText.screenTitle.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 230,
                    child: Text(
                      tr('boss_locked_note'),
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(
                        color: p.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatted,
                    style: AppText.logo.copyWith(
                      fontSize: 44,
                      color: p.star,
                      shadows: AppText.pressedShadow,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: p.panelSoft,
                        valueColor: AlwaysStoppedAnimation<Color>(p.star),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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

/// Пауза внутри попытки. Отдельная от обычной паузы: здесь нет
/// «начать заново», потому что попытки считаны, и есть честное
/// предупреждение о том, что выход стоит попытки.
class BossPauseOverlay extends StatelessWidget {
  const BossPauseOverlay({
    super.key,
    required this.attemptsLeft,
    required this.onResume,
    required this.onHome,
  });

  final int attemptsLeft;
  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.72),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: AnimatedEntrance(
            duration: const Duration(milliseconds: 260),
            offset: const Offset(0, 0.1),
            child: AppPanel(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    tr('pause'),
                    style: AppText.screenTitle.copyWith(color: p.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  BossAttemptDots(left: attemptsLeft, size: 20),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 230,
                    child: Text(
                      tr('boss_leave_warning'),
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(
                        color: p.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GameButton(
                    label: tr('resume'),
                    icon: Icons.play_arrow_rounded,
                    kind: GameButtonKind.success,
                    width: 220,
                    onPressed: onResume,
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
