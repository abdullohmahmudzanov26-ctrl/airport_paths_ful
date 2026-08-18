import 'package:flutter/foundation.dart';

import '../data/daily_flight.dart';
import 'storage_service.dart';

/// Награды за просмотр рекламы и дневной лимит показов.
///
/// ВАЖНО: сам показ рекламы здесь не реализован — он вынесен в один
/// метод [_present]. Подключение SDK делается только там, вся логика
/// лимитов, счётчиков и наград остаётся нетронутой.
class AdService extends ChangeNotifier {
  AdService(this._storage);

  final StorageService _storage;

  /// Больше пятнадцати показов в день игра не предложит.
  static const int maxPerDay = 15;

  static const int coinsPerAd = 100;
  static const int hintsPerAd = 5;

  /// Бонусный ролик - крупнее награда, отдельный и более тесный лимит.
  static const int bonusCoinsPerAd = 250;
  static const int maxBonusPerDay = 3;

  int _day = 0;
  int _count = 0;
  int _bonusDay = 0;
  int _bonusCount = 0;
  bool _showing = false;

  Future<void> load() async {
    _day = _storage.getInt(StorageKeys.adsDay, 0);
    _count = _storage.getInt(StorageKeys.adsCount, 0);
    _bonusDay = _storage.getInt(StorageKeys.adsBonusDay, 0);
    _bonusCount = _storage.getInt(StorageKeys.adsBonusCount, 0);
    _rolloverIfNeeded();
  }

  int get watchedToday {
    _rolloverIfNeeded();
    return _count;
  }

  int get leftToday => maxPerDay - watchedToday;

  bool get canWatch => leftToday > 0 && !_showing;

  /// Идёт показ — экран должен заблокировать кнопки.
  bool get isShowing => _showing;

  int get bonusWatchedToday {
    _rolloverIfNeeded();
    return _bonusCount;
  }

  int get bonusLeftToday => maxBonusPerDay - bonusWatchedToday;

  bool get canWatchBonus => bonusLeftToday > 0 && !_showing;

  void _rolloverIfNeeded() {
    final int today = DailyFlight.todayKey();
    if (_day != today) {
      _day = today;
      _count = 0;
      _storage.setInt(StorageKeys.adsDay, _day);
      _storage.setInt(StorageKeys.adsCount, 0);
    }
    if (_bonusDay != today) {
      _bonusDay = today;
      _bonusCount = 0;
      _storage.setInt(StorageKeys.adsBonusDay, _bonusDay);
      _storage.setInt(StorageKeys.adsBonusCount, 0);
    }
  }

  /// Показывает ролик и сообщает, досмотрел ли игрок до награды.
  /// Счётчик растёт только при честном просмотре. bonus=true списывает
  /// отдельный, более тесный лимит крупного ролика +250.
  Future<bool> showRewarded({bool bonus = false}) async {
    _rolloverIfNeeded();
    if (!(bonus ? canWatchBonus : canWatch)) return false;

    _showing = true;
    notifyListeners();

    bool rewarded = false;
    try {
      rewarded = await _present();
    } catch (e) {
      debugPrint('AdService: показ не удался ($e)');
      rewarded = false;
    }

    if (rewarded) {
      if (bonus) {
        _bonusCount++;
        await _storage.setInt(StorageKeys.adsBonusCount, _bonusCount);
      } else {
        _count++;
        await _storage.setInt(StorageKeys.adsCount, _count);
      }
    }

    _showing = false;
    notifyListeners();
    return rewarded;
  }

  // ===========================================================================
  // ЕДИНСТВЕННОЕ МЕСТО, КУДА ПОДКЛЮЧАЕТСЯ РЕКЛАМНАЯ СЕТЬ
  // ===========================================================================
  //
  // Сейчас здесь заглушка: пауза и «награда получена», чтобы экономику
  // можно было проверять без SDK.
  //
  // Для AdMob:
  //   1. добавить google_mobile_ads в pubspec.yaml;
  //   2. вызвать MobileAds.instance.initialize() в main();
  //   3. заменить тело метода на загрузку и показ RewardedAd;
  //   4. вернуть true ТОЛЬКО из onUserEarnedReward — иначе игрок будет
  //      получать монеты за закрытый на первой секунде ролик.
  //
  // Возврат false обязателен, если ролик не загрузился: игра тогда
  // не спишет показ из дневного лимита и предложит попробовать позже.
  Future<bool> _present() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return true;
  }
}
