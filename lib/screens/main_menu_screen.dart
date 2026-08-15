import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../models/game_settings.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/game_button.dart';
import '../widgets/game_logo.dart';
import '../widgets/icon_plate_button.dart';

/// Главное меню: логотип на фоне аэродрома, четыре кнопки,
/// нижний ряд круглых иконок.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  static const double _buttonMaxWidth = 300;

  void _openCurrentLevel(BuildContext context) {
    final int level = Services.progress.currentLevel;
    Services.progress.rememberCurrentLevel(level);
    Navigator.of(context).pushNamed(
      Routes.game,
      arguments: GameArgs(levelId: level),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints c) {
              final double width =
                  c.maxWidth * 0.72 > _buttonMaxWidth ? _buttonMaxWidth : c.maxWidth * 0.72;
              final bool compact = c.maxHeight < 640;

              return Column(
                children: <Widget>[
                  SizedBox(height: compact ? 18 : 40),
                  AnimatedEntrance(
                    offset: const Offset(0, -0.25),
                    duration: const Duration(milliseconds: 620),
                    child: GameLogo(scale: compact ? 0.85 : 1.0),
                  ),
                  const Spacer(),
                  _MenuButtons(
                    width: width,
                    onPlay: () => _openCurrentLevel(context),
                  ),
                  SizedBox(height: compact ? 18 : 28),
                  const _MenuFooter(),
                  const SizedBox(height: 10),
                  Text(
                    'v1.0.0',
                    style: AppText.caption.copyWith(color: p.textMuted),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuButtons extends StatelessWidget {
  const _MenuButtons({required this.width, required this.onPlay});

  final double width;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Services.progress,
      builder: (BuildContext context, _) {
        final List<Widget> buttons = <Widget>[
          GameButton(
            label: Services.progress.currentLevel > 1
                ? '${tr('play')}  ${Services.progress.currentLevel}'
                : tr('play'),
            kind: GameButtonKind.primary,
            width: width,
            height: 60,
            depth: 7,
            textStyle: AppText.button.copyWith(fontSize: 19),
            onPressed: onPlay,
          ),
          GameButton(
            label: tr('levels'),
            width: width,
            onPressed: () => Navigator.of(context).pushNamed(Routes.levels),
          ),
          GameButton(
            label: tr('settings'),
            width: width,
            onPressed: () => Navigator.of(context).pushNamed(Routes.settings),
          ),
          GameButton(
            label: tr('airport'),
            width: width,
            onPressed: () => Navigator.of(context).pushNamed(Routes.airport),
          ),
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < buttons.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedEntrance(
                  delay: Duration(milliseconds: 120 + i * 90),
                  child: buttons[i],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MenuFooter extends StatelessWidget {
  const _MenuFooter();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameSettings>(
      valueListenable: Services.settings,
      builder: (BuildContext context, GameSettings settings, _) {
        final bool soundOn = settings.music || settings.sounds;
        return AnimatedEntrance(
          delay: const Duration(milliseconds: 520),
          offset: const Offset(0, 0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MenuIconButton(
                icon: Icons.star_rounded,
                label: tr('rate'),
                onPressed: () => _notImplemented(context, tr('rate')),
              ),
              const SizedBox(width: 26),
              MenuIconButton(
                icon: Icons.emoji_events_rounded,
                label: tr('achievements'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.achievements),
              ),
              const SizedBox(width: 26),
              MenuIconButton(
                icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                label: tr('sound'),
                active: soundOn,
                onPressed: Services.settings.toggleAllSound,
              ),
            ],
          ),
        );
      },
    );
  }

  void _notImplemented(BuildContext context, String what) {
    final AppPalette p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          backgroundColor: p.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.panelBorder.withOpacity(0.6)),
          ),
          content: Text(
            '$what — ${tr('coming_soon').toLowerCase()}',
            style: AppText.label.copyWith(color: p.textSecondary),
          ),
        ),
      );
  }
}