import '../models/level_data.dart';
import 'daily_flight.dart';
import 'level_generator.dart';

/// Доступ к уровням. Карты строятся лениво и кэшируются:
/// генерация одной занимает доли миллисекунды, но повторять её
/// при каждом открытии экрана незачем.
class LevelRepository {
  const LevelRepository._();

  static const int levelCount = 200;

  /// С этого уровня начинается орбитальная зона: другая тема,
  /// самые плотные карты в игре.
  static const int orbitalFrom = 101;

  /// С этого уровня начинается EVENT-зона: отдельная локация,
  /// самые плотные карты и до 13 бортов одновременно.
  static const int eventFrom = 151;
  static const int levelsPerPage = 16;

  static final Map<int, LevelData> _cache = <int, LevelData>{};

  static int get pageCount =>
      (levelCount + levelsPerPage - 1) ~/ levelsPerPage;

  static LevelData level(int id) {
    final int safeId = id.clamp(1, levelCount);
    return _cache.putIfAbsent(safeId, () => LevelGenerator.generate(safeId));
  }

  static bool exists(int id) => id >= 1 && id <= levelCount;

  /// Прогреть несколько ближайших уровней в фоне после старта.
  static void warmUp(int aroundId) {
    for (int i = aroundId; i < aroundId + 3; i++) {
      if (exists(i)) level(i);
    }
  }

  static final Map<int, LevelData> _dailyCache = <int, LevelData>{};

  /// Карта рейса дня. Кэш по дате, чтобы не строить её заново
  /// при каждом открытии меню.
  static LevelData daily(DateTime date) {
    final int key = DailyFlight.keyFor(date);
    return _dailyCache.putIfAbsent(key, () => DailyFlight.levelFor(date));
  }

  static void clearCache() {
    _cache.clear();
    _dailyCache.clear();
  }
}
