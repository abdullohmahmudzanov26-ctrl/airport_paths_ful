import 'package:flutter/foundation.dart';

import '../data/achievements_data.dart';
import '../data/level_repository.dart';
import '../models/achievement.dart';
import 'storage_service.dart';

/// Прогресс игрока: открытые уровни, звёзды, рекорды, монеты,
/// подсказки и достижения. Всё в SharedPreferences.
class ProgressService extends ChangeNotifier {
  ProgressService(this._storage);

  final StorageService _storage;

  int _unlocked = 1;
  int _coins = 0;
  int _hints = 3;
  int _hintFreePerfects = 0;
  Set<String> _achievements = <String>{};

  // Счётчики считаются один раз и обновляются при изменениях:
  // раньше каждый кадр экрана уровней перебирал 50 ключей хранилища.
  int _totalStars = 0;
  int _completedLevels = 0;
  int _perfectLevels = 0;

  int get unlockedLevel => _unlocked;

  int get coins => _coins;

  int get hints => _hints;

  Set<String> get unlockedAchievements => _achievements;

  /// Уровень, который откроется кнопкой «Играть».
  int get currentLevel => _unlocked.clamp(1, LevelRepository.levelCount);

  Future<void> load() async {
    _unlocked = _storage.getInt(StorageKeys.unlockedLevel, 1).clamp(1, LevelRepository.levelCount);
    _coins = _storage.getInt(StorageKeys.coins, 0);
    _hints = _storage.getInt(StorageKeys.hints, 3);
    _hintFreePerfects = _storage.getInt(StorageKeys.hintFreePerfects, 0);
    _achievements = _storage.getStringList(StorageKeys.achievements).toSet();
    _recountStats();
  }

  void _recountStats() {
    int stars = 0;
    int completed = 0;
    int perfect = 0;
    for (int i = 1; i <= LevelRepository.levelCount; i++) {
      final int s = starsOf(i);
      if (s > 0) {
        stars += s;
        completed++;
        if (s >= 3) perfect++;
      }
    }
    _totalStars = stars;
    _completedLevels = completed;
    _perfectLevels = perfect;
  }

  bool isUnlocked(int levelId) => levelId <= _unlocked;

  int starsOf(int levelId) => _storage.getInt(StorageKeys.stars(levelId), 0);

  bool isCompleted(int levelId) => starsOf(levelId) > 0;

  int bestTime(int levelId) => _storage.getInt(StorageKeys.bestTime(levelId), 0);

  int bestMoves(int levelId) => _storage.getInt(StorageKeys.bestMoves(levelId), 0);

  int get totalStars => _totalStars;

  int get completedLevels => _completedLevels;

  int get perfectLevels => _perfectLevels;

  AchievementStats get stats => AchievementStats(
        completedLevels: completedLevels,
        totalStars: totalStars,
        perfectLevels: perfectLevels,
        coins: _coins,
        hintFreePerfects: _hintFreePerfects,
      );

  /// Записывает результат уровня и возвращает достижения,
  /// которые открылись именно сейчас - их показывает экран победы.
  Future<List<Achievement>> completeLevel({
    required int levelId,
    required int stars,
    required int seconds,
    required int moves,
    required int coinsEarned,
    required bool usedHint,
  }) async {
    final int prevStars = starsOf(levelId);
    if (stars > prevStars) {
      await _storage.setInt(StorageKeys.stars(levelId), stars);
    }

    final int prevTime = bestTime(levelId);
    if (prevTime == 0 || seconds < prevTime) {
      await _storage.setInt(StorageKeys.bestTime(levelId), seconds);
    }

    final int prevMoves = bestMoves(levelId);
    if (prevMoves == 0 || moves < prevMoves) {
      await _storage.setInt(StorageKeys.bestMoves(levelId), moves);
    }

    if (levelId >= _unlocked && levelId < LevelRepository.levelCount) {
      _unlocked = levelId + 1;
      await _storage.setInt(StorageKeys.unlockedLevel, _unlocked);
    }
    await _storage.setInt(StorageKeys.currentLevel, levelId);

    _coins += coinsEarned;
    await _storage.setInt(StorageKeys.coins, _coins);

    // Идеальное прохождение без подсказки: и достижение, и лишняя подсказка.
    if (stars >= 3 && !usedHint && prevStars < 3) {
      _hintFreePerfects++;
      await _storage.setInt(StorageKeys.hintFreePerfects, _hintFreePerfects);
      _hints++;
      await _storage.setInt(StorageKeys.hints, _hints);
    }

    _recountStats();
    final List<Achievement> fresh = await _checkAchievements();
    notifyListeners();
    return fresh;
  }

  Future<List<Achievement>> _checkAchievements() async {
    final AchievementStats snapshot = stats;
    final List<Achievement> fresh = <Achievement>[];
    for (final Achievement a in AchievementsCatalog.all) {
      if (_achievements.contains(a.id)) continue;
      if (a.test(snapshot)) {
        _achievements.add(a.id);
        fresh.add(a);
      }
    }
    if (fresh.isNotEmpty) {
      await _storage.setStringList(
        StorageKeys.achievements,
        _achievements.toList(),
      );
    }
    return fresh;
  }

  bool hasAchievement(String id) => _achievements.contains(id);

  Future<bool> spendHint() async {
    if (_hints <= 0) return false;
    _hints--;
    await _storage.setInt(StorageKeys.hints, _hints);
    notifyListeners();
    return true;
  }

  Future<void> rememberCurrentLevel(int levelId) async {
    await _storage.setInt(StorageKeys.currentLevel, levelId);
  }

  int get lastPlayedLevel =>
      _storage.getInt(StorageKeys.currentLevel, 1).clamp(1, LevelRepository.levelCount);

  /// Полный сброс - используется в настройках.
  Future<void> resetAll() async {
    for (int i = 1; i <= LevelRepository.levelCount; i++) {
      await _storage.remove(StorageKeys.stars(i));
      await _storage.remove(StorageKeys.bestTime(i));
      await _storage.remove(StorageKeys.bestMoves(i));
    }
    _unlocked = 1;
    _coins = 0;
    _hints = 3;
    _hintFreePerfects = 0;
    _achievements = <String>{};
    await _storage.setInt(StorageKeys.unlockedLevel, 1);
    await _storage.setInt(StorageKeys.currentLevel, 1);
    await _storage.setInt(StorageKeys.coins, 0);
    await _storage.setInt(StorageKeys.hints, 3);
    await _storage.setInt(StorageKeys.hintFreePerfects, 0);
    await _storage.setStringList(StorageKeys.achievements, <String>[]);
    _recountStats();
    notifyListeners();
  }
}
