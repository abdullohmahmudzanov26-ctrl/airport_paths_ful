import 'ad_service.dart';
import 'audio_service.dart';
import 'boss_service.dart';
import 'haptic_service.dart';
import 'lives_service.dart';
import 'onboarding_service.dart';
import 'progress_service.dart';
import 'purchase_service.dart';
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
  static final AdService ads = AdService(storage);

  /// Донат за реальные деньги - монеты, подсказки и разовые наборы.
  /// Реальной оплаты пока нет (см. PurchaseService._processPayment),
  /// но весь каталог, экраны и владение нерасходуемыми товарами уже
  /// работают на заглушке.
  static final PurchaseService purchases = PurchaseService(storage);

  /// Состояние босс-лабиринтов: попытки и блокировка. Читает то же
  /// хранилище, что и остальные сервисы, отдельной загрузки не требует.
  static final BossService boss = BossService(storage);

  /// Жизни на обычных уровнях: не уложился во время - минус одна,
  /// восстанавливаются по одной за 45 секунд, даже пока игра закрыта.
  static final LivesService lives = LivesService(storage);

  /// Флаги "указка уже показана" - Next Level, магазин, свой аэропорт.
  /// Читает то же хранилище, отдельной загрузки тоже не требует.
  static final OnboardingService onboarding = OnboardingService(storage);

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;
    await storage.init();
    await settings.load();
    await progress.load();
    await ads.load();
    await purchases.load();
    await lives.load();
    await audio.init();
    _initialized = true;
  }
}
