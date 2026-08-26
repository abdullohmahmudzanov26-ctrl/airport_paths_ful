import 'package:shared_preferences/shared_preferences.dart';

/// Ключи сохранений в одном месте, чтобы не расползались по коду.
class StorageKeys {
  const StorageKeys._();

  static const String settings = 'settings_json';
  static const String unlockedLevel = 'unlocked_level';
  static const String currentLevel = 'current_level';
  static const String coins = 'coins';
  static const String hints = 'hints';
  static const String achievements = 'achievements';
  static const String hintFreePerfects = 'hint_free_perfects';
  static const String ownedThemes = 'owned_themes';
  static const String equippedTheme = 'equipped_theme';
  static const String ownedSkins = 'owned_skins';
  static const String equippedSkin = 'equipped_skin';
  static const String hintsRefillDay = 'hints_refill_day';
  static const String adsDay = 'ads_day';
  static const String adsCount = 'ads_count';
  static const String adsBonusDay = 'ads_bonus_day';
  static const String adsBonusCount = 'ads_bonus_count';
  static const String coinsDailyBonusDay = 'coins_daily_bonus_day';
  static const String doubleRewardArmed = 'double_reward_armed';
  static const String iapOwned = 'iap_owned';
  static const String airportLevel = 'airport_level';

  /// Заменил airport_income_day: теперь хранится момент сбора
  /// в миллисекундах, а не номер дня - доход забирают каждые
  /// пять минут, а не раз в сутки. Старый ключ больше не читается.
  static const String airportIncomeClaimedAt = 'airport_income_claimed_at';
  static const String playSeconds = 'play_seconds';
  static const String firstRun = 'first_run';

  // Босс-лабиринт: попытки, блокировка, прохождение и рекорд.
  // Ключи привязаны к номеру уровня-босса (10, 20, 30...).
  static String bossAttempts(int levelId) => 'boss_attempts_$levelId';
  static String bossLockUntil(int levelId) => 'boss_lock_until_$levelId';
  static String bossCleared(int levelId) => 'boss_cleared_$levelId';
  static String bossBestTime(int levelId) => 'boss_best_time_$levelId';

  /// Зерно карты этого босса - генерируется один раз и запоминается,
  /// чтобы повторный вход в тот же уровень видел ту же карту, а не
  /// новую случайную при каждом заходе.
  static String bossMazeSeed(int levelId) => 'boss_maze_seed_$levelId';

  static String stars(int levelId) => 'stars_$levelId';
  static String bestTime(int levelId) => 'best_time_$levelId';
  static String bestMoves(int levelId) => 'best_moves_$levelId';
  static String perfect(int levelId) => 'perfect_$levelId';
  static String quest(int levelId) => 'quest_$levelId';
}

/// Тонкая обёртка над SharedPreferences. Все чтения синхронные
/// (после init), поэтому UI не ждёт диск на каждом кадре.
class StorageService {
  SharedPreferences? _prefs;

  bool get isReady => _prefs != null;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  int getInt(String key, [int fallback = 0]) =>
      _prefs?.getInt(key) ?? fallback;

  Future<void> setInt(String key, int value) async =>
      _prefs?.setInt(key, value);

  double getDouble(String key, [double fallback = 0]) =>
      _prefs?.getDouble(key) ?? fallback;

  Future<void> setDouble(String key, double value) async =>
      _prefs?.setDouble(key, value);

  bool getBool(String key, [bool fallback = false]) =>
      _prefs?.getBool(key) ?? fallback;

  Future<void> setBool(String key, bool value) async =>
      _prefs?.setBool(key, value);

  String? getString(String key) => _prefs?.getString(key);

  Future<void> setString(String key, String value) async =>
      _prefs?.setString(key, value);

  List<String> getStringList(String key) =>
      _prefs?.getStringList(key) ?? const <String>[];

  Future<void> setStringList(String key, List<String> value) async =>
      _prefs?.setStringList(key, value);

  Future<void> remove(String key) async => _prefs?.remove(key);

  Future<void> clearAll() async => _prefs?.clear();
}
