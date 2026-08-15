import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';

/// Компактный счётчик: звёзды, монеты, подсказки.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.panelBorder.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: iconColor ?? p.star),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppText.label.copyWith(color: p.textPrimary),
          ),
        ],
      ),
    );
  }
}
