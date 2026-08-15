import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Ряд из трёх звёзд. Используется на карточках уровней и на экране победы.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.count,
    this.size = 14,
    this.total = 3,
    this.spacing = 1,
  });

  final int count;
  final int total;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(total, (int i) {
        final bool filled = i < count;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? p.star : p.starEmpty,
            shadows: filled
                ? const <Shadow>[
                    Shadow(color: Color(0x66000000), offset: Offset(0, 1), blurRadius: 2),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
