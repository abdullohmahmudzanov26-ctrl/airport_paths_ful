import 'package:flutter/foundation.dart';

import '../data/app_strings.dart';
import '../models/game_settings.dart';
import 'storage_service.dart';

/// Хранит настройки и уведомляет приложение об изменениях.
/// MaterialApp подписан на него, поэтому тема и язык меняются мгновенно.
class SettingsService extends ValueNotifier<GameSettings> {
  SettingsService(this._storage) : super(GameSettings.defaults);

  final StorageService _storage;

  Future<void> load() async {
    value = GameSettings.decode(_storage.getString(StorageKeys.settings));
    AppStrings.language = value.languageCode;
  }

  Future<void> update(GameSettings next) async {
    if (next == value) return;
    value = next;
    AppStrings.language = next.languageCode;
    await _storage.setString(StorageKeys.settings, next.encode());
  }

  Future<void> setMusic(bool on) => update(value.copyWith(music: on));

  Future<void> setSounds(bool on) => update(value.copyWith(sounds: on));

  Future<void> setVibration(bool on) => update(value.copyWith(vibration: on));

  Future<void> setMusicVolume(double v) =>
      update(value.copyWith(musicVolume: v.clamp(0.0, 1.0)));

  Future<void> setSoundVolume(double v) =>
      update(value.copyWith(soundVolume: v.clamp(0.0, 1.0)));

  Future<void> setDarkTheme(bool on) => update(value.copyWith(darkTheme: on));

  Future<void> setLanguage(String code) =>
      update(value.copyWith(languageCode: code));

  /// Одна кнопка "звук" в главном меню глушит и музыку, и эффекты.
  Future<void> toggleAllSound() {
    final bool on = !(value.music || value.sounds);
    return update(value.copyWith(music: on, sounds: on));
  }

  bool get anySoundOn => value.music || value.sounds;
}
