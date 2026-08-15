import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import 'animated_entrance.dart';
import 'app_panel.dart';
import 'game_button.dart';

/// Пауза. Появилась уже на этапе 4, потому что кнопке «Заново»
/// нужно было честное место, а не спрятанный жест.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onHome,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    const double width = 260;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.62),
        alignment: Alignment.center,
        child: AnimatedEntrance(
          duration: const Duration(milliseconds: 260),
          offset: const Offset(0, 0.12),
          child: AppPanel(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  tr('pause'),
                  style: AppText.screenTitle.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: 18),
                GameButton(
                  label: tr('resume'),
                  kind: GameButtonKind.success,
                  width: width,
                  onPressed: onResume,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: tr('restart'),
                  width: width,
                  onPressed: onRestart,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: tr('settings'),
                  width: width,
                  onPressed: onSettings,
                ),
                const SizedBox(height: 12),
                GameButton(
                  label: tr('home'),
                  kind: GameButtonKind.neutral,
                  width: width,
                  onPressed: onHome,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
