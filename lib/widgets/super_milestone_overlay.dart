import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/board_themes.dart';
import '../data/super_milestones.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'game_button.dart';

/// Полноэкранное поздравление с одной из четырёх супер-вех (50/100/150/200).
///
/// Показывается поверх уже собранного WinOverlay через showDialog -
/// ни новой навигации, ни нового состояния экрана игры не требуется.
class SuperMilestoneOverlay extends StatefulWidget {
  const SuperMilestoneOverlay({
    super.key,
    required this.milestone,
    this.grantedThemeId,
  });

  final SuperMilestone milestone;

  /// На уровнях 100 и 150 та же веха приносит ещё и новую локацию
  /// бесплатно - её можно надеть или не надевать по желанию, но
  /// заявить об этом стоит громко, вместе с самой вехой, а не мелкой
  /// строкой где-то ещё.
  final String? grantedThemeId;

  @override
  State<SuperMilestoneOverlay> createState() => _SuperMilestoneOverlayState();
}

class _SuperMilestoneOverlayState extends State<SuperMilestoneOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final Animation<double> number = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    final Animation<double> body = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: <Color>[
                  p.primary.top.withOpacity(0.35),
                  const Color(0xFF06111F),
                ],
              ),
            ),
          ),
          Positioned.fill(child: _Confetti(controller: _c)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      tr('super_milestone'),
                      style: AppText.caption.copyWith(
                        color: p.coin,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ScaleTransition(
                      scale: number,
                      child: Text(
                        '${widget.milestone.level}',
                        style: AppText.logo.copyWith(
                          fontSize: 96,
                          color: Colors.white,
                          shadows: <Shadow>[
                            Shadow(
                              color: p.primary.top.withOpacity(0.8),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    FadeTransition(
                      opacity: body,
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 6),
                          Text(
                            tr(widget.milestone.phraseKey),
                            textAlign: TextAlign.center,
                            style: AppText.value.copyWith(
                              color: Colors.white,
                              fontSize: 19,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.monetization_on_rounded,
                                  size: 30, color: p.coin),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.milestone.coins}',
                                style: AppText.logo.copyWith(
                                  fontSize: 34,
                                  color: p.coin,
                                ),
                              ),
                            ],
                          ),
                          if (widget.grantedThemeId != null) ...<Widget>[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: p.primary.top.withOpacity(0.5),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.map_rounded,
                                          size: 18, color: p.primary.top),
                                      const SizedBox(width: 8),
                                      Text(
                                        tr('zone_unlocked_title'),
                                        style: AppText.caption.copyWith(
                                          color: p.primary.top,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tr(BoardThemes.byId(
                                      widget.grantedThemeId,
                                    ).nameKey),
                                    style: AppText.value.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tr('zone_unlocked_hint'),
                                    textAlign: TextAlign.center,
                                    style: AppText.caption.copyWith(
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          GameButton(
                            label: tr('resume'),
                            kind: GameButtonKind.primary,
                            width: 220,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Конфетти: позиции считаются один раз в initState, дальше только
/// читаются - в paint() ни Paint, ни List не создаются.
class _Confetti extends StatefulWidget {
  const _Confetti({required this.controller});

  final AnimationController controller;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> {
  static const int _count = 46;

  late final List<double> _x =
      List<double>.generate(_count, (_) => _rnd.nextDouble());
  late final List<double> _delay =
      List<double>.generate(_count, (_) => _rnd.nextDouble() * 0.4);
  late final List<double> _speed =
      List<double>.generate(_count, (_) => 0.7 + _rnd.nextDouble() * 0.6);
  late final List<double> _sway =
      List<double>.generate(_count, (_) => (_rnd.nextDouble() - 0.5) * 40);
  late final List<double> _spin =
      List<double>.generate(_count, (_) => (_rnd.nextDouble() - 0.5) * 8);
  late final List<int> _colorIndex =
      List<int>.generate(_count, (_) => _rnd.nextInt(PlaneColors.all.length));

  final math.Random _rnd = math.Random(2026);

  /// По одной кисти на цвет палитры бортов - переиспользуются на
  /// все частицы этого цвета, ничего не создаётся в paint().
  late final List<Paint> _paints = <Paint>[
    for (final Color c in PlaneColors.all) Paint()..color = c,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, _) => CustomPaint(
        painter: _ConfettiPainter(
          t: widget.controller.value,
          x: _x,
          delay: _delay,
          speed: _speed,
          sway: _sway,
          spin: _spin,
          colorIndex: _colorIndex,
          paints: _paints,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.t,
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.spin,
    required this.colorIndex,
    required this.paints,
  });

  final double t;
  final List<double> x;
  final List<double> delay;
  final List<double> speed;
  final List<double> sway;
  final List<double> spin;
  final List<int> colorIndex;
  final List<Paint> paints;

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < x.length; i++) {
      final double local = ((t - delay[i]) * speed[i]).clamp(0.0, 1.2);
      if (local <= 0) continue;
      final double fall = local * size.height * 1.15;
      final double drift = math.sin(local * math.pi * 1.6) * sway[i];
      final double px = x[i] * size.width + drift;
      final double py = fall - size.height * 0.15;
      if (py < -12 || py > size.height + 12) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(local * spin[i]);
      canvas.drawRect(
        const Rect.fromLTWH(-3.5, -6, 7, 12),
        paints[colorIndex[i]],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
