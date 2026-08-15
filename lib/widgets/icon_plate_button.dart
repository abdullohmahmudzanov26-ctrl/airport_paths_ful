import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import 'game_button.dart';

/// Квадратная объёмная кнопка-иконка: "назад", "шестерёнка", "пауза".
class IconPlateButton extends StatefulWidget {
  const IconPlateButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.kind = GameButtonKind.neutral,
    this.size = 46,
    this.radius = 14,
    this.depth = 4,
    this.iconSize = 24,
    this.circle = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final GameButtonKind kind;
  final double size;
  final double radius;
  final double depth;
  final double iconSize;
  final bool circle;
  final String? tooltip;

  @override
  State<IconPlateButton> createState() => _IconPlateButtonState();
}

class _IconPlateButtonState extends State<IconPlateButton>
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

  ButtonPalette _colors(AppPalette p) {
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
    final ButtonPalette c = _colors(context.palette);
    final BorderRadius shape = BorderRadius.circular(
      widget.circle ? widget.size : widget.radius,
    );

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: () {
          Services.audio.play(Sfx.click);
          Services.haptics.tap();
          widget.onPressed?.call();
        },
        child: SizedBox(
          width: widget.size,
          height: widget.size + widget.depth,
          child: AnimatedBuilder(
            animation: _press,
            builder: (BuildContext context, Widget? child) {
              final double drop = widget.depth * _press.value;
              return Padding(
                padding: EdgeInsets.only(top: drop, bottom: widget.depth - drop),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: shape,
                    gradient: c.gradient,
                    border: Border.all(color: c.border.withOpacity(0.5), width: 1.3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: c.shadow, offset: Offset(0, widget.depth - drop)),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: Offset(0, widget.depth - drop + 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Center(
              child: Icon(widget.icon, size: widget.iconSize, color: c.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// Круглая кнопка с подписью снизу - нижний ряд главного меню.
class MenuIconButton extends StatelessWidget {
  const MenuIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.active = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconPlateButton(
          icon: icon,
          circle: true,
          size: 52,
          iconSize: 24,
          kind: GameButtonKind.neutral,
          onPressed: onPressed,
          tooltip: label,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: active ? p.textSecondary : p.textMuted,
          ),
        ),
      ],
    );
  }
}
