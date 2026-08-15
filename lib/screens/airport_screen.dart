import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/game_logo.dart';
import '../widgets/screen_header.dart';

/// Заглушка для будущего раздела «Аэропорт».
/// Появится на следующем этапе разработки — см. AppStrings.stage_note.
class AirportScreen extends StatelessWidget {
  const AirportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0.42,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ScreenHeader(title: tr('airport')),
              const Spacer(flex: 2),
              const AnimatedEntrance(
                offset: Offset(0, -0.2),
                child: GameLogo(scale: 0.9),
              ),
              const Spacer(),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 140),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: Text(
                    tr('stage_note'),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: p.textSecondary),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}