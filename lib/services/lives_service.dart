import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Жизни на обычных уровнях: не успел уложиться в отведённое время -
/// теряешь одну. С нуля жизни копятся заново по одной за 30 секунд -
/// по-настоящему в фоне, тем же приёмом, что и банк дохода в «Моём
/// аэропорте»: считается от разницы реальных часов, а не от того,
/// открыто ли приложение.
///
/// Отдельный сервис, а не поле в ProgressService, ровно по той же
/// причине, что и BossService - это новая, независимая система, а не
/// переделка существующего прогресса. Боссы её не касаются: у них уже
/// есть собственные три попытки с минутной блокировкой, эта система
/// живёт только на обычных уровнях.
class LivesService extends ChangeNotifier {
  LivesService(this._storage);

  final StorageService _storage;

  static const int maxLives = 3;
  static const int regenSeconds = 30;

  int _lives = maxLives;

  /// Момент, с которого отсчитывается регенерация недостающей жизни.
  /// 0, если запас сейчас полный - восстанавливать нечего.
  int _regenAnchor = 0;

  Future<void> load() async {
    _lives = _storage.getInt(StorageKeys.lives, maxLives).clamp(0, maxLives);
    _regenAnchor = _storage.getInt(StorageKeys.livesRegenAnchor, 0);
    _resolveRegen();
  }

  /// Разрешает накопленные тики регенерации в реальные жизни. Дешёвая
  /// синхронная арифметика - вызывается из каждого геттера, поэтому
  /// значение всегда свежее, даже если экран просто открыли заново
  /// после долгого отсутствия.
  void _resolveRegen() {
    if (_lives >= maxLives || _regenAnchor <= 0) return;

    final int tickMs = regenSeconds * 1000;
    final int elapsed = DateTime.now().millisecondsSinceEpoch - _regenAnchor;
    final int gained = elapsed ~/ tickMs;
    if (gained <= 0) return;

    _lives = (_lives + gained).clamp(0, maxLives);
    // Полный запас - копить больше не от чего, якорь снимается.
    // Не полный - сдвигаем якорь ровно на отданные тики, чтобы
    // дробный прогресс к следующей жизни не терялся зря.
    _regenAnchor = _lives >= maxLives ? 0 : _regenAnchor + gained * tickMs;

    // Значение уже вычислено и возвращается вызывающей стороне сразу;
    // запись в хранилище может завершиться чуть позже - тем же приёмом,
    // что и BossService.mazeSeed.
    _storage.setInt(StorageKeys.lives, _lives);
    _storage.setInt(StorageKeys.livesRegenAnchor, _regenAnchor);
  }

  int get livesLeft {
    _resolveRegen();
    return _lives;
  }

  bool get isFull => livesLeft >= maxLives;

  /// Сколько секунд осталось до следующей восстановленной жизни.
  /// 0, если запас уже полный.
  int get secondsUntilNextLife {
    _resolveRegen();
    if (_lives >= maxLives || _regenAnchor <= 0) return 0;

    final int tickMs = regenSeconds * 1000;
    final int elapsed = DateTime.now().millisecondsSinceEpoch - _regenAnchor;
    final int left = tickMs - elapsed;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  /// Списывает жизнь за не уложенное в лимит время. Если запас был
  /// полным, отсчёт следующей регенерации стартует прямо сейчас.
  Future<void> loseLife() async {
    _resolveRegen();
    if (_lives <= 0) return;

    _lives -= 1;
    if (_regenAnchor <= 0) {
      _regenAnchor = DateTime.now().millisecondsSinceEpoch;
    }
    // Если якорь уже шёл (это не первая потерянная жизнь подряд),
    // трогать его не нужно - следующая жизнь и так придёт по графику,
    // просто теперь их не хватает на одну больше.

    await _storage.setInt(StorageKeys.lives, _lives);
    await _storage.setInt(StorageKeys.livesRegenAnchor, _regenAnchor);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _lives = maxLives;
    _regenAnchor = 0;
    await _storage.setInt(StorageKeys.lives, maxLives);
    await _storage.setInt(StorageKeys.livesRegenAnchor, 0);
    notifyListeners();
  }
}
