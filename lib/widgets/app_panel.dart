import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Тёмная скруглённая панель со светлой рамкой - база для всех блоков UI.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.margin,
    this.soft = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: soft ? p.panelSoft : p.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.panelBorder.withOpacity(0.55), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: child,
    );
  }
}
