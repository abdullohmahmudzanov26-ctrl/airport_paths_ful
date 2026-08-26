import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_strings.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/game_button.dart';
import '../widgets/game_logo.dart';
import '../widgets/icon_plate_button.dart';
import '../widgets/stat_chip.dart';

/// Главное меню: логотип, четыре кнопки и ряд круглых иконок.
///
/// Настройки и «об игре» ушли в нижний ряд, чтобы освободить место
/// магазину и своему аэропорту - именно они возвращают игрока завтра.
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
          child: AnimatedBuilder(
            // Раньше слушал только Services.progress - смена языка
            // в настройках и возврат в меню показывали старый текст,
            // пока что-нибудь ещё (например, изменение монет) не
            // перестраивало экран заново.
            animation: Listenable.merge(
              <Listenable>[Services.progress, Services.settings],
            ),
            builder: (BuildContext context, _) {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints c) {
                  final double width = c.maxWidth * 0.72 > _buttonMaxWidth
                      ? _buttonMaxWidth
                      : c.maxWidth * 0.72;
                  final bool compact = c.maxHeight < 680;

                  return Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            StatChip(
                              icon: Icons.monetization_on_rounded,
                              value: '${Services.progress.coins}',
                              iconColor: p.coin,
                            ),
                          ],
                        ),
                      ),
                      const _AirportAmbience(),
                      SizedBox(height: compact ? 6 : 18),
                      AnimatedEntrance(
                        offset: const Offset(0, -0.25),
                        duration: const Duration(milliseconds: 620),
                        child: GameLogo(scale: compact ? 0.8 : 0.95),
                      ),
                      const Spacer(),
                      _MenuButtons(
                        width: width,
                        onPlay: () => _openCurrentLevel(context),
                      ),
                      SizedBox(height: compact ? 14 : 24),
                      const _MenuFooter(),
                      const SizedBox(height: 8),
                      Text(
                        'v1.0.0',
                        style: AppText.caption.copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Атмосфера аэропорта в меню: изредка вдалеке взлетает борт.
///
/// Ничего не рисует - существует только ради таймера, поэтому его
/// можно вставить в любое место дерева, не трогая вёрстку экрана.
/// Переиспользует уже готовый Sfx.takeoff и AudioService, который сам
/// молчит при выключенном звуке.
class _AirportAmbience extends StatefulWidget {
  const _AirportAmbience();

  @override
  State<_AirportAmbience> createState() => _AirportAmbienceState();
}

class _AirportAmbienceState extends State<_AirportAmbience> {
  static const int _minSeconds = 5;
  static const int _maxSeconds = 10;

  final math.Random _rnd = math.Random();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  /// Следующий взлёт планируется только после предыдущего, поэтому
  /// два звука никогда не накладываются друг на друга.
  void _schedule() {
    final int wait = _minSeconds + _rnd.nextInt(_maxSeconds - _minSeconds + 1);
    _timer?.cancel();
    _timer = Timer(Duration(seconds: wait), () {
      if (!mounted) return;
      // Проверяем настройку до вызова: AudioService и сам смолчит,
      // но так мы не дёргаем плеер впустую каждые несколько секунд.
      if (Services.settings.value.sounds) {
        Services.audio.play(Sfx.takeoff);
      }
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MenuButtons extends StatelessWidget {
  const _MenuButtons({
    required this.width,
    required this.onPlay,
  });

  final double width;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = <Widget>[
      // PLAY - главный акцент экрана: выше остальных, с подписью
      // текущего уровня, чтобы сразу было видно, куда возвращаешься.
      SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            GameButton(
              label: tr('play'),
              icon: Icons.flight_takeoff_rounded,
              kind: GameButtonKind.primary,
              width: width,
              height: 72,
              depth: 8,
              textStyle: AppText.button.copyWith(fontSize: 21),
              onPressed: onPlay,
            ),
            Positioned(
              bottom: 14,
              child: IgnorePointer(
                child: Text(
                  '${tr('level')} ${Services.progress.currentLevel}',
                  style: AppText.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      GameButton(
        label: tr('levels'),
        width: width,
        onPressed: () => Navigator.of(context).pushNamed(Routes.levels),
      ),
      GameButton(
        label: tr('shop'),
        icon: Icons.storefront_rounded,
        width: width,
        onPressed: () => Navigator.of(context).pushNamed(Routes.shop),
      ),
      GameButton(
        label: tr('my_airport'),
        icon: Services.progress.airportUnlocked
            ? Icons.location_city_rounded
            : Icons.lock_rounded,
        kind: Services.progress.airportUnlocked
            ? GameButtonKind.secondary
            : GameButtonKind.locked,
        width: width,
        // Точка-напоминание, когда доход ещё не забран.
        badge: Services.progress.airportIncomeReady
            ? Services.progress.airportBankedAmount
            : null,
        onPressed: () => Navigator.of(context).pushNamed(Routes.myAirport),
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < buttons.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: AnimatedEntrance(
              delay: Duration(milliseconds: 120 + i * 80),
              child: buttons[i],
            ),
          ),
      ],
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
                icon: Icons.emoji_events_rounded,
                label: tr('achievements'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.achievements),
              ),
              const SizedBox(width: 18),
              MenuIconButton(
                icon: Icons.settings_rounded,
                label: tr('settings'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(Routes.settings),
              ),
              const SizedBox(width: 18),
              MenuIconButton(
                icon: Icons.info_rounded,
                label: tr('about'),
                onPressed: () => Navigator.of(context).pushNamed(Routes.about),
              ),
              const SizedBox(width: 18),
              MenuIconButton(
                icon: soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
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
}
