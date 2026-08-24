import 'package:flutter/foundation.dart';

import '../data/boss_config.dart';
import '../data/level_repository.dart';
import 'storage_service.dart';

/// Состояние босс-лабиринтов: попытки, блокировка, рекорды.
///
/// Отдельный сервис, а не поле в ProgressService: монеты, звёзды и
/// открытие следующего уровня по-прежнему считает ProgressService, а
/// здесь живёт только то, чего в игре раньше не было. Ничего из
/// существующего прогресса этот класс не переписывает.
///
/// Всё лежит в том же SharedPreferences, поэтому попытки и блокировка
/// переживают перезапуск игры: выйти из приложения, чтобы обнулить
/// минуту ожидания, не получится.
class BossService extends ChangeNotifier {
  BossService(this._storage);

  final StorageService _storage;

  /// Сколько попыток осталось на этом боссе. Пустой ключ - полный запас.
  int attemptsLeft(int levelId) {
    if (isLocked(levelId)) return 0;
    final int stored =
        _storage.getInt(StorageKeys.bossAttempts(levelId), BossConfig.attempts);
    // Блокировка снята, а попытки не восстановлены - значит минута
    // истекла, пока игра была закрыта. Восстанавливаем запас.
    if (stored <= 0) return BossConfig.attempts;
    return stored.clamp(0, BossConfig.attempts);
  }

  /// Момент окончания блокировки в миллисекундах эпохи. 0 - не заблокирован.
  int lockUntil(int levelId) =>
      _storage.getInt(StorageKeys.bossLockUntil(levelId), 0);

  bool isLocked(int levelId) =>
      lockUntil(levelId) > DateTime.now().millisecondsSinceEpoch;

  /// Сколько секунд осталось ждать. 0, если босс доступен.
  int lockSecondsLeft(int levelId) {
    final int until = lockUntil(levelId);
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (until <= now) return 0;
    return ((until - now) / 1000).ceil();
  }

  bool isCleared(int levelId) =>
      _storage.getBool(StorageKeys.bossCleared(levelId), false);

  /// Зерно карты для этого босса.
  ///
  /// Раньше карта и тема пересоздавались случайными при КАЖДОМ входе
  /// на уровень - выйти в меню и зайти обратно означало другую карту.
  /// Теперь зерно генерируется один раз при первом входе и запоминается:
  /// повторные заходы на тот же уровень (10, 20, 30...) видят ту же
  /// самую карту и ту же тему, пока её не пройдут и не решат сыграть
  /// заново. Разные боссы (10 и 20) всё так же получают разные карты -
  /// у каждого уровня своё независимое зерно.
  int mazeSeed(int levelId) {
    final int stored = _storage.getInt(StorageKeys.bossMazeSeed(levelId), 0);
    if (stored != 0) return stored;

    final int fresh =
        DateTime.now().microsecondsSinceEpoch ^ (levelId * 7919 + 104729);
    // Значение уже готово и возвращается сразу; запись в хранилище может
    // завершиться чуть позже - к следующему чтению она гарантированно
    // успеет, а до этого момента тот же сеанс всё равно держит fresh
    // в памяти вызывающей стороны.
    _storage.setInt(StorageKeys.bossMazeSeed(levelId), fresh);
    return fresh;
  }

  /// Новая случайная карта для этого босса взамен старой - осознанное
  /// действие игрока (например, кнопка «другая карта» после победы),
  /// а не побочный эффект простого входа на уровень.
  Future<void> rerollMaze(int levelId) async {
    final int fresh =
        DateTime.now().microsecondsSinceEpoch ^ (levelId * 415241 + 17);
    await _storage.setInt(StorageKeys.bossMazeSeed(levelId), fresh);
    notifyListeners();
  }

  /// Лучшее время прохождения в секундах. 0 - рекорда ещё нет.
  int bestTime(int levelId) =>
      _storage.getInt(StorageKeys.bossBestTime(levelId), 0);

  /// Сколько боссов пройдено - для будущих достижений и статистики.
  int get clearedCount {
    int count = 0;
    for (int id = BossConfig.every;
        id <= LevelRepository.levelCount;
        id += BossConfig.every) {
      if (isCleared(id)) count++;
    }
    return count;
  }

  /// Списывает попытку. Когда попытки кончились, включает блокировку
  /// ровно на минуту - и возвращает true, если она включилась.
  Future<bool> loseAttempt(int levelId) async {
    final int left = attemptsLeft(levelId) - 1;
    if (left > 0) {
      await _storage.setInt(StorageKeys.bossAttempts(levelId), left);
      notifyListeners();
      return false;
    }

    final int until = DateTime.now().millisecondsSinceEpoch +
        BossConfig.lockSeconds * 1000;
    await _storage.setInt(StorageKeys.bossAttempts(levelId), 0);
    await _storage.setInt(StorageKeys.bossLockUntil(levelId), until);
    notifyListeners();
    return true;
  }

  /// Минута прошла - выдаём новые три попытки.
  Future<void> refill(int levelId) async {
    await _storage.setInt(StorageKeys.bossAttempts(levelId), BossConfig.attempts);
    await _storage.setInt(StorageKeys.bossLockUntil(levelId), 0);
    notifyListeners();
  }

  /// Победа: запас попыток восстанавливается, рекорд обновляется.
  Future<void> markCleared(int levelId, int seconds) async {
    await _storage.setBool(StorageKeys.bossCleared(levelId), true);

    final int prev = bestTime(levelId);
    if (prev == 0 || seconds < prev) {
      await _storage.setInt(StorageKeys.bossBestTime(levelId), seconds);
    }

    await _storage.setInt(StorageKeys.bossAttempts(levelId), BossConfig.attempts);
    await _storage.setInt(StorageKeys.bossLockUntil(levelId), 0);
    notifyListeners();
  }

  /// Полный сброс - вызывается из настроек вместе со сбросом прогресса.
  Future<void> resetAll() async {
    for (int id = BossConfig.every;
        id <= LevelRepository.levelCount;
        id += BossConfig.every) {
      await _storage.remove(StorageKeys.bossAttempts(id));
      await _storage.remove(StorageKeys.bossLockUntil(id));
      await _storage.remove(StorageKeys.bossCleared(id));
      await _storage.remove(StorageKeys.bossBestTime(id));
      await _storage.remove(StorageKeys.bossMazeSeed(id));
    }
    notifyListeners();
  }
}
