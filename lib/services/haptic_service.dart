import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Вибро-отклик. Использует системный HapticFeedback,
/// поэтому не тянет лишних зависимостей и работает на всех Android.
class HapticService {
  HapticService(this._settings);

  final SettingsService _settings;

  bool get _on => _settings.value.vibration;

  Future<void> tap() async {
    if (_on) await HapticFeedback.lightImpact();
  }

  Future<void> impact() async {
    if (_on) await HapticFeedback.mediumImpact();
  }

  Future<void> success() async {
    if (_on) await HapticFeedback.heavyImpact();
  }

  Future<void> error() async {
    if (!_on) return;
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }

  Future<void> select() async {
    if (_on) await HapticFeedback.selectionClick();
  }
}
