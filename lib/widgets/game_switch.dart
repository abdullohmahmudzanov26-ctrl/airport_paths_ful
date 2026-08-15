import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';

/// Тумблер в стиле игры: зелёная дорожка и белая ручка.
/// Материальный Switch сюда не вписывается по форме и цвету.
class GameSwitch extends StatelessWidget {
  const GameSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Services.audio.play(Sfx.click);
        Services.haptics.select();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 58,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: value ? p.success.gradient : null,
          color: value ? null : Colors.black.withOpacity(0.34),
          border: Border.all(
            color: value
                ? p.success.border.withOpacity(0.6)
                : p.panelBorder.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x59000000),
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
