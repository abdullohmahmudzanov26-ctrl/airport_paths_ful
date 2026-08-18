import 'package:flutter/material.dart';

import '../data/app_strings.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import '../services/service_locator.dart';
import '../theme/app_palette.dart';
import '../theme/app_text_styles.dart';
import '../widgets/airport_backdrop.dart';
import '../widgets/app_panel.dart';
import '../widgets/game_button.dart';
import '../widgets/responsive_center.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_rows.dart';

/// Настройки. Каждое изменение сразу уходит в SharedPreferences
/// и сразу же слышно: AudioService подписан на тот же ValueNotifier.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final AppPalette p = context.palette;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AppPanel(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 38, color: p.danger.top),
              const SizedBox(height: 12),
              Text(
                tr('reset_confirm'),
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: p.textSecondary),
              ),
              const SizedBox(height: 18),
              GameButton(
                label: tr('reset_progress'),
                kind: GameButtonKind.danger,
                width: 230,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 10),
              GameButton(
                label: tr('cancel'),
                kind: GameButtonKind.neutral,
                width: 230,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed ?? false) {
      await Services.progress.resetAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;

    return Scaffold(
      body: AirportBackdrop(
        sceneHeightFactor: 0,
        animatePlane: false,
        child: SafeArea(
          child: ValueListenableBuilder<GameSettings>(
            valueListenable: Services.settings,
            builder: (BuildContext context, GameSettings s, _) {
              return Column(
                children: <Widget>[
                  ScreenHeader(title: tr('settings')),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                      child: ResponsiveCenter(
                        child: Column(
                        children: <Widget>[
                          AppPanel(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              children: <Widget>[
                                SettingsToggleRow(
                                  icon: Icons.music_note_rounded,
                                  label: tr('music'),
                                  value: s.music,
                                  onChanged: (bool v) {
                                    Services.settings.setMusic(v);
                                    if (v) {
                                      Services.audio.playMusic(MusicTrack.menu);
                                    }
                                  },
                                ),
                                const SettingsDivider(),
                                SettingsToggleRow(
                                  icon: Icons.volume_up_rounded,
                                  label: tr('sounds'),
                                  value: s.sounds,
                                  onChanged: Services.settings.setSounds,
                                ),
                                const SettingsDivider(),
                                SettingsToggleRow(
                                  icon: Icons.vibration_rounded,
                                  label: tr('vibration'),
                                  value: s.vibration,
                                  onChanged: (bool v) async {
                                    await Services.settings.setVibration(v);
                                    // Сразу дать почувствовать результат.
                                    if (v) Services.haptics.impact();
                                  },
                                ),
                                const SettingsDivider(),
                                SettingsSliderRow(
                                  label: tr('music_volume'),
                                  value: s.musicVolume,
                                  enabled: s.music,
                                  onChanged: Services.settings.setMusicVolume,
                                ),
                                const SettingsDivider(),
                                SettingsSliderRow(
                                  label: tr('sound_volume'),
                                  value: s.soundVolume,
                                  enabled: s.sounds,
                                  onChanged: (double v) {
                                    Services.settings.setSoundVolume(v);
                                  },
                                ),
                                const SettingsDivider(),
                                SettingsToggleRow(
                                  icon: Icons.dark_mode_rounded,
                                  label: tr('dark_theme'),
                                  value: s.darkTheme,
                                  onChanged: Services.settings.setDarkTheme,
                                ),
                                const SettingsDivider(),
                                SettingsActionRow(
                                  icon: Icons.language_rounded,
                                  label: tr('language'),
                                  onTap: () => Services.settings.setLanguage(
                                    s.languageCode == 'en' ? 'es' : 'en',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        tr('language_name'),
                                        style: AppText.label
                                            .copyWith(color: p.textSecondary),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 20,
                                        color: p.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GameButton(
                            label: tr('reset_progress'),
                            kind: GameButtonKind.danger,
                            width: 260,
                            height: 50,
                            textStyle: AppText.buttonSmall,
                            onPressed: () => _confirmReset(context),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
