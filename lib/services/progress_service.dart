import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../app/app_config.dart';
import '../data/achievements_data.dart';
import '../data/airport_evolution.dart';
import '../data/board_themes.dart';
import '../data/super_milestones.dart';
import '../data/daily_keys.dart';
import '../data/plane_skins.dart';
import '../data/level_repository.dart';
import '../models/achievement.dart';
import '../models/iap_product.dart';
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
  int _airportLevel = 0;

  /// Момент последнего сбора дохода в миллисекундах эпохи - было
  /// «какой день», стало «когда именно», потому что забирать теперь
  /// можно каждые пять минут, а не раз в сутки.
  int _airportIncomeClaimedAt = 0;

  /// Сколько уже заработано из банка дохода СЕГОДНЯ - отдельно от
  /// самого банка (тот копится по времени, этот - по деньгам за день).
  int _airportEarnedToday = 0;

  /// День (см. DailyKeys.todayKey), к которому относится счётчик выше.
  /// Не совпал с сегодняшним - счётчик обнуляется при первом же чтении.
  int _airportEarnedDay = 0;

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

    _airportLevel = _storage
        .getInt(StorageKeys.airportLevel, 0)
        .clamp(0, AirportEvolution.maxLevel);
    _airportIncomeClaimedAt =
        _storage.getInt(StorageKeys.airportIncomeClaimedAt, 0);
    _airportEarnedToday = _storage.getInt(StorageKeys.airportEarnedToday, 0);
    _airportEarnedDay = _storage.getInt(StorageKeys.airportEarnedDay, 0);
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

  /// Уровень открыт по прогрессу.
  ///
  /// Здесь стояла отладочная заглушка `return true` - в релизе она
  /// открывала игроку сразу все 200 уровней: кампания, награды за
  /// прохождение и обучение по одной механике за уровень теряли
  /// смысл с первого запуска. Теперь тест-режим включается флагом
  /// AppConfig.unlockAllLevels, который в релизе false.
  bool isUnlocked(int levelId) {
    if (AppConfig.unlockAllLevels) return true;
    return levelId <= _unlocked;
  }

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
  /// зачисленные за этот забег (0 при повторном прохождении),
  /// zoneThemeGranted - id темы новой локации, если она досталась
  /// бесплатно именно за этот забег (иначе null).
  Future<
      ({
        List<Achievement> achievements,
        int coinsAwarded,
        String? zoneThemeGranted,
      })> completeLevel({
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

    // Орбитальная зона (101+) и EVENT-зона (151+) раньше НАВЯЗЫВАЛИ
    // свою тему насильно, что бы ни было экипировано - купленные темы
    // становились бесполезны на этих уровнях. Теперь вместо принуждения
    // игрок получает саму тему В СОБСТВЕННОСТЬ бесплатно ровно один раз,
    // при первом прохождении уровня-порога, а носить её или нет -
    // решает сам, как и любую другую тему из магазина.
    String? zoneThemeGranted;
    if (levelId == LevelRepository.orbitalFrom - 1 &&
        !ownsTheme(BoardThemes.orbital.id)) {
      await _grantTheme(BoardThemes.orbital.id);
      zoneThemeGranted = BoardThemes.orbital.id;
    } else if (levelId == LevelRepository.eventFrom - 1 &&
        !ownsTheme(BoardThemes.volcanic.id)) {
      await _grantTheme(BoardThemes.volcanic.id);
      zoneThemeGranted = BoardThemes.volcanic.id;
    }
    await _storage.setInt(StorageKeys.currentLevel, levelId);

    if (coinsAwarded > 0) {
      _coins += coinsAwarded;
      await _storage.setInt(StorageKeys.coins, _coins);
    }

    // Идеальное прохождение без подсказки: и достижение, и лишняя подсказка.
    // Достижение (_hintFreePerfects) считается всегда - это лишь счётчик
    // для наград/статистики, не валюта. А саму подсказку эта бесплатная
    // награда за прохождение начисляет только до потолка hintsFreeCap:
    // раньше проходя уровни можно было накопить подсказок сколько угодно.
    // Купленные подсказки (магазин за монеты, донат) этот потолок не
    // видят вообще - buyHints/grantIapReward прибавляют мимо него, как и
    // раньше, поэтому переплата за подсказки всегда даёт честный результат.
    if (stars >= 3 && !usedHint && prevStars < 3) {
      _hintFreePerfects++;
      await _storage.setInt(StorageKeys.hintFreePerfects, _hintFreePerfects);
      if (_hints < hintsFreeCap) {
        _hints++;
        await _storage.setInt(StorageKeys.hints, _hints);
      }
    }

    _recountStats();
    final List<Achievement> fresh = await _checkAchievements();
    notifyListeners();
    return (
      achievements: fresh,
      coinsAwarded: coinsAwarded,
      zoneThemeGranted: zoneThemeGranted,
    );
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
          if (m.skinId != null) await _grantSkin(m.skinId!);
        }
      }
    }
    return fresh;
  }

  bool hasAchievement(String id) => _achievements.contains(id);

  // ------------------------------------------------- награды извне игры
  // Общие для рекламы (оставшийся мид-геймовый ролик за подсказку)
  // и доната - откуда бы монеты и подсказки ни пришли, начисляются
  // они одинаково.

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

  /// Начисляет то, что даёт купленный товар доната: монеты, подсказки,
  /// а для стартового набора и разового буста - ещё и удвоение
  /// следующей награды за уровень. Вызывается уже ПОСЛЕ того, как
  /// PurchaseService подтвердил успешную оплату - здесь только выдача.
  Future<void> grantIapReward(IapProduct product) async {
    if (product.coins > 0) await rewardCoins(product.coins);
    if (product.hints > 0) await rewardHints(product.hints);
    if (product.id == 'starter_pack' || product.id == 'double_boost') {
      await armDoubleReward();
    }
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

  /// Ставка одной пятиминутки. Название без «daily» - это не сутки,
  /// а цена ровно одного тика в банке.
  int get airportClaimAmount => AirportEvolution.incomeFor(_airportLevel);

  /// Сколько тиков накопилось с последнего сбора - настоящее фоновое
  /// начисление: считается от разницы реальных часов, а не от того,
  /// открыт ли сейчас экран. Игрок закрыл приложение на два часа -
  /// вернувшись, застаёт банк с 24 тиками, а не с одним. Выше потолка
  /// (AirportEvolution.maxBankedTicks) счётчик просто перестаёт расти.
  int get _bankedTicks {
    if (_airportIncomeClaimedAt <= 0) return 0;
    final int tickMs = AirportEvolution.incomeIntervalSeconds * 1000;
    final int elapsedMs = DateTime.now().millisecondsSinceEpoch - _airportIncomeClaimedAt;
    if (elapsedMs < tickMs) return 0;
    return (elapsedMs ~/ tickMs).clamp(0, AirportEvolution.maxBankedTicks);
  }

  /// Сегодняшний день сменился - счётчик заработка обнуляется. Дешёвая
  /// синхронная проверка, вызывается из каждого геттера ниже, поэтому
  /// значение всегда свежее само по себе, без отдельного тикера.
  void _resolveAirportDailyReset() {
    final int today = DailyKeys.todayKey();
    if (_airportEarnedDay == today) return;
    _airportEarnedDay = today;
    _airportEarnedToday = 0;
    _storage.setInt(StorageKeys.airportEarnedDay, today);
    _storage.setInt(StorageKeys.airportEarnedToday, 0);
  }

  /// Сколько уже заработано из банка дохода сегодня.
  int get airportEarnedToday {
    _resolveAirportDailyReset();
    return _airportEarnedToday;
  }

  /// Сколько ещё можно заработать сегодня до дневного потолка.
  int get airportDailyRemaining =>
      (AirportEvolution.dailyEarnCap - airportEarnedToday)
          .clamp(0, AirportEvolution.dailyEarnCap);

  /// Дневной потолок уже выбран целиком - копить в банке смысла нет,
  /// новые монеты появятся только завтра.
  bool get airportDailyLimitReached => airportDailyRemaining <= 0;

  /// Сумма, которая реально ждёт сбора прямо сейчас - то самое число,
  /// что показывает кнопка. Уже учитывает дневной потолок: банк может
  /// быть набит битком, но если сегодня заработано почти 3000, кнопка
  /// честно покажет остаток, а не то, что «на бумаге» накопил банк.
  int get airportBankedAmount =>
      math.min(_bankedTicks * airportClaimAmount, airportDailyRemaining);

  /// Банк упёрся в потолок - копить дальше некуда, самое время забрать.
  /// Экран может честно предупредить об этом, а не молчать о том,
  /// что часть времени уже пропадает впустую.
  bool get airportBankFull =>
      airportUnlocked &&
      _airportLevel > 0 &&
      _bankedTicks >= AirportEvolution.maxBankedTicks;

  /// Есть что забрать - построенный аэропорт, хотя бы один накопленный
  /// тик и дневной потолок ещё не исчерпан.
  bool get airportIncomeReady =>
      airportUnlocked &&
      _airportLevel > 0 &&
      _bankedTicks > 0 &&
      !airportDailyLimitReached;

  /// Сколько секунд осталось до ПЕРВОГО тика, если банк сейчас пуст.
  /// Пока в банке уже есть что забрать, отсчитывать нечего - экран
  /// показывает кнопку сбора вместо таймера. Если дневной потолок уже
  /// выбран - тоже 0: считать здесь нечего, экран показывает отдельное
  /// сообщение «приходи завтра» через airportDailyLimitReached.
  int get airportIncomeSecondsLeft {
    if (!airportUnlocked || _airportLevel <= 0) return 0;
    if (_bankedTicks > 0 || airportDailyLimitReached) return 0;
    final int tickMs = AirportEvolution.incomeIntervalSeconds * 1000;
    final int leftMs = tickMs - _msSinceClaim;
    return leftMs <= 0 ? 0 : (leftMs / 1000).ceil();
  }

  int get _msSinceClaim =>
      DateTime.now().millisecondsSinceEpoch - _airportIncomeClaimedAt;

  /// Апгрейд за монеты. Возвращает награду, если ступень оказалась
  /// вехой, иначе null. false-случай (не хватило монет) отличается
  /// тем, что уровень не изменился - экран смотрит на airportLevel.
  Future<AirportReward?> upgradeAirport() async {
    if (!airportUnlocked || airportMaxed) return null;
    final int cost = airportUpgradeCost;
    if (_coins < cost) return null;

    // Самое первое улучшение заводит банк дохода с нуля, а не с
    // 1970 года: без этого первый же расчёт _bankedTicks увидел бы
    // разницу в полвека и мгновенно засыпал бы банк до потолка.
    if (_airportLevel == 0) {
      _airportIncomeClaimedAt = DateTime.now().millisecondsSinceEpoch;
      await _storage.setInt(
        StorageKeys.airportIncomeClaimedAt,
        _airportIncomeClaimedAt,
      );
    }

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

  /// Забрать всё, что накопилось в банке. Возвращает 0, если банк
  /// пуст. Метка времени продвигается ровно на забранные тики, а не
  /// сбрасывается на «сейчас» - дробный прогресс к следующей
  /// пятиминутке не сгорает, а остаётся в зачёт.
  /// Забрать всё, что накопилось в банке. Возвращает 0, если банк
  /// пуст ИЛИ дневной потолок уже выбран. Метка времени продвигается
  /// ровно на забранные тики, а не сбрасывается на «сейчас» - дробный
  /// прогресс к следующей пятиминутке не сгорает, а остаётся в зачёт.
  ///
  /// Выплата зажата дневным потолком (AirportEvolution.dailyEarnCap):
  /// банк списывается ЦЕЛИКОМ в любом случае - иначе излишек можно
  /// было бы придержать до завтра и разом обойти лимит, - но монет
  /// сверх остатка за сегодня начислено не будет.
  Future<int> claimAirportIncome() async {
    final int ticks = _bankedTicks;
    if (ticks <= 0) return 0;

    _resolveAirportDailyReset();
    final int remaining = airportDailyRemaining;

    final int tickMs = AirportEvolution.incomeIntervalSeconds * 1000;
    _airportIncomeClaimedAt += ticks * tickMs;
    await _storage.setInt(
      StorageKeys.airportIncomeClaimedAt,
      _airportIncomeClaimedAt,
    );

    if (remaining <= 0) {
      // Банк списан, но сегодня уже выбрано всё до потолка - ни одной
      // лишней монеты сверху, даже если банк был набит битком.
      notifyListeners();
      return 0;
    }

    final int amount = math.min(ticks * airportClaimAmount, remaining);
    _coins += amount;
    _airportEarnedToday += amount;
    await _storage.setInt(StorageKeys.coins, _coins);
    await _storage.setInt(StorageKeys.airportEarnedToday, _airportEarnedToday);
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

  bool get dailyBonusReady => _coinsBonusDay != DailyKeys.todayKey();

  Future<int> claimDailyBonus() async {
    if (!dailyBonusReady) return 0;
    _coinsBonusDay = DailyKeys.todayKey();
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

  /// Потолок для БЕСПЛАТНОЙ подсказки за идеальное прохождение уровня
  /// (см. completeLevel). Купленные подсказки (магазин, донат, ролик)
  /// этот потолок не ограничивает - запас честно может быть больше 10,
  /// если игрок за них заплатил.
  static const int hintsFreeCap = 10;

  /// Раз в сутки запас подсказок пополняется до трёх.
  ///
  /// Именно пополняется, а не прибавляется: иначе игрок, не заходивший
  /// неделю, получил бы двадцать одну штуку и прошёл полигры подсказками.
  /// Купленные и полученные за рекламу сверх трёх при этом не сгорают.
  Future<void> refreshDailyHints() async {
    final int today = DailyKeys.todayKey();
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
      // Раньше квест уровня не сбрасывался вместе со звёздами: после
      // "Reset Progress" isQuestDone() всё ещё отвечал true для уже
      // выполненных квестов, и game_screen._handleWin молча не выдавал
      // за них награду повторно, хотя игрок формально начинал с нуля.
      await _storage.remove(StorageKeys.quest(i));
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
    _airportLevel = 0;
    _airportIncomeClaimedAt = 0;
    _airportEarnedToday = 0;
    _airportEarnedDay = 0;
    _coinsBonusDay = 0;
    _doubleRewardArmed = false;
    _playSeconds = 0;
    await _storage.setInt(StorageKeys.airportLevel, 0);
    await _storage.setInt(StorageKeys.airportIncomeClaimedAt, 0);
    await _storage.setInt(StorageKeys.airportEarnedToday, 0);
    await _storage.setInt(StorageKeys.airportEarnedDay, 0);
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
    _recountStats();
    notifyListeners();
  }
}
