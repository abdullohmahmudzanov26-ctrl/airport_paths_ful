import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'star_row.dart';

/// Плитка уровня из сетки выбора.
/// Три состояния: пройден (зелёная со звёздами), открыт (синяя),
/// закрыт (тёмная с замком) - ровно как на референсе.
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

class _LevelTileState extends State<LevelTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 150),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  ButtonPalette _colors(AppPalette p) {
    if (!widget.unlocked) return p.locked;
    if (widget.stars > 0) return p.success;
    return p.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    final ButtonPalette c = _colors(p);
    const double depth = 5;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (BuildContext context, Widget? child) {
          final double drop = depth * _press.value;
          return Padding(
            padding: EdgeInsets.only(top: drop, bottom: depth - drop),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: c.gradient,
                border: Border.all(color: c.border.withOpacity(0.5), width: 1.3),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: c.shadow, offset: Offset(0, depth - drop)),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.26),
                    offset: Offset(0, depth - drop + 2),
                    blurRadius: 8,
                  ),
                  if (widget.isNext)
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
    required this.textColor,
  });

  final int levelId;
  final int stars;
  final bool unlocked;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (!unlocked) {
      return Center(
        child: Icon(
          Icons.lock_rounded,
          size: 26,
          color: textColor.withOpacity(0.9),
          shadows: const <Shadow>[
            Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
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
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$levelId',
                style: TextStyle(
                  fontSize: 26,
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
                StarRow(count: stars, size: 13),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
