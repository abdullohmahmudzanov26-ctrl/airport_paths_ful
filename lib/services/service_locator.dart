import 'audio_service.dart';
import 'haptic_service.dart';
import 'progress_service.dart';
import 'settings_service.dart';
import 'storage_service.dart';

/// Единая точка доступа к сервисам. Без внешних DI-пакетов:
/// ленивые синглтоны + один await на старте в Splash.
class Services {
  const Services._();

  static final StorageService storage = StorageService();
  static final SettingsService settings = SettingsService(storage);
  static final AudioService audio = AudioService(settings);
  static final HapticService haptics = HapticService(settings);
  static final ProgressService progress = ProgressService(storage);

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    await storage.init();
    await settings.load();
    await progress.load();
    await audio.init();
    _initialized = true;
  }
}
