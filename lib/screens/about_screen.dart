import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/game_button.dart';
import '../widgets/game_logo.dart';
import '../widgets/screen_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0.42,
        child: SafeArea(
          child: Column(
            children: <Widget>[
              ScreenHeader(title: tr('about')),
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
                    tr('about_text'),
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: p.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                '${tr('version')} 1.0.0',
                style: AppText.caption.copyWith(color: p.textMuted, letterSpacing: 2),
              ),
              const SizedBox(height: 18),
              AnimatedEntrance(
                delay: const Duration(milliseconds: 240),
                child: Column(
                  children: <Widget>[
                    GameButton(
                      label: tr('privacy'),
                      width: 300,
                      height: 48,
                      textStyle: AppText.buttonSmall,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      label: tr('terms'),
                      width: 300,
                      height: 48,
                      textStyle: AppText.buttonSmall,
                      onPressed: () {},
                    ),
                  ],
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
