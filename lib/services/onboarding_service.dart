import 'storage_service.dart';

/// Отметки о показанных указках-обучении ("палец в кнопку").
///
/// Не ChangeNotifier - ничего не должно перерисовываться, когда флаг
/// меняется. Экран сам проверяет его один раз при открытии и сам решает,
/// показывать ли указку - это дешевле и понятнее, чем городить подписку
/// ради события, которое за всю жизнь сохранения происходит максимум
/// по разу на каждый флаг.
class OnboardingService {
  OnboardingService(this._storage);

  final StorageService _storage;

  /// Самая первая указка в игре - на кнопку "Play" в главном меню при
  /// самом первом запуске, до того как пройден хоть один уровень.
  bool get hasSeenPlayHint =>
      _storage.getBool(StorageKeys.onboardingPlayHintSeen, false);

  Future<void> markPlayHintSeen() =>
      _storage.setBool(StorageKeys.onboardingPlayHintSeen, true);

  /// Указка на кнопку "Next Level" на экране победы уровней 1-3 -
  /// гасится сама, как только показан тур по магазину (см. ниже),
  /// поэтому не мешает при повторном прохождении ранних уровней.
  bool get hasSeenShopHint =>
      _storage.getBool(StorageKeys.onboardingShopHintSeen, false);

  Future<void> markShopHintSeen() =>
      _storage.setBool(StorageKeys.onboardingShopHintSeen, true);

  /// Указка на кнопку "Магазин" в главном меню - появляется один раз,
  /// как только игрок прошёл 3-й уровень.
  bool get hasSeenShopMenuHint =>
      _storage.getBool(StorageKeys.onboardingShopMenuHintSeen, false);

  Future<void> markShopMenuHintSeen() =>
      _storage.setBool(StorageKeys.onboardingShopMenuHintSeen, true);

  /// Указка на кнопку "Мой аэропорт" в главном меню - один раз, как
  /// только раздел разблокирован (прохождение уровня 25).
  bool get hasSeenAirportMenuHint =>
      _storage.getBool(StorageKeys.onboardingAirportMenuHintSeen, false);

  Future<void> markAirportMenuHintSeen() =>
      _storage.setBool(StorageKeys.onboardingAirportMenuHintSeen, true);

  /// Тур по "Моему аэропорту" - постройка и сбор дохода, указками
  /// прямо на настоящих кнопках. Один раз при первом открытии экрана
  /// после разблокировки.
  bool get hasSeenAirportHint =>
      _storage.getBool(StorageKeys.onboardingAirportHintSeen, false);

  Future<void> markAirportHintSeen() =>
      _storage.setBool(StorageKeys.onboardingAirportHintSeen, true);
}
