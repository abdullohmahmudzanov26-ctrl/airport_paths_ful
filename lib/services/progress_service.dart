import 'package:flutter/foundation.dart';

import '../data/achievements_data.dart';
import '../data/airport_evolution.dart';
import '../data/board_themes.dart';
import '../data/super_milestones.dart';
import '../data/daily_flight.dart';
import '../data/plane_skins.dart';
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
  Set<String> _ownedThemes = <String>{BoardThemes.defaultId};
  String _equippedTheme = BoardThemes.defaultId;
  Set<String> _ownedSkins = <String>{PlaneSkins.defaultId};
  String _equippedSkin = PlaneSkins.defaultId;
  int _hintsRefillDay = 0;
  int _dailyLast = 0;
  int _dailyStreak = 0;
  int _dailyBestStreak = 0;
  int _dailyStars = 0;
  int _dailyReward = 0;
  int _airportLevel = 0;
  int _airportIncomeDay = 0;
  int _playSeconds = 0;

  // Счётчики считаются один раз и обновляются при изменениях:
  // раньше каждый кадр экрана уровней перебирал 150 ключей хранилища.
  int _totalStars = 0;
  int _completedLevels = 0;
  int _perfectLevels = 0;
  int _perfectRuns = 0;
  int _unlockProgress = 0;
  int _coinsBonusDay = 0;
  bool _doubleRewardArmed = false;

  int get unlockedLevel => _unlocked;

  int get coins => _coins;

  int get hints => _hints;

  Set<String> get unlockedAchievements => _achievements;

  /// Уровень, который откроется кнопкой «Играть».
  int get currentLevel => _unlocked.clamp(1, LevelRepository.levelCount);

  Future<void> load() async {
    _unlocked = _storage
        .getInt(StorageKeys.unlockedLevel, 1)
        .clamp(1, LevelRepository.levelCount);
    _coins = _storage.getInt(StorageKeys.coins, 0);
    _hints = _storage.getInt(StorageKeys.hints, 3);
    _hintFreePerfects = _storage.getInt(StorageKeys.hintFreePerfects, 0);
    _achievements = _storage.getStringList(StorageKeys.achievements).toSet();

    _ownedThemes = _storage.getStringList(StorageKeys.ownedThemes).toSet()
      ..add(BoardThemes.defaultId);
    _equippedTheme =
        _storage.getString(StorageKeys.equippedTheme) ?? BoardThemes.defaultId;
    if (!_ownedThemes.contains(_equippedTheme)) {
      _equippedTheme = BoardThemes.defaultId;
    }

    _ownedSkins = _storage.getStringList(StorageKeys.ownedSkins).toSet()
      ..add(PlaneSkins.defaultId);
    _equippedSkin =
        _storage.getString(StorageKeys.equippedSkin) ?? PlaneSkins.defaultId;
    if (!_ownedSkins.contains(_equippedSkin)) {
      _equippedSkin = PlaneSkins.defaultId;
    }

    _hintsRefillDay = _storage.getInt(StorageKeys.hintsRefillDay, 0);
    _coinsBonusDay = _storage.getInt(StorageKeys.coinsDailyBonusDay, 0);
    _doubleRewardArmed =
        _storage.getBool(StorageKeys.doubleRewardArmed, false);
    await refreshDailyHints();

    _dailyLast = _storage.getInt(StorageKeys.dailyLast, 0);
    _dailyStreak = _storage.getInt(StorageKeys.dailyStreak, 0);
    _dailyBestStreak = _storage.getInt(StorageKeys.dailyBestStreak, 0);
    _dailyStars = _storage.getInt(StorageKeys.dailyStars, 0);
    _dailyReward = _storage.getInt(StorageKeys.dailyReward, 0);

    _airportLevel = _storage
        .getInt(StorageKeys.airportLevel, 0)
        .clamp(0, AirportEvolution.maxLevel);
    _airportIncomeDay = _storage.getInt(StorageKeys.airportIncomeDay, 0);
    _playSeconds = _storage.getInt(StorageKeys.playSeconds, 0);

    _recountStats();
  }

  void _recountStats() {
    int stars = 0;
    int completed = 0;
    int perfect = 0;
    int flawless = 0;
    int towardsAirport = 0;
    for (int i = 1; i <= LevelRepository.levelCount; i++) {
      final int s = starsOf(i);
      if (s > 0) {
        stars += s;
        completed++;
        if (s >= 3) perfect++;
        if (i <= AirportEvolution.unlockLevel) towardsAirport++;
      }
      if (isPerfectRun(i)) flawless++;
    }
    _unlockProgress = towardsAirport;
    _totalStars = stars;
    _completedLevels = completed;
    _perfectLevels = perfect;
    _perfectRuns = flawless;
  }

  bool isUnlocked(int levelId) => levelId <= _unlocked;

  int starsOf(int levelId) => _storage.getInt(StorageKeys.stars(levelId), 0);

  bool isCompleted(int levelId) => starsOf(levelId) > 0;

  int bestTime(int levelId) =>
      _storage.getInt(StorageKeys.bestTime(levelId), 0);

  int bestMoves(int levelId) =>
      _storage.getInt(StorageKeys.bestMoves(levelId), 0);

  /// Уровень когда-либо пройден как Perfect Run: без ошибок,
  /// без отмены, без подсказки. Как и звёзды - лучший результат
  /// сохраняется навсегда, а не только за последний забег.
  bool isPerfectRun(int levelId) =>
      _storage.getBool(StorageKeys.perfect(levelId), false);

  /// Задание уровня выполнено - тем же приёмом, что и Perfect Run:
  /// булев флаг на устройстве, пишется один раз навсегда.
  bool isQuestDone(int levelId) =>
      _storage.getBool(StorageKeys.quest(levelId), false);

  /// Награда за задание. Вызывающая сторона (game_screen) сама решает,
  /// выполнено ли условие - здесь только идемпотентная запись и выплата.
  Future<void> completeQuest(int levelId, int reward) async {
    if (isQuestDone(levelId)) return;
    await _storage.setBool(StorageKeys.quest(levelId), true);
    _coins += reward;
    await _storage.setInt(StorageKeys.coins, _coins);
    await _checkAchievements();
    notifyListeners();
  }

  int get totalStars => _totalStars;

  int get completedLevels => _completedLevels;

  int get perfectLevels => _perfectLevels;

  int get perfectRuns => _perfectRuns;

  AchievementStats get stats => AchievementStats(
        completedLevels: completedLevels,
        totalStars: totalStars,
        perfectLevels: perfectLevels,
        coins: _coins,
        hintFreePerfects: _hintFreePerfects,
        perfectRuns: perfectRuns,
      );

  /// Записывает результат уровня и возвращает достижения,
  /// которые открылись именно сейчас - их показывает экран победы.
  /// achievements - новые награды, coinsAwarded - монеты, реально
  /// зачисленные за этот забег (0 при повторном прохождении).
  Future<({List<Achievement> achievements, int coinsAwarded})> completeLevel({
    required int levelId,
    required int stars,
    required int seconds,
    required int moves,
    required int coinsEarned,
    required bool usedHint,
    required bool perfect,
  }) async {
    final int prevStars = starsOf(levelId);

    // Монеты за уровень платятся один раз - при самом первом
    // прохождении. Повторные забеги улучшают время и звёзды,
    // но не превращаются в бесконечный источник монет.
    final bool firstClear = prevStars == 0;
    int coinsAwarded = firstClear ? coinsEarned : 0;
    final bool doubled = _doubleRewardArmed && coinsAwarded > 0;
    if (doubled) {
      coinsAwarded *= 2;
      _doubleRewardArmed = false;
      await _storage.setBool(StorageKeys.doubleRewardArmed, false);
    }

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

    // Флаг пишем один раз навсегда - как и рекорд, откатить его
    // отдельным забегом нельзя, только подтвердить повторно.
    if (perfect && !isPerfectRun(levelId)) {
      await _storage.setBool(StorageKeys.perfect(levelId), true);
    }

    if (levelId >= _unlocked && levelId < LevelRepository.levelCount) {
      _unlocked = levelId + 1;
      await _storage.setInt(StorageKeys.unlockedLevel, _unlocked);
    }
    await _storage.setInt(StorageKeys.currentLevel, levelId);

    if (coinsAwarded > 0) {
      _coins += coinsAwarded;
      await _storage.setInt(StorageKeys.coins, _coins);
    }

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
    return (achievements: fresh, coinsAwarded: coinsAwarded);
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
      // Супер-вехи платят отдельно от обычной награды уровня, ровно
      // в момент первой разблокировки. Повторно это достижение уже
      // не разблокируется - отдельный флаг "выдано" тут не нужен.
      for (final Achievement a in fresh) {
        final SuperMilestone? m = SuperMilestones.byAchievementId(a.id);
        if (m != null) {
          _coins += m.coins;
          await _storage.setInt(StorageKeys.coins, _coins);
        }
      }
    }
    return fresh;
  }

  bool hasAchievement(String id) => _achievements.contains(id);

  // ---------------------------------------------------------- за рекламу

  Future<void> rewardCoins(int amount) async {
    _coins += amount;
    await _storage.setInt(StorageKeys.coins, _coins);
    await _checkAchievements();
    notifyListeners();
  }

  Future<void> rewardHints(int amount) async {
    _hints += amount;
    await _storage.setInt(StorageKeys.hints, _hints);
    notifyListeners();
  }

  // ------------------------------------------------------------ рейс дня

  int get dailyStreak => _dailyStreak;

  int get dailyBestStreak => _dailyBestStreak;

  /// Результат сегодняшнего рейса - чтобы панель показывала не
  /// только серию, но и чем именно закончился день.
  int get dailyStars => _dailyStars;

  int get dailyReward => _dailyReward;

  /// Сегодняшний рейс уже пройден.
  bool get dailyDoneToday => _dailyLast == DailyFlight.todayKey();

  /// Записывает рейс дня. Серия продолжается, только если предыдущий
  /// зачёт был вчера: пропустил день - счёт начинается заново.
  Future<int> completeDaily({required int stars}) async {
    final int today = DailyFlight.todayKey();
    if (_dailyLast == today) return 0;

    _dailyStreak =
        _dailyLast == DailyFlight.yesterdayKey() ? _dailyStreak + 1 : 1;
    _dailyLast = today;
    if (_dailyStreak > _dailyBestStreak) {
      _dailyBestStreak = _dailyStreak;
      await _storage.setInt(StorageKeys.dailyBestStreak, _dailyBestStreak);
    }

    final int reward =
        DailyFlight.reward(stars: stars, streak: _dailyStreak);
    _coins += reward;
    _dailyStars = stars;
    _dailyReward = reward;
    await _storage.setInt(StorageKeys.dailyStars, stars);
    await _storage.setInt(StorageKeys.dailyReward, reward);

    await _storage.setInt(StorageKeys.dailyLast, _dailyLast);
    await _storage.setInt(StorageKeys.dailyStreak, _dailyStreak);
    await _storage.setInt(StorageKeys.coins, _coins);

    await _checkAchievements();
    notifyListeners();
    return reward;
  }

  // ------------------------------------------------- развитие аэропорта

  /// Аэропорт открыт после прохождения 25-го уровня.
  bool get airportUnlocked => isCompleted(AirportEvolution.unlockLevel);

  /// Сколько из первых 25 уровней пройдено - для полосы прогресса.
  int get airportUnlockProgress => _unlockProgress;

  int get airportLevel => _airportLevel;

  bool get airportMaxed => _airportLevel >= AirportEvolution.maxLevel;

  /// Цена следующей ступени. 0, если ветка пройдена до конца.
  int get airportUpgradeCost =>
      airportMaxed ? 0 : AirportEvolution.costFor(_airportLevel + 1);

  int get airportDailyIncome => AirportEvolution.incomeFor(_airportLevel);

  /// Доход можно забрать раз в сутки и только при построенном аэропорте.
  bool get airportIncomeReady =>
      airportUnlocked &&
      _airportLevel > 0 &&
      _airportIncomeDay != DailyFlight.todayKey();

  /// Апгрейд за монеты. Возвращает награду, если ступень оказалась
  /// вехой, иначе null. false-случай (не хватило монет) отличается
  /// тем, что уровень не изменился - экран смотрит на airportLevel.
  Future<AirportReward?> upgradeAirport() async {
    if (!airportUnlocked || airportMaxed) return null;
    final int cost = airportUpgradeCost;
    if (_coins < cost) return null;

    _coins -= cost;
    _airportLevel++;
    await _storage.setInt(StorageKeys.coins, _coins);
    await _storage.setInt(StorageKeys.airportLevel, _airportLevel);

    // Веха выдаёт эксклюзив - тем же владением, что и покупки магазина.
    final AirportReward? reward = AirportEvolution.rewardFor(_airportLevel);
    if (reward != null) {
      if (reward.skinId != null) await _grantSkin(reward.skinId!);
      if (reward.themeId != null) await _grantTheme(reward.themeId!);
    }

    await _checkAchievements();
    notifyListeners();
    return reward;
  }

  /// Забрать пассивный доход. Возвращает 0, если сегодня уже забирали.
  Future<int> claimAirportIncome() async {
    if (!airportIncomeReady) return 0;
    final int amount = airportDailyIncome;
    _airportIncomeDay = DailyFlight.todayKey();
    _coins += amount;
    await _storage.setInt(StorageKeys.airportIncomeDay, _airportIncomeDay);
    await _storage.setInt(StorageKeys.coins, _coins);
    await _checkAchievements();
    notifyListeners();
    return amount;
  }

  Future<void> _grantSkin(String id) async {
    if (_ownedSkins.contains(id)) return;
    _ownedSkins.add(id);
    await _storage.setStringList(StorageKeys.ownedSkins, _ownedSkins.toList());
  }

  Future<void> _grantTheme(String id) async {
    if (_ownedThemes.contains(id)) return;
    _ownedThemes.add(id);
    await _storage.setStringList(
      StorageKeys.ownedThemes,
      _ownedThemes.toList(),
    );
  }

  // ------------------------------------------------------ COINS SHOP

  /// Бесплатные монеты раз в сутки - независимо от Daily Flight,
  /// который остаётся про головоломку, а не про валюту.
  static const int dailyBonusCoins = 50;

  /// Обёртка над static const - экран обращается к Services.progress,
  /// а не к классу напрямую.
  int get dailyBonusCoinsValue => dailyBonusCoins;

  bool get dailyBonusReady => _coinsBonusDay != DailyFlight.todayKey();

  Future<int> claimDailyBonus() async {
    if (!dailyBonusReady) return 0;
    _coinsBonusDay = DailyFlight.todayKey();
    _coins += dailyBonusCoins;
    await _storage.setInt(StorageKeys.coinsDailyBonusDay, _coinsBonusDay);
    await _storage.setInt(StorageKeys.coins, _coins);
    await _checkAchievements();
    notifyListeners();
    return dailyBonusCoins;
  }

  /// Взведённое удвоение сгорает при следующей РЕАЛЬНОЙ выплате за
  /// уровень (см. completeLevel) - повторное прохождение уже
  /// пройденного уровня, где coinsAwarded == 0, его не тратит.
  bool get doubleRewardArmed => _doubleRewardArmed;

  Future<void> armDoubleReward() async {
    _doubleRewardArmed = true;
    await _storage.setBool(StorageKeys.doubleRewardArmed, true);
    notifyListeners();
  }

  // ------------------------------------------------- монеты за время игры

  /// Копит секунды активной игры и выдаёт монеты за каждые семь минут.
  /// Вызывается только из игрового экрана, пока идёт уровень: время в
  /// меню, на паузе и в фоне сюда не попадает.
  Future<int> addPlaySeconds(int seconds) async {
    if (seconds <= 0) return 0;
    _playSeconds += seconds;

    int earned = 0;
    while (_playSeconds >= AirportEvolution.playSecondsPerReward) {
      _playSeconds -= AirportEvolution.playSecondsPerReward;
      earned += AirportEvolution.playReward;
    }

    if (earned > 0) {
      _coins += earned;
      await _storage.setInt(StorageKeys.coins, _coins);
      await _checkAchievements();
    }
    // Остаток тоже сохраняем - прогресс не сгорает при выходе.
    await _storage.setInt(StorageKeys.playSeconds, _playSeconds);
    if (earned > 0) notifyListeners();
    return earned;
  }

  // -------------------------------------------------------------- магазин

  Set<String> get ownedThemes => _ownedThemes;

  String get equippedTheme => _equippedTheme;

  bool ownsTheme(String id) => _ownedThemes.contains(id);

  bool canAfford(int price) => _coins >= price;

  /// Покупка темы. Возвращает false, если монет не хватает, -
  /// экран сам покажет об этом сообщение.
  Future<bool> buyTheme(String id, int price) async {
    if (_ownedThemes.contains(id)) return true;
    if (_coins < price) return false;

    _coins -= price;
    _ownedThemes.add(id);
    await _storage.setInt(StorageKeys.coins, _coins);
    await _storage.setStringList(
      StorageKeys.ownedThemes,
      _ownedThemes.toList(),
    );
    notifyListeners();
    return true;
  }

  Set<String> get ownedSkins => _ownedSkins;

  String get equippedSkin => _equippedSkin;

  bool ownsSkin(String id) => _ownedSkins.contains(id);

  Future<bool> buySkin(String id, int price) async {
    if (_ownedSkins.contains(id)) return true;
    if (_coins < price) return false;

    _coins -= price;
    _ownedSkins.add(id);
    await _storage.setInt(StorageKeys.coins, _coins);
    await _storage.setStringList(StorageKeys.ownedSkins, _ownedSkins.toList());
    notifyListeners();
    return true;
  }

  Future<void> equipSkin(String id) async {
    if (!_ownedSkins.contains(id) || _equippedSkin == id) return;
    _equippedSkin = id;
    await _storage.setString(StorageKeys.equippedSkin, id);
    notifyListeners();
  }

  Future<void> equipTheme(String id) async {
    if (!_ownedThemes.contains(id) || _equippedTheme == id) return;
    _equippedTheme = id;
    await _storage.setString(StorageKeys.equippedTheme, id);
    notifyListeners();
  }

  // ------------------------------------------------------------- подсказки

  static const int freeHintsPerDay = 3;

  /// Раз в сутки запас подсказок пополняется до трёх.
  ///
  /// Именно пополняется, а не прибавляется: иначе игрок, не заходивший
  /// неделю, получил бы двадцать одну штуку и прошёл полигры подсказками.
  /// Купленные и полученные за рекламу сверх трёх при этом не сгорают.
  Future<void> refreshDailyHints() async {
    final int today = DailyFlight.todayKey();
    if (_hintsRefillDay == today) return;

    _hintsRefillDay = today;
    await _storage.setInt(StorageKeys.hintsRefillDay, today);

    if (_hints < freeHintsPerDay) {
      _hints = freeHintsPerDay;
      await _storage.setInt(StorageKeys.hints, _hints);
    }
    notifyListeners();
  }

  Future<bool> buyHints({required int count, required int price}) async {
    if (_coins < price) return false;
    _coins -= price;
    _hints += count;
    await _storage.setInt(StorageKeys.coins, _coins);
    await _storage.setInt(StorageKeys.hints, _hints);
    notifyListeners();
    return true;
  }

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

  int get lastPlayedLevel => _storage
      .getInt(StorageKeys.currentLevel, 1)
      .clamp(1, LevelRepository.levelCount);

  /// Полный сброс - используется в настройках.
  Future<void> resetAll() async {
    for (int i = 1; i <= LevelRepository.levelCount; i++) {
      await _storage.remove(StorageKeys.stars(i));
      await _storage.remove(StorageKeys.bestTime(i));
      await _storage.remove(StorageKeys.bestMoves(i));
      await _storage.remove(StorageKeys.perfect(i));
    }
    _unlocked = 1;
    _coins = 0;
    _hints = 3;
    _hintFreePerfects = 0;
    _achievements = <String>{};
    _ownedThemes = <String>{BoardThemes.defaultId};
    _equippedTheme = BoardThemes.defaultId;
    _ownedSkins = <String>{PlaneSkins.defaultId};
    _equippedSkin = PlaneSkins.defaultId;
    _hintsRefillDay = 0;
    _dailyLast = 0;
    _dailyStreak = 0;
    _dailyBestStreak = 0;
    _dailyStars = 0;
    _dailyReward = 0;
    _airportLevel = 0;
    _airportIncomeDay = 0;
    _coinsBonusDay = 0;
    _doubleRewardArmed = false;
    _playSeconds = 0;
    await _storage.setInt(StorageKeys.airportLevel, 0);
    await _storage.setInt(StorageKeys.airportIncomeDay, 0);
    await _storage.setInt(StorageKeys.coinsDailyBonusDay, 0);
    await _storage.setBool(StorageKeys.doubleRewardArmed, false);
    await _storage.setInt(StorageKeys.playSeconds, 0);
    await _storage.setInt(StorageKeys.unlockedLevel, 1);
    await _storage.setInt(StorageKeys.currentLevel, 1);
    await _storage.setInt(StorageKeys.coins, 0);
    await _storage.setInt(StorageKeys.hints, 3);
    await _storage.setInt(StorageKeys.hintFreePerfects, 0);
    await _storage.setStringList(StorageKeys.achievements, <String>[]);
    await _storage.setStringList(
      StorageKeys.ownedThemes,
      <String>[BoardThemes.defaultId],
    );
    await _storage.setString(StorageKeys.equippedTheme, BoardThemes.defaultId);
    await _storage.setStringList(
      StorageKeys.ownedSkins,
      <String>[PlaneSkins.defaultId],
    );
    await _storage.setString(StorageKeys.equippedSkin, PlaneSkins.defaultId);
    await _storage.setInt(StorageKeys.hintsRefillDay, 0);
    await _storage.setInt(StorageKeys.dailyLast, 0);
    await _storage.setInt(StorageKeys.dailyStreak, 0);
    await _storage.setInt(StorageKeys.dailyBestStreak, 0);
    await _storage.setInt(StorageKeys.dailyStars, 0);
    await _storage.setInt(StorageKeys.dailyReward, 0);
    _recountStats();
    notifyListeners();
  }
}
