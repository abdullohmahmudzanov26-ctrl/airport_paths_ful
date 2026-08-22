import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../data/boss_config.dart';
import '../theme/app_palette.dart';
import 'star_row.dart';

/// Плитка уровня из сетки выбора.
/// Три состояния: пройден (зелёная со звёздами), открыт (синяя),
/// закрыт (тёмная с замком) - ровно как на референсе.
///
/// Четвёртое состояние - босс-уровень (каждый десятый). Он не должен
/// теряться в ряду одинаковых плиток, поэтому у него своя пурпурная
/// палитра с золотой рамкой, корона, подпись BOSS и мягкое свечение.
/// Обычные плитки при этом выглядят и ведут себя как раньше.
class LevelTile extends StatefulWidget {
  const LevelTile({
    super.key,
    required this.levelId,
    required this.stars,
    required this.unlocked,
    required this.onTap,
    this.isNext = false,
  });

  final int levelId;
  final int stars;
  final bool unlocked;

  /// Первый неоткрытый пройденный уровень подсвечивается ярче.
  final bool isNext;
  final VoidCallback onTap;

  @override
  State<LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<LevelTile> with TickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 150),
  );

  /// Дыхание золотого ореола. Заводится только на плитках босса -
  /// на обычной странице это максимум две штуки, поэтому лишних
  /// тикеров в сетке не появляется.
  AnimationController? _glow;

  bool get _isBoss => BossConfig.isBoss(widget.levelId);

  @override
  void initState() {
    super.initState();
    if (_isBoss && widget.unlocked) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _glow?.dispose();
    super.dispose();
  }

  ButtonPalette _colors(AppPalette p) {
    // Босс остаётся боссом в любом состоянии: и закрытым, и пройденным.
    // Иначе после прохождения он сливался бы с зелёной сеткой.
    if (_isBoss && widget.unlocked) return p.boss;
    if (!widget.unlocked) return p.locked;
    if (widget.stars > 0) return p.success;
    return p.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ButtonPalette c = _colors(p);
    final bool bossLocked = _isBoss && !widget.unlocked;
    const double depth = 5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable?>[_press, _glow]),
        builder: (BuildContext context, Widget? child) {
          final double drop = depth * _press.value;
          final double pulse = _glow == null
              ? 0
              : (math.sin(_glow!.value * math.pi * 2) + 1) / 2;

          return Padding(
            padding: EdgeInsets.only(top: drop, bottom: depth - drop),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: c.gradient,
                border: Border.all(
                  color: _isBoss
                      ? c.border.withOpacity(bossLocked ? 0.55 : 0.95)
                      : c.border.withOpacity(0.5),
                  width: _isBoss ? 2.2 : 1.3,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: c.shadow, offset: Offset(0, depth - drop)),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.26),
                    offset: Offset(0, depth - drop + 2),
                    blurRadius: 8,
                  ),
                  // Золотой ореол босса дышит, поэтому плитка ловит
                  // взгляд даже боковым зрением.
                  if (_isBoss && widget.unlocked)
                    BoxShadow(
                      color: p.star.withOpacity(0.30 + pulse * 0.35),
                      blurRadius: 12 + pulse * 12,
                      spreadRadius: pulse * 2,
                    ),
                  if (widget.isNext && !_isBoss)
                    BoxShadow(
                      color: p.secondary.top.withOpacity(0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: _TileFace(
          levelId: widget.levelId,
          stars: widget.stars,
          unlocked: widget.unlocked,
          isBoss: _isBoss,
          textColor: c.text,
        ),
      ),
    );
  }
}

class _TileFace extends StatelessWidget {
  const _TileFace({
    required this.levelId,
    required this.stars,
    required this.unlocked,
    required this.isBoss,
    required this.textColor,
  });

  final int levelId;
  final int stars;
  final bool unlocked;
  final bool isBoss;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    if (!unlocked) {
      // Закрытый босс тоже виден заранее: замок соседствует с короной,
      // и игрок понимает, что его ждёт впереди.
      return Stack(
        children: <Widget>[
          if (isBoss) _CrownBadge(color: p.star.withOpacity(0.75)),
          Center(
            child: Icon(
              Icons.lock_rounded,
              size: 26,
              color: textColor.withOpacity(0.9),
              shadows: const <Shadow>[
                Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
              ],
            ),
          ),
          if (isBoss)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: _BossLabel(dimmed: true),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: <Widget>[
        // Глянец по верхней половине - как у остальных кнопок.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withOpacity(0.24),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isBoss) _CrownBadge(color: p.star),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (isBoss) const SizedBox(height: 6),
              Text(
                '$levelId',
                style: TextStyle(
                  fontSize: isBoss ? 24 : 26,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.0,
                  shadows: const <Shadow>[
                    Shadow(color: Color(0x73000000), offset: Offset(0, 2), blurRadius: 3),
                  ],
                ),
              ),
              if (stars > 0) ...<Widget>[
                const SizedBox(height: 4),
                StarRow(count: stars, size: isBoss ? 11 : 13),
              ],
              if (isBoss) ...<Widget>[
                SizedBox(height: stars > 0 ? 3 : 5),
                const _BossLabel(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Корона в углу плитки - метка босса, читаемая даже мельком.
class _CrownBadge extends StatelessWidget {
  const _CrownBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 5,
      left: 0,
      right: 0,
      child: Icon(
        Icons.workspace_premium_rounded,
        size: 17,
        color: color,
        shadows: const <Shadow>[
          Shadow(color: Color(0x8C000000), offset: Offset(0, 1), blurRadius: 3),
        ],
      ),
    );
  }
}

/// Золотая подпись BOSS. Текст берётся из локализации, поэтому на
/// испанском плитка так же читается.
class _BossLabel extends StatelessWidget {
  const _BossLabel({this.dimmed = false});

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(dimmed ? 0.22 : 0.30),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: p.star.withOpacity(dimmed ? 0.45 : 0.85),
          width: 1,
        ),
      ),
      child: Text(
        tr('boss_tile'),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
          height: 1.0,
          color: p.star.withOpacity(dimmed ? 0.7 : 1.0),
        ),
      ),
    );
  }
}
