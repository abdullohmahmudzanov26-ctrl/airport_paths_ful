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
  static const String firstRun = 'first_run';

  static String stars(int levelId) => 'stars_$levelId';
  static String bestTime(int levelId) => 'best_time_$levelId';
  static String bestMoves(int levelId) => 'best_moves_$levelId';
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
