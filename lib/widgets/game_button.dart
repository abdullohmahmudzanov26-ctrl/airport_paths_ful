import 'package:flutter/material.dart';

import '../services/service_locator.dart';
import '../services/audio_service.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

enum GameButtonKind { primary, secondary, success, danger, neutral, locked }

/// Объёмная кнопка в стиле референса: градиент, светлая рамка,
/// плотный нижний торец и честное "вдавливание" при нажатии.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = GameButtonKind.secondary,
    this.icon,
    this.height = 56,
    this.width,
    this.depth = 6,
    this.radius = 18,
    this.textStyle,
    this.badge,
    this.enabled = true,
    this.playSound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonKind kind;
  final IconData? icon;
  final double height;
  final double? width;
  final double depth;
  final double radius;
  final TextStyle? textStyle;

  /// Красный кружок в углу (счётчик подсказок).
  final int? badge;
  final bool enabled;
  final bool playSound;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _interactive => widget.enabled && widget.onPressed != null;

  void _handleTap() {
    if (!_interactive) return;
    if (widget.playSound) Services.audio.play(Sfx.click);
    Services.haptics.tap();
    widget.onPressed!.call();
  }

  ButtonPalette _palette(AppPalette p) {
    if (!_interactive) return p.locked;
    switch (widget.kind) {
      case GameButtonKind.primary:
        return p.primary;
      case GameButtonKind.secondary:
        return p.secondary;
      case GameButtonKind.success:
        return p.success;
      case GameButtonKind.danger:
        return p.danger;
      case GameButtonKind.neutral:
        return p.neutral;
      case GameButtonKind.locked:
        return p.locked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonPalette c = _palette(context.palette);
    final TextStyle style = (widget.textStyle ?? AppText.button).copyWith(
      color: c.text,
      shadows: AppText.pressedShadow,
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _interactive ? (_) => _press.forward() : null,
        onTapUp: _interactive ? (_) => _press.reverse() : null,
        onTapCancel: _interactive ? () => _press.reverse() : null,
        onTap: _handleTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height + widget.depth,
          child: AnimatedBuilder(
            animation: _press,
            builder: (BuildContext context, Widget? child) {
              final double t = _press.value;
              final double drop = widget.depth * t;
              return Padding(
                padding: EdgeInsets.only(top: drop, bottom: widget.depth - drop),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius),
                    gradient: c.gradient,
                    border: Border.all(color: c.border.withOpacity(0.55), width: 1.4),
                    boxShadow: <BoxShadow>[
                      // Торец: даёт объём.
                      BoxShadow(
                        color: c.shadow,
                        offset: Offset(0, widget.depth - drop),
                      ),
                      // Мягкая тень на фон.
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28 * (1 - t * 0.6)),
                        offset: Offset(0, widget.depth - drop + 3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: _ButtonFace(
              label: widget.label,
              icon: widget.icon,
              style: style,
              radius: widget.radius,
              badge: widget.badge,
              iconColor: c.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonFace extends StatelessWidget {
  const _ButtonFace({
    required this.label,
    required this.icon,
    required this.style,
    required this.radius,
    required this.badge,
    required this.iconColor,
  });

  final String label;
  final IconData? icon;
  final TextStyle style;
  final double radius;
  final int? badge;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        // Глянцевый блик по верхней половине.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
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
                        Colors.white.withOpacity(0.26),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: (style.fontSize ?? 16) + 5, color: iconColor),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -8,
            right: -6,
            child: _Badge(value: badge!),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFFF6B5B), Color(0xFFD32F2F)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.75), width: 1.5),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
