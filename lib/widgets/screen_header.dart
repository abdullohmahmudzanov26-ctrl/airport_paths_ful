import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'game_button.dart';
import 'icon_plate_button.dart';

/// Шапка экрана: кнопка "назад", заголовок по центру, опциональное действие.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.action,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: <Widget>[
          IconPlateButton(
            icon: Icons.arrow_back_rounded,
            kind: GameButtonKind.neutral,
            tooltip: tr('home'),
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: AppText.screenTitle.copyWith(
                  color: p.textPrimary,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Color(0x99000A14),
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 46,
            child: action ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
